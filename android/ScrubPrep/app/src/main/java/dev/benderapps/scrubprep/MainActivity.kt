package dev.benderapps.scrubprep

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.material3.Text
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.compose.viewModel
import dev.benderapps.scrubprep.ui.MainScreen
import dev.benderapps.scrubprep.ui.screens.SignInScreen
import dev.benderapps.scrubprep.ui.theme.ScrubPrepTheme
import dev.benderapps.scrubprep.viewmodel.AuthViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ScrubPrepTheme {
                ScrubPrepRoot()
            }
        }
    }
}

@Composable
private fun ScrubPrepRoot() {
    val auth = containerViewModel { AuthViewModel(it) }
    if (auth.currentUser != null) {
        MainScreen(auth)
    } else {
        SignInScreen(auth)
    }

    if (auth.showAccountCreatedAlert) {
        AlertDialog(
            onDismissRequest = { auth.showAccountCreatedAlert = false },
            title = { Text("Account Created") },
            text = { Text("Check your inbox to confirm your email address — you'll need it if you ever forget your password.") },
            confirmButton = { TextButton(onClick = { auth.showAccountCreatedAlert = false }) { Text("OK") } },
        )
    }
}
