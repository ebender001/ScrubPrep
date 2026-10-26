package dev.benderapps.scrubprep.data

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.android.billingclient.api.acknowledgePurchase
import com.android.billingclient.api.queryProductDetails
import com.android.billingclient.api.queryPurchasesAsync
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlin.coroutines.resume
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * Owns everything Google Play Billing: loading the two subscription products, purchasing,
 * restoring, and keeping a live purchase listener running for the app's lifetime.
 *
 * Trust model (same as the iOS app): subscription access is derived entirely from Play's own
 * on-device purchase data (`queryPurchasesAsync`) — nothing here calls a custom server, and
 * nothing is cached across launches beyond what Play itself persists. See backend/README.md's
 * "Subscriptions & complimentary case" section for the accepted tradeoff (no independent
 * server-side enforcement of an active subscription).
 */
class SubscriptionManager(context: Context) {
    companion object {
        // Play Console product IDs may not contain uppercase letters, so these differ from
        // the App Store identifiers (dev.benderapps.ScrubPrep.subscription.*). Create one
        // subscription per ID in Play Console, each with a single auto-renewing base plan.
        const val MONTHLY_PRODUCT_ID = "scrubprep_monthly"
        const val QUARTERLY_PRODUCT_ID = "scrubprep_quarterly"
        val PRODUCT_IDS = listOf(MONTHLY_PRODUCT_ID, QUARTERLY_PRODUCT_ID)
    }

    /** What Settings shows for "current plan", recomputed fresh on every refresh. */
    data class ActiveSubscription(val productId: String, val willAutoRenew: Boolean)

    enum class PurchaseOutcome { Success, Pending, UserCancelled }

    /** One purchasable plan — a Play subscription's first (base plan) offer. */
    data class Plan(
        val details: ProductDetails,
        val offerToken: String,
        val displayName: String,
        val displayPrice: String,
        /** ISO 8601 billing period, e.g. "P1M" or "P3M". */
        val billingPeriod: String,
    ) {
        val productId: String get() = details.productId
    }

    var plans by mutableStateOf<List<Plan>>(emptyList())
        private set
    var isLoadingProducts by mutableStateOf(false)
        private set
    var productsLoadError by mutableStateOf<String?>(null)
        private set
    var activeSubscription by mutableStateOf<ActiveSubscription?>(null)
        private set

    val hasActiveSubscription: Boolean get() = activeSubscription != null

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var pendingPurchase: CompletableDeferred<PurchaseOutcome>? = null

    // Purchases can arrive at any time (renewals, a redeemed code, an approved pending
    // purchase), not only from an explicit purchase() call in this session.
    private val purchasesListener = PurchasesUpdatedListener { result, purchases ->
        scope.launch {
            if (result.responseCode == BillingClient.BillingResponseCode.OK) {
                purchases.orEmpty().forEach { acknowledgeIfNeeded(it) }
                refreshEntitlements()
            }
            pendingPurchase?.complete(
                when (result.responseCode) {
                    BillingClient.BillingResponseCode.OK ->
                        if (purchases.orEmpty().any { it.purchaseState == Purchase.PurchaseState.PENDING }) {
                            PurchaseOutcome.Pending
                        } else {
                            PurchaseOutcome.Success
                        }
                    BillingClient.BillingResponseCode.USER_CANCELED -> PurchaseOutcome.UserCancelled
                    else -> null
                } ?: error("Purchase failed: ${result.debugMessage}"),
            )
        }
    }

    private val billingClient: BillingClient = BillingClient.newBuilder(context.applicationContext)
        .setListener(purchasesListener)
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
        .enableAutoServiceReconnection()
        .build()

    init {
        scope.launch {
            loadProducts()
            refreshEntitlements()
        }
    }

    private suspend fun ensureConnected(): Boolean {
        if (billingClient.isReady) return true
        return suspendCancellableCoroutine { continuation ->
            billingClient.startConnection(object : BillingClientStateListener {
                override fun onBillingSetupFinished(result: BillingResult) {
                    if (continuation.isActive) {
                        continuation.resume(result.responseCode == BillingClient.BillingResponseCode.OK)
                    }
                }

                override fun onBillingServiceDisconnected() {}
            })
        }
    }

