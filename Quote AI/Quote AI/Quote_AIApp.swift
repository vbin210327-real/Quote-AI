//
//  Quote_AIApp.swift
//  Quote AI
//
//  Created by 林凡滨 on 2025/11/26.
//

import SwiftUI
import GoogleSignIn

@main
struct Quote_AIApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var userPreferences = UserPreferences.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true
    @State private var showWelcome = false

    init() {
        // Configure RevenueCat
        SubscriptionManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if showSplash {
                        SplashScreenView()
                            .onAppear {
                                // Hide splash after 2.5 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    withAnimation {
                                        showSplash = false
                                        // Show welcome if user hasn't seen it yet
                                        if !userPreferences.hasSeenWelcome {
                                            showWelcome = true
                                        }
                                    }
                                }
                            }
                    } else {
                        Group {
                            // Only show ChatView if BOTH authenticated AND onboarding complete
                            if supabaseManager.isAuthenticated && userPreferences.hasCompletedOnboarding {
                                ChatView()
                            } else if showWelcome {
                                WelcomeView {
                                    userPreferences.hasSeenWelcome = true
                                    withAnimation {
                                        showWelcome = false
                                    }
                                }
                                .preferredColorScheme(.light)
                            } else {
                                OnboardingView {
                                    // Go back to Welcome
                                    withAnimation {
                                        showWelcome = true
                                    }
                                }
                                .preferredColorScheme(.light)
                            }
                        }
                        .onOpenURL { url in
                            GIDSignIn.sharedInstance.handle(url)
                        }
                    }
                }

                // Daily Quote Overlay - Appears over everything when triggered by notification
                if !showSplash, notificationManager.showDailyQuoteOverlay, let quote = notificationManager.selectedDailyQuote {
                    DailyQuoteOverlay(
                        initialQuote: quote,
                        isPresented: $notificationManager.showDailyQuoteOverlay
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(999) // Ensure it's on top of everything
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    // Flush any pending cloud syncs before app goes to background
                    Task {
                        await userPreferences.flushPendingSync()
                    }
                }
            }
        }
    }
}
