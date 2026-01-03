//
//  UpgradePlanView.swift
//  Quote AI
//
//  Clean plan selection for upgrading subscription
//

import SwiftUI
import RevenueCat

struct UpgradePlanView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var selectedPackage: Package?
    @State private var selectedFallbackPlan: String? = "yearly"
    @State private var showContent = false

    private let goldColor = Color(hex: "E4CFAA")

    // Plan tier levels: weekly=1, monthly=2, yearly=3
    private var currentPlanTier: Int {
        guard let planName = subscriptionManager.subscriptionPlanName?.lowercased() else { return 0 }
        if planName.contains("year") { return 3 }
        if planName.contains("month") { return 2 }
        if planName.contains("week") { return 1 }
        return 0
    }

    private var isUpgrading: Bool {
        subscriptionManager.isProUser && currentPlanTier > 0
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Light gray background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // App Icon
                        appIconSection
                            .padding(.top, 32)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 10)
                            .animation(.easeOut(duration: 0.4), value: showContent)

                        // Title
                        Text(isUpgrading ? localization.string(for: "upgrade.upgradePlan") : localization.string(for: "upgrade.availablePlans"))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 20)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.05), value: showContent)

                        // Plan Cards - only show plans higher than current
                        VStack(spacing: 12) {
                            if let offering = subscriptionManager.currentOffering {
                                // Yearly (tier 3) - show if current tier < 3
                                if currentPlanTier < 3, let yearly = offering.annual {
                                    UpgradePlanCard(
                                        planName: localization.string(for: "upgrade.yearly"),
                                        price: yearly.localizedPriceString,
                                        period: localization.string(for: "upgrade.perYear"),
                                        isSelected: selectedPackage?.identifier == yearly.identifier,
                                        goldColor: goldColor
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedPackage = yearly
                                        }
                                    }
                                }

                                // Monthly (tier 2) - show if current tier < 2
                                if currentPlanTier < 2, let monthly = offering.monthly {
                                    UpgradePlanCard(
                                        planName: localization.string(for: "upgrade.monthly"),
                                        price: monthly.localizedPriceString,
                                        period: localization.string(for: "upgrade.perMonth"),
                                        isSelected: selectedPackage?.identifier == monthly.identifier,
                                        goldColor: goldColor
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedPackage = monthly
                                        }
                                    }
                                }

                                // Weekly (tier 1) - only show if not subscribed at all
                                if currentPlanTier == 0, let weekly = offering.weekly {
                                    UpgradePlanCard(
                                        planName: localization.string(for: "upgrade.weekly"),
                                        price: weekly.localizedPriceString,
                                        period: localization.string(for: "upgrade.perWeek"),
                                        isSelected: selectedPackage?.identifier == weekly.identifier,
                                        goldColor: goldColor
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedPackage = weekly
                                        }
                                    }
                                }
                            } else {
                                // Fallback UI - only show plans higher than current
                                if currentPlanTier < 3 {
                                    UpgradePlanCard(
                                        planName: localization.string(for: "upgrade.yearly"),
                                        price: "$29.99",
                                        period: localization.string(for: "upgrade.perYear"),
                                        isSelected: selectedFallbackPlan == "yearly",
                                        goldColor: goldColor
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedFallbackPlan = "yearly"
                                        }
                                    }
                                }

                                if currentPlanTier < 2 {
                                    UpgradePlanCard(
                                        planName: localization.string(for: "upgrade.monthly"),
                                        price: "$9.99",
                                        period: localization.string(for: "upgrade.perMonth"),
                                        isSelected: selectedFallbackPlan == "monthly",
                                        goldColor: goldColor
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedFallbackPlan = "monthly"
                                        }
                                    }
                                }

                                if currentPlanTier == 0 {
                                    UpgradePlanCard(
                                        planName: localization.string(for: "upgrade.weekly"),
                                        price: "$4.99",
                                        period: localization.string(for: "upgrade.perWeek"),
                                        isSelected: selectedFallbackPlan == "weekly",
                                        goldColor: goldColor
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedFallbackPlan = "weekly"
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: showContent)

                        // Current plan indicator (if upgrading)
                        if isUpgrading, let currentPlan = subscriptionManager.subscriptionPlanName {
                            Text(String(format: localization.string(for: "upgrade.currentPlan"), currentPlan))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.top, 16)
                                .opacity(showContent ? 1 : 0)
                                .animation(.easeOut(duration: 0.4).delay(0.15), value: showContent)
                        }

                        Spacer().frame(height: 32)

                        // Subscribe/Upgrade Button
                        subscribeButton
                            .padding(.horizontal, 20)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary, Color(UIColor.systemGray5))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // Pre-select the next tier up, or yearly if not subscribed
            if let offering = subscriptionManager.currentOffering {
                if currentPlanTier == 0 {
                    // Not subscribed - default to yearly
                    selectedPackage = offering.annual
                } else if currentPlanTier == 1 {
                    // Weekly user - default to monthly (next tier)
                    selectedPackage = offering.monthly ?? offering.annual
                } else if currentPlanTier == 2 {
                    // Monthly user - default to yearly (next tier)
                    selectedPackage = offering.annual
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showContent = true
            }
        }
    }

    // MARK: - App Icon Section
    private var appIconSection: some View {
        Group {
            if let uiImage = UIImage(named: "AppIcon") ?? UIImage(named: "AppIcon60x60") {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            } else {
                // Fallback icon
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text("❞")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }

    // MARK: - Subscribe/Upgrade Button
    private var subscribeButton: some View {
        Button(action: {
            Task {
                if let package = selectedPackage {
                    // This triggers Apple's native upgrade flow automatically
                    let success = await subscriptionManager.purchase(package: package)
                    if success {
                        dismiss()
                    }
                }
            }
        }) {
            HStack(spacing: 8) {
                if subscriptionManager.isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: goldColor))
                } else {
                    Text(isUpgrading ? localization.string(for: "upgrade.upgrade") : localization.string(for: "upgrade.subscribe"))
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.black)
            .foregroundColor(goldColor)
            .cornerRadius(14)
        }
        .disabled(selectedPackage == nil || subscriptionManager.isPurchasing)
        .opacity((selectedPackage == nil || subscriptionManager.isPurchasing) ? 0.6 : 1)
    }
}

// MARK: - Plan Card
struct UpgradePlanCard: View {
    let planName: String
    let price: String
    let period: String
    let isSelected: Bool
    let goldColor: Color
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onSelect()
        }) {
            HStack(spacing: 0) {
                // Plan info
                VStack(alignment: .leading, spacing: 4) {
                    Text(planName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("\(price) \(period)")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(goldColor)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                    } else {
                        Circle()
                            .stroke(Color(UIColor.systemGray3), lineWidth: 2)
                            .frame(width: 26, height: 26)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? goldColor : Color.clear, lineWidth: 2.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UpgradePlanView()
}
