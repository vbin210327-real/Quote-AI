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
    @State private var showSplash = true
    @State private var showWelcome = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
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
                        if supabaseManager.isAuthenticated {
                            ChatView()
                        } else if showWelcome {
                            WelcomeView {
                                userPreferences.hasSeenWelcome = true
                                withAnimation {
                                    showWelcome = false
                                }
                            }
                        } else {
                            OnboardingView {
                                // Go back to Welcome
                                withAnimation {
                                    showWelcome = true
                                }
                            }
                        }
                    }
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
                }
            }
        }
    }
}
