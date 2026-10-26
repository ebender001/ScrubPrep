package dev.benderapps.scrubprep.ui.screens

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import dev.benderapps.scrubprep.ScrubPrepApplication
import dev.benderapps.scrubprep.config.AppLinks
import dev.benderapps.scrubprep.data.SubscriptionManager
import dev.benderapps.scrubprep.data.SubscriptionManager.Plan
import dev.benderapps.scrubprep.data.SubscriptionManager.PurchaseOutcome
import dev.benderapps.scrubprep.ui.components.CardSurface
import dev.benderapps.scrubprep.ui.components.PrimaryButton
import dev.benderapps.scrubprep.ui.components.SecondaryText
import dev.benderapps.scrubprep.ui.components.openUrl
import kotlinx.coroutines.launch

internal fun Context.findActivity(): Activity? {
    var current = this
    while (current is ContextWrapper) {
        if (current is Activity) return current
        current = current.baseContext
    }
    return null
}

internal fun Context.subscriptionManager(): SubscriptionManager =
    (applicationContext as ScrubPrepApplication).container.subscriptions

private enum class PurchaseState { Idle, Purchasing, Pending, Restoring }

/**
 * The paywall — shown when Home determines (entirely client-side, before any AI request)
 * that a new case needs a subscription, or opened directly from Settings. Never mentions the
 * complimentary case — this screen exists to sell the subscription, not explain the
 * free-case mechanic.
 *
 * [onPurchaseCompleted] is called exactly once, right after Play confirms an active
 * subscription — from a purchase or a restore — and the presenter uses it to dismiss this
 * sheet and resume whatever case-generation attempt triggered the paywall.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaywallSheet(onDismiss: () -> Unit, onPurchaseCompleted: () -> Unit = onDismiss) {
    val context = LocalContext.current
    val subscriptions = remember { context.subscriptionManager() }
    val scope = rememberCoroutineScope()

    // Defaults to the better-value plan — leading with, and pre-selecting, the recommended
    // option is standard paywall practice.
    var selectedProductId by remember { mutableStateOf(SubscriptionManager.QUARTERLY_PRODUCT_ID) }
    var purchaseState by remember { mutableStateOf(PurchaseState.Idle) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    // A purchase can report success both through subscribe() and the entitlement observer.
    var didComplete by remember { mutableStateOf(false) }
    val isBusy = purchaseState != PurchaseState.Idle

    fun complete() {
        if (didComplete) return
        didComplete = true
        onPurchaseCompleted()
    }

    // Always refetch: the manager lives for the whole process, so "only fetch if empty"
    // would mean a plan that becomes available after launch never appears until a relaunch.
    LaunchedEffect(Unit) { subscriptions.loadProducts() }

    // Completes whenever a subscription becomes active while open (e.g. a pending purchase
    // that gets approved).
    LaunchedEffect(subscriptions.hasActiveSubscription) {
        if (subscriptions.hasActiveSubscription) complete()
    }

    // Falls back to whatever plan actually loaded if the preferred default isn't among the
    // loaded products — without this, Subscribe would stay permanently disabled.
    val plans = remember(subscriptions.plans) {
        subscriptions.plans.sortedWith(
            compareByDescending<Plan> { it.productId == SubscriptionManager.QUARTERLY_PRODUCT_ID }
                .thenBy { periodMonths(it.billingPeriod) },
        )
    }
    LaunchedEffect(plans) {
        if (plans.isNotEmpty() && plans.none { it.productId == selectedProductId }) selectedProductId = plans.first().productId
    }
    val selectedPlan = plans.firstOrNull { it.productId == selectedProductId }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = MaterialTheme.colorScheme.background,
    ) {
        Column(
            Modifier.verticalScroll(rememberScrollState()).padding(start = 16.dp, end = 16.dp, bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("Prepare for your next case", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                SecondaryText("Get access to case preparation, Quiz Me, and Rapid Fire.")
            }

            if (subscriptions.isLoadingProducts) {
                Row(Modifier.fillMaxWidth().padding(vertical = 24.dp), horizontalArrangement = Arrangement.Center) {
                    CircularProgressIndicator()
                }
            } else if (subscriptions.productsLoadError != null) {
                CardSurface {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        SecondaryText(subscriptions.productsLoadError.orEmpty())
                        TextButton(onClick = { scope.launch { subscriptions.loadProducts() } }) { Text("Try Again") }
                    }
                }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    plans.forEach { plan ->
                        PlanCard(
                            plan = plan,
                            isSelected = plan.productId == selectedProductId,
                            isRecommended = plan.productId == SubscriptionManager.QUARTERLY_PRODUCT_ID,
                            enabled = !isBusy,
                            onSelect = { selectedProductId = plan.productId },
                        )
                    }
                }

                if (purchaseState == PurchaseState.Pending) {
                    SecondaryText("Waiting for approval — you'll get access once it's confirmed.")
                }
                errorMessage?.let {
                    Text(it, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.error)
                }

                PrimaryButton(
                    text = "Subscribe",
                    enabled = !isBusy && selectedPlan != null,
                    isLoading = purchaseState == PurchaseState.Purchasing,
                    onClick = {
                        val plan = selectedPlan ?: return@PrimaryButton
                        val activity = context.findActivity() ?: return@PrimaryButton
                        errorMessage = null
                        purchaseState = PurchaseState.Purchasing
                        scope.launch {
                            try {
                                when (subscriptions.purchase(activity, plan)) {
                                    PurchaseOutcome.Success -> {
                                        purchaseState = PurchaseState.Idle
                                        if (subscriptions.hasActiveSubscription) {
                                            complete()
                                        } else {
                                            errorMessage = "Your purchase went through, but we're still waiting on confirmation. This usually resolves in a moment — try again, or check Manage Subscription in Settings."
                                        }
                                    }
                                    PurchaseOutcome.Pending -> purchaseState = PurchaseState.Pending
                                    PurchaseOutcome.UserCancelled -> purchaseState = PurchaseState.Idle
                                }
                            } catch (e: Exception) {
                                purchaseState = PurchaseState.Idle
                                errorMessage = "Something went wrong completing your purchase. Please try again."
                            }
                        }
                    },
                )

                Text(
                    "Payment is charged to your Google Play account at confirmation. Your subscription renews automatically unless canceled at least 24 hours before the current period ends. Manage or cancel in your Google Play subscription settings.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )

                TextButton(
                    enabled = !isBusy,
                    modifier = Modifier.fillMaxWidth(),
                    onClick = {
                        errorMessage = null
                        purchaseState = PurchaseState.Restoring
                        scope.launch {
                            try {
                                subscriptions.restore()
                                purchaseState = PurchaseState.Idle
                                if (subscriptions.hasActiveSubscription) {
                                    complete()
                                } else {
                                    errorMessage = "No active subscription was found for this Google account."
                                }
                            } catch (e: Exception) {
                                purchaseState = PurchaseState.Idle
                                errorMessage = "Couldn't restore purchases. Please try again."
                            }
                        }
                    },
                ) {
                    if (purchaseState == PurchaseState.Restoring) CircularProgressIndicator(Modifier.padding(2.dp), strokeWidth = 2.dp)
                    else Text("Restore Purchases")
                }

                TextButton(
                    enabled = !isBusy,
                    modifier = Modifier.fillMaxWidth(),
                    onClick = { openUrl(context, "https://play.google.com/redeem") },
                ) { Text("Have a promo code? Redeem it") }

                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterHorizontally)) {
                    Text("Terms of Use", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.clickable { openUrl(context, AppLinks.TERMS_OF_USE) })
                    Text("Privacy Policy", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.clickable { openUrl(context, AppLinks.PRIVACY_POLICY) })
                }
            }
        }
    }
}

/** One selectable subscription plan on the paywall. */
@Composable
private fun PlanCard(plan: Plan, isSelected: Boolean, isRecommended: Boolean, enabled: Boolean, onSelect: () -> Unit) {
    val shape = RoundedCornerShape(16.dp)
    Row(
        Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceContainer, shape)
            .border(2.dp, if (isSelected) MaterialTheme.colorScheme.primary else Color.Transparent, shape)
            .clickable(enabled = enabled, onClick = onSelect)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(planTitle(plan), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                if (isRecommended) {
                    Text(
                        "BEST VALUE",
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        modifier = Modifier.background(MaterialTheme.colorScheme.primary, CircleShape).padding(horizontal = 7.dp, vertical = 3.dp),
                    )
                }
            }
            SecondaryText("${plan.displayPrice} ${billingLabel(plan.billingPeriod)}")
        }
        Icon(
            if (isSelected) Icons.Filled.CheckCircle else Icons.Outlined.Circle,
            contentDescription = if (isSelected) "Selected" else null,
            tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

/** Months in an ISO 8601 billing period ("P1M", "P3M", "P1Y"); a rough sort key for anything else. */
private fun periodMonths(period: String): Int = parsePeriod(period)?.let { (unit, n) ->
    when (unit) {
        'Y' -> n * 12
        'M' -> n
        else -> 0
    }
} ?: Int.MAX_VALUE

private fun parsePeriod(period: String): Pair<Char, Int>? {
    val match = Regex("^P(\\d+)([DWMY])$").matchEntire(period) ?: return null
    return match.groupValues[2][0] to match.groupValues[1].toInt()
}

// "Monthly" / "Every 3 Months" from the plan's own billing period — never a hard-coded label
// tied to a specific product ID, so this stays correct if the durations change in Play Console.
private fun planTitle(plan: Plan): String {
    val (unit, n) = parsePeriod(plan.billingPeriod) ?: return plan.displayName
    return when {
        n == 1 && unit == 'M' -> "Monthly"
        n == 1 && unit == 'Y' -> "Yearly"
        n == 1 && unit == 'W' -> "Weekly"
        n == 1 && unit == 'D' -> "Daily"
        else -> "Every $n ${unitName(unit)}s".replaceFirstChar { it.uppercase() }.replace(Regex("(?<=\\s)(\\w)")) { it.value.uppercase() }
    }
}

// The FULL amount charged for that period (Play's formatted price already is the total for
// the period, never a computed monthly-equivalent) — e.g. "$2.99 billed every 3 months".
private fun billingLabel(period: String): String {
    val (unit, n) = parsePeriod(period) ?: return ""
    return when {
        n == 1 && unit == 'M' -> "per month"
        n == 1 && unit == 'Y' -> "per year"
        n == 1 && unit == 'W' -> "per week"
        n == 1 && unit == 'D' -> "per day"
        else -> "billed every $n ${unitName(unit)}s"
    }
}

private fun unitName(unit: Char) = when (unit) {
    'D' -> "day"
    'W' -> "week"
    'M' -> "month"
    else -> "year"
}
