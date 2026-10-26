package dev.benderapps.scrubprep.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dev.benderapps.scrubprep.AppContainer
import dev.benderapps.scrubprep.data.ParseApiException
import dev.benderapps.scrubprep.data.ParseNetworkException
import dev.benderapps.scrubprep.data.SignedInUser
import kotlinx.coroutines.launch
import org.json.JSONObject

/**
 * The single source of truth for whether the app shows the sign-in screen or the main tabs,
 * and the view model backing the sign-in screen itself. Sign-in is mandatory, since Cases
 * and Quiz Me sessions live on the backend as the single source of truth, not the device.
 */
class AuthViewModel(private val container: AppContainer) : ViewModel() {
    var currentUser by mutableStateOf(container.sessionStore.currentUser())
        private set
    var isLoading by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)

    /**
     * Set right after a successful signup — the root view shows a one-time "check your
     * inbox" alert on top of the transition into the tabs, then clears this.
     */
    var showAccountCreatedAlert by mutableStateOf(false)

    init {
        // Parse Server rejects every request carrying a stale session token, so without
        // this the app would sit signed-in-but-broken with no way to recover short of a
        // manual sign-out. Drops straight back to the sign-in screen.
        viewModelScope.launch {
            container.invalidSession.collect {
                if (currentUser != null) {
                    clearSession()
                    errorMessage = "Your session expired. Please sign in again."
                }
            }
        }
    }

    fun signUp(email: String, password: String) {
        viewModelScope.launch {
            isLoading = true
            errorMessage = null
            try {
                val json = container.parseClient.signUp(username = email, email = email, password = password)
                startSession(json, fallbackEmail = email)
                showAccountCreatedAlert = true
            } catch (e: Exception) {
                errorMessage = friendlyMessage(e)
            }
            isLoading = false
        }
    }

    fun logIn(email: String, password: String) {
        viewModelScope.launch {
            isLoading = true
            errorMessage = null
            try {
                startSession(container.parseClient.logIn(email, password), fallbackEmail = email)
            } catch (e: Exception) {
                errorMessage = friendlyMessage(e)
            }
            isLoading = false
        }
    }

    /**
     * Clears local state even if the server-side logout call fails (e.g. offline) — staying
     * "stuck" signed in because of a network blip would be worse.
     */
    fun logOut() {
        viewModelScope.launch {
            runCatching { container.parseClient.logOut() }
            clearSession()
        }
    }

    /**
     * Permanently deletes the account and everything saved under it (see
     * backend/cloud/scrubPrep/account.js). Returns whether it succeeded — the Settings screen
     * owns its own progress/error state rather than using [isLoading]/[errorMessage], which
     * belong to the sign-in screen.
     */
    suspend fun deleteAccount(): Boolean {
        try {
            container.service.deleteAccount()
        } catch (e: Exception) {
            return false
        }
        clearSession()
        return true
    }

    fun resetPassword(email: String, onSent: () -> Unit) {
        viewModelScope.launch {
            isLoading = true
            errorMessage = null
            try {
                container.parseClient.requestPasswordReset(email)
                onSent()
            } catch (e: Exception) {
                errorMessage = friendlyMessage(e)
            }
            isLoading = false
        }
    }

    private fun startSession(json: JSONObject, fallbackEmail: String) {
        val user = SignedInUser(
            objectId = json.getString("objectId"),
            email = json.optString("email").ifEmpty { fallbackEmail },
        )
        container.sessionStore.save(json.getString("sessionToken"), user)
        currentUser = user
    }

    private fun clearSession() {
        container.sessionStore.clear()
        currentUser = null
    }

    private fun friendlyMessage(error: Exception): String = when {
        error is ParseNetworkException -> "Check your connection and try again."
        error is ParseApiException -> when (error.code) {
            ParseApiException.INVALID_EMAIL_ADDRESS ->
                "That doesn't look like a valid email address. Check it and try again."
            ParseApiException.USERNAME_TAKEN, ParseApiException.USER_EMAIL_TAKEN ->
                "That email is already in use. Try signing in instead."
            ParseApiException.OBJECT_NOT_FOUND -> "That email or password is incorrect."
            else -> "Something went wrong. Please try again."
        }
        else -> "Something went wrong. Please try again."
    }
}
