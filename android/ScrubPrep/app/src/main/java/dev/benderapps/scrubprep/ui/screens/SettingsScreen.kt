package dev.benderapps.scrubprep.ui.screens

import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.outlined.CreditCard
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.PanTool
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.ReportProblem
import androidx.compose.material.icons.outlined.ConfirmationNumber
import androidx.compose.material.icons.outlined.StarOutline
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import dev.benderapps.scrubprep.R
import dev.benderapps.scrubprep.config.AppLinks
import dev.benderapps.scrubprep.data.SubscriptionManager
import dev.benderapps.scrubprep.ui.components.ScreenScaffold
import dev.benderapps.scrubprep.ui.components.SecondaryText
import dev.benderapps.scrubprep.ui.components.SoftDivider
import dev.benderapps.scrubprep.ui.components.openUrl
import dev.benderapps.scrubprep.viewmodel.AuthViewModel
import kotlinx.coroutines.launch

/** Settings tab — account sign-out and deletion, subscription management, and app information. */
@Composable
fun SettingsScreen(auth: AuthViewModel) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var showSignOutConfirmation by remember { mutableStateOf(false) }
    var showDeleteAccountConfirmation by remember { mutableStateOf(false) }
    var isDeletingAccount by remember { mutableStateOf(false) }
    var showDeleteAccountError by remember { mutableStateOf(false) }

    ScreenScaffold(title = "Settings") {
        Column(Modifier.verticalScroll(rememberScrollState()).padding(bottom = 24.dp)) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("Scrub Prep", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                SecondaryText("Your AI companion for the surgery clerkship.")
            }

            SettingsSection("Account")
            val email = auth.currentUser?.email
            SecondaryText(
                if (!email.isNullOrEmpty()) "Signed in as $email." else "Signed in.",
                Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
            )
            SettingsRow("Sign Out", Icons.AutoMirrored.Outlined.Logout, destructive = true) { showSignOutConfirmation = true }
            SettingsRow("Delete Account", Icons.Outlined.DeleteOutline, destructive = true, isInProgress = isDeletingAccount, enabled = !isDeletingAccount) {
                showDeleteAccountConfirmation = true
            }

            SubscriptionSection()

            SettingsSection("Medical Disclaimer")
            Text(
                "Scrub Prep is an educational tool for medical students and is not intended to provide patient-specific medical advice, diagnosis, or treatment recommendations. Clinical decisions should be made under the supervision of the student's clinical team.",
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
            )
            SettingsRow("Report an AI Concern", Icons.Outlined.ReportProblem, isExternal = true) {
                openUrl(context, "mailto:${AppLinks.SUPPORT_EMAIL}?subject=" + Uri.encode("Report AI concerns"))
            }

            SettingsSection("Creator")
            Row(Modifier.padding(horizontal = 16.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Image(
                    painter = painterResource(R.drawable.creator_headshot),
                    contentDescription = "Portrait of Dr. Edward Bender, retired cardiothoracic surgeon and creator of Scrub Prep",
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.size(60.dp).clip(CircleShape),
                )
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        "Scrub Prep was created by Edward Bender, MD, a retired cardiothoracic surgeon and former Clinical Professor of Cardiothoracic Surgery at Stanford University.",
                        style = MaterialTheme.typography.bodyMedium,
                    )
                    Text(
                        "Scrub Prep is an independent educational application and is not affiliated with or endorsed by Stanford University.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            SettingsSection("Contact")
            SettingsRow("Email Support", Icons.Outlined.Email, subtitle = AppLinks.SUPPORT_EMAIL, isExternal = true) {
                openUrl(context, "mailto:${AppLinks.SUPPORT_EMAIL}?subject=" + Uri.encode("Scrub Prep"))
            }
            SecondaryText("Questions, feedback, or something not working? Reach out anytime.", Modifier.padding(horizontal = 16.dp, vertical = 4.dp))

            SettingsSection("Legal")
            SettingsRow("Terms of Use", Icons.Outlined.Description, isExternal = true) { openUrl(context, AppLinks.TERMS_OF_USE) }
            SettingsRow("Privacy Policy", Icons.Outlined.PanTool, isExternal = true) { openUrl(context, AppLinks.PRIVACY_POLICY) }
        }
    }

    if (showSignOutConfirmation) {
        AlertDialog(
            onDismissRequest = { showSignOutConfirmation = false },
            title = { Text("Sign out of Scrub Prep?") },
            text = { Text("Your saved cases and notes stay with your account, so they'll be here when you sign back in.") },
            confirmButton = {
                TextButton(onClick = {
                    showSignOutConfirmation = false
                    auth.logOut()
                }) { Text("Sign Out", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { showSignOutConfirmation = false }) { Text("Cancel") } },
        )
    }
    if (showDeleteAccountConfirmation) {
        AlertDialog(
            onDismissRequest = { showDeleteAccountConfirmation = false },
            title = { Text("Delete your account?") },
            text = {
                Text("This permanently deletes your account, saved cases, and Quiz Me sessions. This can't be undone. Deleting your account doesn't cancel an active subscription — cancel it first from the Subscription section above.")
            },
            confirmButton = {
                TextButton(onClick = {
                    showDeleteAccountConfirmation = false
                    scope.launch {
                        isDeletingAccount = true
                        val deleted = auth.deleteAccount()
                        isDeletingAccount = false
                        if (!deleted) showDeleteAccountError = true
                    }
                }) { Text("Delete Account", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { showDeleteAccountConfirmation = false }) { Text("Cancel") } },
        )
    }
    if (showDeleteAccountError) {
        AlertDialog(
            onDismissRequest = { showDeleteAccountError = false },
            title = { Text("Couldn't Delete Account") },
            text = { Text("Check your connection and try again. If this keeps happening, contact ${AppLinks.SUPPORT_EMAIL}.") },
            confirmButton = { TextButton(onClick = { showDeleteAccountError = false }) { Text("OK") } },
        )
    }
}

/** The Subscription section — current plan, subscribe/manage row, Restore Purchases, and Redeem Code. */
@Composable
private fun SubscriptionSection() {
    val context = LocalContext.current
    val subscriptions = remember { context.subscriptionManager() }
    val scope = rememberCoroutineScope()
    var showPaywall by remember { mutableStateOf(false) }
    var isRestoring by remember { mutableStateOf(false) }
    var restoreResultMessage by remember { mutableStateOf<String?>(null) }

    SettingsSection("Subscription")

    val active = subscriptions.activeSubscription
    // The subscribed plan's own Play display name — null while products haven't loaded yet or
    // there's no active subscription.
    val planName = active?.let { sub -> subscriptions.plans.firstOrNull { it.productId == sub.productId }?.displayName }
    Column(Modifier.padding(horizontal = 16.dp, vertical = 8.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(planName ?: "Scrub Prep", style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
        // Never describes a canceled-but-still-valid subscription as "expired" — Play only
        // reports a purchase while its paid period is still running. (Play's client API
        // doesn't expose the renewal date, so none is shown.)
        SecondaryText(
            when {
                active == null -> "No active subscription."
                active.willAutoRenew -> "Active — renews automatically."
                else -> "Active until the end of the current period (auto-renew is off)."
            },
        )
    }

    if (active != null) {
        SettingsRow("Manage Subscription", Icons.Outlined.CreditCard, isExternal = true) {
            openUrl(
                context,
                "https://play.google.com/store/account/subscriptions?sku=${active.productId}&package=${context.packageName}",
            )
        }
    } else {
        SettingsRow("Subscribe", Icons.Outlined.StarOutline) { showPaywall = true }
    }

    SettingsRow("Restore Purchases", Icons.Outlined.Refresh, isInProgress = isRestoring, enabled = !isRestoring) {
        isRestoring = true
        scope.launch {
            restoreResultMessage = try {
                subscriptions.restore()
                if (subscriptions.hasActiveSubscription) "Your subscription has been restored."
                else "No active subscription was found for this Google account."
            } catch (e: Exception) {
                "Couldn't restore purchases. Check your connection and try again."
            }
            isRestoring = false
        }
    }
    SettingsRow("Redeem Promo Code", Icons.Outlined.ConfirmationNumber, isExternal = true) {
        openUrl(context, "https://play.google.com/redeem")
    }

    if (showPaywall) PaywallSheet(onDismiss = { showPaywall = false })
    restoreResultMessage?.let { message ->
        AlertDialog(
            onDismissRequest = { restoreResultMessage = null },
            title = { Text("Restore Purchases") },
            text = { Text(message) },
            confirmButton = { TextButton(onClick = { restoreResultMessage = null }) { Text("OK") } },
        )
    }
}

@Composable
private fun SettingsSection(title: String) {
    Column {
        SoftDivider(Modifier.padding(top = 8.dp))
        Text(
            title,
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(start = 16.dp, end = 16.dp, top = 16.dp, bottom = 4.dp),
        )
    }
}

/** A tappable Settings row: an icon and title, plus an optional secondary line, a trailing arrow for links, or a spinner. */
@Composable
private fun SettingsRow(
    title: String,
    icon: ImageVector,
    subtitle: String? = null,
    isExternal: Boolean = false,
    isInProgress: Boolean = false,
    destructive: Boolean = false,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    val tint = if (destructive) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
    Row(
        Modifier.fillMaxWidth().clickable(enabled = enabled, onClick = onClick).padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Icon(icon, contentDescription = null, tint = tint)
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyLarge, color = tint)
            if (subtitle != null) SecondaryText(subtitle)
        }
        if (isInProgress) {
            CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
        } else if (isExternal) {
            Icon(Icons.AutoMirrored.Outlined.OpenInNew, contentDescription = null, modifier = Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
