package dev.benderapps.scrubprep.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import dev.benderapps.scrubprep.ui.components.PrimaryButton
import dev.benderapps.scrubprep.ui.components.SecondaryText
import dev.benderapps.scrubprep.viewmodel.AuthViewModel

private enum class AuthMode { SignUp, LogIn }

/**
 * Shown whenever there's no signed-in user — sign-in is mandatory, since Cases and Quiz Me
 * sessions live on the backend as the single source of truth, not the device. (Email and
 * password only; the iOS app also offers Sign in with Apple.)
 */
@Composable
fun SignInScreen(auth: AuthViewModel) {
    // Defaults to account creation: sessions persist until an explicit sign-out, so most
    // students only ever type credentials here once, to sign up.
    var mode by rememberSaveable { mutableStateOf(AuthMode.SignUp) }
    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var confirmPassword by rememberSaveable { mutableStateOf("") }
    var infoMessage by remember { mutableStateOf<String?>(null) }
    var isShowingError by remember { mutableStateOf(false) }

    // Arriving with an error already set means an existing account was just bounced here
    // (e.g. session-expired handling) — they need to sign back in, not create a new account.
    LaunchedEffect(Unit) {
        if (auth.errorMessage != null) {
            mode = AuthMode.LogIn
            isShowingError = true
        }
    }
    LaunchedEffect(auth.errorMessage) { isShowingError = auth.errorMessage != null }

    val trimmedEmail = email.trim()
    val isFormValid = trimmedEmail.isNotEmpty() && password.isNotEmpty() &&
        (mode == AuthMode.LogIn || password == confirmPassword)

    Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).safeDrawingPadding().imePadding()) {
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(24.dp),
        ) {
            Column(Modifier.padding(top = 40.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("Scrub Prep", style = MaterialTheme.typography.displaySmall, fontWeight = FontWeight.Bold)
                SecondaryText("Your AI companion for the surgery clerkship.")
            }

            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                // A segmented control rather than a footnote link, so switching to Sign In is
                // obvious for a returning student on a new device.
                Row(
                    Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surfaceContainer, CircleShape).padding(3.dp),
                ) {
                    ModeSegment("Create Account", mode == AuthMode.SignUp, Modifier.weight(1f)) {
                        mode = AuthMode.SignUp
                        infoMessage = null
                        confirmPassword = ""
                    }
                    ModeSegment("Sign In", mode == AuthMode.LogIn, Modifier.weight(1f)) {
                        mode = AuthMode.LogIn
                        infoMessage = null
                        confirmPassword = ""
                    }
                }

                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    label = { Text("Email") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth(),
                )
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text("Password") },
                    singleLine = true,
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth(),
                )
                if (mode == AuthMode.SignUp) {
                    OutlinedTextField(
                        value = confirmPassword,
                        onValueChange = { confirmPassword = it },
                        label = { Text("Confirm Password") },
                        singleLine = true,
                        visualTransformation = PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth(),
                    )
                    if (confirmPassword.isNotEmpty() && confirmPassword != password) {
                        Text("Passwords don't match.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.error)
                    }
                }

                PrimaryButton(
                    text = if (mode == AuthMode.SignUp) "Create Account" else "Sign In",
                    enabled = isFormValid,
                    isLoading = auth.isLoading,
                    onClick = {
                        infoMessage = null
                        if (mode == AuthMode.SignUp) auth.signUp(trimmedEmail, password) else auth.logIn(trimmedEmail, password)
                    },
                )

                infoMessage?.let { SecondaryText(it) }

                if (mode == AuthMode.LogIn) {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                        TextButton(
                            enabled = trimmedEmail.isNotEmpty() && !auth.isLoading,
                            onClick = {
                                auth.resetPassword(trimmedEmail) {
                                    infoMessage = "If an account exists for $trimmedEmail, a reset link is on its way."
                                }
                            },
                        ) { Text("Forgot password?") }
                    }
                }
            }
        }
    }

    if (isShowingError && auth.errorMessage != null) {
        AlertDialog(
            onDismissRequest = { auth.errorMessage = null },
            title = { Text(if (mode == AuthMode.SignUp) "Couldn't create account" else "Couldn't sign in") },
            text = { Text(auth.errorMessage.orEmpty()) },
            confirmButton = { TextButton(onClick = { auth.errorMessage = null }) { Text("OK") } },
        )
    }
}

@Composable
private fun ModeSegment(title: String, isSelected: Boolean, modifier: Modifier, onClick: () -> Unit) {
    Box(
        modifier
            .background(if (isSelected) MaterialTheme.colorScheme.primary else androidx.compose.ui.graphics.Color.Transparent, CircleShape)
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            title,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
            color = if (isSelected) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurface,
        )
    }
}
