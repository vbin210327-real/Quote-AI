//
//  SubscriptionManager.swift
//  Quote AI
//
//  Manages RevenueCat subscriptions
//

import Foundation
import Combine
import RevenueCat

class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()

    @Published var isProUser = false
    @Published var offerings: Offerings?
    @Published var currentOffering: Offering?
    @Published var isPurchasing = false
    @Published var errorMessage: String?
    
    // Subscription details for display in settings
    @Published var subscriptionPlanName: String?
    @Published var expirationDate: Date?
    @Published var willRenew: Bool = false

    private let apiKey = "appl_bTdDfhcTBvjFXUATEYESBjEGamj" // RevenueCat App Store API key

    private override init() {
        super.init()
    }

    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        Purchases.shared.delegate = self

        // Fetch offerings and check subscription status
        Task {
            await fetchOfferings()
            await checkSubscriptionStatus()
        }
    }

    @MainActor
    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            self.currentOffering = offerings.current
        } catch {
            print("Error fetching offerings: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func checkSubscriptionStatus() async {
        do {
            // Invalidate cache to get fresh data from RevenueCat
            Purchases.shared.invalidateCustomerInfoCache()
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionInfo(from: customerInfo)
        } catch {
            print("Error checking subscription: \(error)")
        }
    }
    
    @MainActor
    private func updateSubscriptionInfo(from customerInfo: CustomerInfo) {
        if let proEntitlement = customerInfo.entitlements["pro"], proEntitlement.isActive {
            self.isProUser = true
            self.expirationDate = proEntitlement.expirationDate
            self.willRenew = proEntitlement.willRenew

            // Determine plan name based on product identifier
            let productId = proEntitlement.productIdentifier
            if productId.contains("annual") || productId.contains("yearly") {
                self.subscriptionPlanName = "Yearly"
            } else if productId.contains("month") {
                self.subscriptionPlanName = "Monthly"
            } else if productId.contains("week") {
                self.subscriptionPlanName = "Weekly"
            } else if productId.contains("lifetime") {
                self.subscriptionPlanName = "Lifetime"
            } else {
                self.subscriptionPlanName = "Pro"
            }
        } else {
            self.isProUser = false
            self.subscriptionPlanName = nil
            self.expirationDate = nil
            self.willRenew = false
        }

        // Sync subscription status to shared UserDefaults for widget access
        let sharedDefaults = UserDefaults(suiteName: SharedConstants.suiteName)
        sharedDefaults?.set(self.isProUser, forKey: SharedConstants.Keys.isProUser)
        sharedDefaults?.synchronize()
    }

    @MainActor
    func purchase(package: Package) async -> Bool {
        isPurchasing = true
        errorMessage = nil

        do {
            let result = try await Purchases.shared.purchase(package: package)
            isPurchasing = false
            updateSubscriptionInfo(from: result.customerInfo)
            return isProUser
        } catch {
            isPurchasing = false
            // Ignore user cancellation
            if let purchasesError = error as? RevenueCat.ErrorCode,
               purchasesError == .purchaseCancelledError {
                return false
            }
            errorMessage = error.localizedDescription
        }

        return false
    }

    @MainActor
    func restorePurchases() async -> Bool {
        isPurchasing = true
        errorMessage = nil

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            isPurchasing = false
            updateSubscriptionInfo(from: customerInfo)
            
            if !isProUser {
                errorMessage = "No active subscription found"
            }
            return isProUser
        } catch {
            isPurchasing = false
            errorMessage = error.localizedDescription
        }

        return false
    }

    // Login user to RevenueCat (call after Supabase auth)
    func login(userId: String) async {
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            await MainActor.run {
                self.updateSubscriptionInfo(from: customerInfo)
            }
        } catch {
            print("RevenueCat login error: \(error)")
        }
    }

    func logout() async {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            await MainActor.run {
                self.updateSubscriptionInfo(from: customerInfo)
            }
        } catch {
            print("RevenueCat logout error: \(error)")
        }
    }
}

// MARK: - PurchasesDelegate
extension SubscriptionManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.updateSubscriptionInfo(from: customerInfo)
        }
    }
}
