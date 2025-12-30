//
//  PaywallView.swift
//  Quote AI
//
//  Premium subscription paywall
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL

    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://gist.github.com/vbin210327-real/131a5d4d01c2591efa84453c78d9ba9c")!

    @State private var selectedPackage: Package?
    @State private var selectedFallbackPlan: String? = "yearly"
    @State private var showContent = false
    @State private var showDismissAlert = false

    var onComplete: () -> Void
    private let heroZoomOutScale: CGFloat = 1.2
    private let heroBackgroundBlur: CGFloat = 18

    // Check if yearly/annual is selected (for free trial button text)
    private var isYearlySelected: Bool {
        if let package = selectedPackage {
            return package.packageType == .annual
        }
        return selectedFallbackPlan == "yearly"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-bleed hero image as background
                Image("PaywallHero")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(heroZoomOutScale, anchor: .top)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    .background(
                        Image("PaywallHero")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .blur(radius: heroBackgroundBlur)
                    )
                    .clipped()
                    .ignoresSafeArea()

                // Close button (top-left)
                VStack {
                    HStack {
                        Button(action: {
                            showDismissAlert = true
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, 60)
                        Spacer()
                    }
                    Spacer()
                }
                .zIndex(10)

                // Gradient overlay - transparent at top, dark at bottom
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.black.opacity(0), location: 0),
                        .init(color: Color.black.opacity(0.3), location: 0.4),
                        .init(color: Color.black.opacity(0.85), location: 0.6),
                        .init(color: Color.black, location: 0.75)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Content
                VStack(spacing: 0) {
                    Spacer()

                    // Title
                    VStack(spacing: 8) {
                        Text(localization.string(for: "paywall.unlimitedAccess"))
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))

                        Text("Quote AI")
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(Color(hex: "E4CFAA"))

                        Text(localization.string(for: "paywall.subtitle"))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 4)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showContent)

                    Spacer()
                        .frame(height: 28)

                    // Pricing options
                    VStack(spacing: 16) {
                        if let offering = subscriptionManager.currentOffering {
                            if let yearly = offering.annual {
                                PricingCard(
                                    title: localization.string(for: "paywall.yearly"),
                                    subtitle: localization.string(for: "paywall.freeTrial"),
                                    price: yearly.localizedPriceString,
                                    isSelected: selectedPackage?.identifier == yearly.identifier,
                                    isBestValue: true,
                                    savingsText: localization.string(for: "paywall.savingsText"),
                                    perMonthPrice: localization.string(for: "paywall.perMonth")
                                ) { selectedPackage = yearly }
                            }

                            if let monthly = offering.monthly {
                                PricingCard(
                                    title: localization.string(for: "paywall.monthly"),
                                    subtitle: localization.string(for: "paywall.cancelAnytime"),
                                    price: monthly.localizedPriceString,
                                    isSelected: selectedPackage?.identifier == monthly.identifier,
                                    isBestValue: false
                                ) { selectedPackage = monthly }
                            }

                            if let weekly = offering.weekly {
                                PricingCard(
                                    title: localization.string(for: "paywall.weekly"),
                                    subtitle: localization.string(for: "paywall.cancelAnytime"),
                                    price: weekly.localizedPriceString,
                                    isSelected: selectedPackage?.identifier == weekly.identifier,
                                    isBestValue: false
                                ) { selectedPackage = weekly }
                            }
                        } else {
                            // Fallback prices
                            PricingCard(
                                title: localization.string(for: "paywall.yearly"),
                                subtitle: localization.string(for: "paywall.freeTrial"),
                                price: "$29.99",
                                isSelected: selectedFallbackPlan == "yearly",
                                isBestValue: true,
                                savingsText: localization.string(for: "paywall.savingsText"),
                                perMonthPrice: localization.string(for: "paywall.perMonth")
                            ) { selectedFallbackPlan = "yearly" }

                            PricingCard(
                                title: localization.string(for: "paywall.monthly"),
                                subtitle: localization.string(for: "paywall.cancelAnytime"),
                                price: "$9.99",
                                isSelected: selectedFallbackPlan == "monthly",
                                isBestValue: false
                            ) { selectedFallbackPlan = "monthly" }

                            PricingCard(
                                title: localization.string(for: "paywall.weekly"),
                                subtitle: localization.string(for: "paywall.cancelAnytime"),
                                price: "$4.99",
                                isSelected: selectedFallbackPlan == "weekly",
                                isBestValue: false
                            ) { selectedFallbackPlan = "weekly" }
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)

                    Spacer()
                        .frame(height: 24)

                    // Continue button
                    Button(action: {
                        Task {
                            if let package = selectedPackage {
                                let success = await subscriptionManager.purchase(package: package)
                                if success {
                                    onComplete()
                                }
                            } else {
                                // No valid package available - retry fetching offerings
                                await subscriptionManager.fetchOfferings()
                            }
                        }
                    }) {
                        HStack {
                            if subscriptionManager.isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else if selectedPackage == nil {
                                // Show retry text when offerings not loaded
                                Text(localization.string(for: "paywall.retry"))
                                    .font(.system(size: 18, weight: .semibold))
                            } else {
                                Text(isYearlySelected ? localization.string(for: "paywall.startTrial") : localization.string(for: "paywall.continue"))
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedPackage != nil ? Color.white : Color.white.opacity(0.5))
                        .foregroundColor(.black)
                        .cornerRadius(28)
                    }
                    .disabled(subscriptionManager.isPurchasing)
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)

                    // Trial details
                    if isYearlySelected {
                        Text(localization.string(for: "paywall.trialDetails"))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.top, 12)
                            .opacity(showContent ? 1 : 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: showContent)
                    }

                    Spacer()
                        .frame(height: 16)

                    // Footer links
                    HStack(spacing: 28) {
                        Button {
                            openURL(termsURL)
                        } label: {
                            Text(localization.string(for: "paywall.termsOfUse"))
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                                .underline()
                        }

                        Button {
                            openURL(privacyURL)
                        } label: {
                            Text(localization.string(for: "paywall.privacyPolicy"))
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                                .underline()
                        }

                        Button {
                            Task {
                                let success = await subscriptionManager.restorePurchases()
                                if success { onComplete() }
                            }
                        } label: {
                            Text(localization.string(for: "paywall.restore"))
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                                .underline()
                        }
                    }
                    .padding(.bottom, 16)
                    .opacity(showContent ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                }
                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if let yearly = subscriptionManager.currentOffering?.annual {
                selectedPackage = yearly
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showContent = true
            }
        }
        .alert(localization.string(for: "paywall.dismissTitle"), isPresented: $showDismissAlert) {
            Button(localization.string(for: "paywall.dismissStay"), role: .cancel) { }
            Button(localization.string(for: "paywall.dismissLeave"), role: .destructive) {
                dismiss()
            }
        } message: {
            Text(localization.string(for: "paywall.dismissMessage"))
        }
    }
}

// MARK: - Pricing Card
struct PricingCard: View {
    let title: String
    let subtitle: String
    let price: String
    let isSelected: Bool
    let isBestValue: Bool
    var savingsText: String? = nil
    var perMonthPrice: String? = nil
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onSelect()
        }) {
            ZStack(alignment: .top) {
                // Card content
                HStack(spacing: 12) {
                    // Radio circle
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color(hex: "E4CFAA") : Color.white.opacity(0.4), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(Color(hex: "E4CFAA"))
                                .frame(width: 14, height: 14)
                        }
                    }

                    // Title & subtitle
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    // Price
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(price)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        if let perMonth = perMonthPrice {
                            Text(perMonth)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .padding(.top, savingsText != nil ? 6 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color(hex: "E4CFAA") : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                        )
                )

                // Savings badge floating on top
                if let savings = savingsText {
                    Text(savings)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(hex: "E4CFAA"))
                        )
                        .offset(y: -14)
                }
            }
        }
    }
}

#Preview {
    PaywallView(onComplete: {})
}