    suspend fun loadProducts() {
        isLoadingProducts = true
        try {
            if (!ensureConnected()) {
                productsLoadError = "Couldn't load subscription options. Check your connection and try again."
                return
            }
            val params = QueryProductDetailsParams.newBuilder()
                .setProductList(
                    PRODUCT_IDS.map {
                        QueryProductDetailsParams.Product.newBuilder()
                            .setProductId(it)
                            .setProductType(BillingClient.ProductType.SUBS)
                            .build()
                    },
                )
                .build()
            val result = billingClient.queryProductDetails(params)
            if (result.billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                productsLoadError = "Couldn't load subscription options. Check your connection and try again."
                return
            }
            plans = result.productDetailsList.orEmpty().mapNotNull { details ->
                val offer = details.subscriptionOfferDetails?.firstOrNull() ?: return@mapNotNull null
                // The recurring phase is the last one (earlier phases are intro/trial prices).
                val phase = offer.pricingPhases.pricingPhaseList.lastOrNull() ?: return@mapNotNull null
                Plan(details, offer.offerToken, details.name, phase.formattedPrice, phase.billingPeriod)
            }
            productsLoadError = if (plans.isEmpty()) "These subscription options aren't available right now." else null
        } catch (e: Exception) {
            productsLoadError = "Couldn't load subscription options. Check your connection and try again."
        } finally {
            isLoadingProducts = false
        }
    }

    /**
     * Recomputes [activeSubscription] straight from Play's own purchase data. Call on
     * launch, on foreground, and right after any purchase/restore/purchase update.
     */
    suspend fun refreshEntitlements() {
        if (!ensureConnected()) return
        val result = billingClient.queryPurchasesAsync(
            QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build(),
        )
        if (result.billingResult.responseCode != BillingClient.BillingResponseCode.OK) return
        var found: ActiveSubscription? = null
        for (purchase in result.purchasesList) {
            if (purchase.purchaseState != Purchase.PurchaseState.PURCHASED) continue
            val productId = purchase.products.firstOrNull { it in PRODUCT_IDS } ?: continue
            acknowledgeIfNeeded(purchase)
            found = ActiveSubscription(productId, purchase.isAutoRenewing)
        }
        activeSubscription = found
    }

    /** Only starts the Play purchase sheet once Subscribe is tapped. */
    suspend fun purchase(activity: Activity, plan: Plan): PurchaseOutcome {
        if (!ensureConnected()) error("Billing unavailable")
        val deferred = CompletableDeferred<PurchaseOutcome>()
        pendingPurchase = deferred
        val flowParams = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(
                listOf(
                    BillingFlowParams.ProductDetailsParams.newBuilder()
                        .setProductDetails(plan.details)
                        .setOfferToken(plan.offerToken)
                        .build(),
                ),
            )
            .build()
        val launch = billingClient.launchBillingFlow(activity, flowParams)
        if (launch.responseCode != BillingClient.BillingResponseCode.OK) {
            pendingPurchase = null
            error("Couldn't start purchase: ${launch.debugMessage}")
        }
        return try {
            deferred.await()
        } finally {
            pendingPurchase = null
        }
    }

    /** "Restore Purchases" — re-syncs whatever Play currently says this account owns. */
    suspend fun restore() {
        check(ensureConnected()) { "Billing unavailable" }
        refreshEntitlements()
    }

    /** Play refunds a purchase that isn't acknowledged within three days. */
    private suspend fun acknowledgeIfNeeded(purchase: Purchase) {
        if (purchase.purchaseState != Purchase.PurchaseState.PURCHASED || purchase.isAcknowledged) return
        runCatching {
            billingClient.acknowledgePurchase(
                AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.purchaseToken).build(),
            )
        }
    }
}
