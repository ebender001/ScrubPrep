package dev.benderapps.scrubprep.data

import android.content.Context
import android.content.SharedPreferences

/** The signed-in user, as far as the app needs to know. */
data class SignedInUser(val objectId: String, val email: String?)

/**
 * Persists the Parse session token and basic user info across launches (the Android
 * counterpart of ParseSwift's Keychain-backed `User.current`). Lives in app-private
 * storage, which is excluded from backups.
 */
class SessionStore(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("session.v1", Context.MODE_PRIVATE)

    val sessionToken: String? get() = prefs.getString(KEY_TOKEN, null)

    fun currentUser(): SignedInUser? {
        val token = sessionToken ?: return null
        val id = prefs.getString(KEY_USER_ID, null) ?: return null
        return SignedInUser(id, prefs.getString(KEY_EMAIL, null)).takeIf { token.isNotEmpty() }
    }

    fun save(sessionToken: String, user: SignedInUser) {
        prefs.edit()
            .putString(KEY_TOKEN, sessionToken)
            .putString(KEY_USER_ID, user.objectId)
            .putString(KEY_EMAIL, user.email)
            .apply()
    }

    // Not session data, but a per-device UI preference that lives alongside it.
    fun sortOrderName(): String? = prefs.getString(KEY_SORT_ORDER, null)

    fun saveSortOrderName(name: String) {
        prefs.edit().putString(KEY_SORT_ORDER, name).apply()
    }

    /** Signing out clears the session but keeps UI preferences. */
    fun clear() {
        val sortOrder = sortOrderName()
        prefs.edit().clear().apply()
        sortOrder?.let(::saveSortOrderName)
    }

    private companion object {
        const val KEY_TOKEN = "token"
        const val KEY_USER_ID = "userId"
        const val KEY_EMAIL = "email"
        const val KEY_SORT_ORDER = "casesSortOrder"
    }
}
