import StoreKit
import SwiftUI

/// One selectable subscription plan on the paywall.
struct PaywallPlanCard: View {
    let product: Product
    let isSelected: Bool
    let isRecommended: Bool
    let isDisabled: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(planTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if isRecommended {
                            bestValueChip
                        }
                    }
                    if let period = product.subscription?.subscriptionPeriod {
                        Text("\(product.displayPrice) \(billingLabel(for: period))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var bestValueChip: some View {
        Text("BEST VALUE")
            .font(.system(size: 10, weight: .bold))
            .tracking(0.4)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.accentColor, in: Capsule())
            .foregroundStyle(.white)
    }

    // "Monthly" / "Every 3 months" per the product's own StoreKit period — never a
    // hard-coded label tied to a specific product ID, so this stays correct if the
    // durations are ever reconfigured in App Store Connect.
    private var planTitle: String {
        guard let period = product.subscription?.subscriptionPeriod else { return product.displayName }
        switch (period.unit, period.value) {
        case (.month, 1): return "Monthly"
        case (.month, let n): return "Every \(n) Months"
        case (.year, 1): return "Yearly"
        case (.week, 1): return "Weekly"
        case (.day, 1): return "Daily"
        default: return product.displayName
        }
    }

    // The FULL amount charged for that period (StoreKit's displayPrice already is the
    // total for the period, never a computed monthly-equivalent) — e.g. "$2.99 billed
    // every 3 months", not "$1.00/mo".
    private func billingLabel(for period: Product.SubscriptionPeriod) -> String {
        switch (period.unit, period.value) {
        case (.month, 1): return "per month"
        case (.year, 1): return "per year"
        case (.week, 1): return "per week"
        case (.day, 1): return "per day"
        case (.month, let n): return "billed every \(n) months"
        case (.year, let n): return "billed every \(n) years"
        case (.week, let n): return "billed every \(n) weeks"
        case (.day, let n): return "billed every \(n) days"
        @unknown default: return ""
        }
    }
}
