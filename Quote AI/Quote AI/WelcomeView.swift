//
//  WelcomeView.swift
//  Quote AI
//
//  Welcome screen displayed before onboarding
//

import SwiftUI
import GoogleSignInSwift

struct WelcomeView: View {
    var onGetStarted: () -> Void
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var userPreferences = UserPreferences.shared
    @State private var showSignInSheet = false
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    private static let backgroundUIImage: UIImage? = UIImage(named: "welcome_background")
    private static let googleLogoUIImage: UIImage? = UIImage(named: "google_logo")
    
    // Animation States
    @State private var didConfigureAppearance = false
    @State private var shouldPlayIntroAnimation = !UserDefaults.standard.bool(forKey: "hasPlayedWelcomeIntro")
    @State private var showMissionStatement = UserDefaults.standard.bool(forKey: "hasPlayedWelcomeIntro")
    @State private var showRestOfContent = UserDefaults.standard.bool(forKey: "hasPlayedWelcomeIntro")
    
    var body: some View {
        ZStack {
            // Background Image
            Group {
                if let uiImage = Self.backgroundUIImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                } else {
                    // Fallback gradient if image fails
                    LinearGradient(
                        colors: [Color.black, Color.blue.opacity(0.5), Color.white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            }
            // Prevent background from participating in text animations (avoids flicker/flash).
            .transaction { transaction in
                transaction.animation = nil
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Mission Statement
                VStack(spacing: 0) {
                    Text("Wisdom customized\nfor your journey")
                        .font(.system(size: 36, weight: .bold))
                        .italic()
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.bottom, 20) // Keep original position (reserve space for bottom content)
                .opacity(showMissionStatement ? 1 : 0)
                .animation(shouldPlayIntroAnimation ? .easeOut(duration: 0.35) : nil, value: showMissionStatement)

                VStack(spacing: 0) {
                    // Get Started Button
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        onGetStarted()
                    }) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .italic()
                            .foregroundColor(.white)
                            .frame(width: UIScreen.main.bounds.width - 40)
                            .frame(height: 60)
                            .background(Color.black)
                            .cornerRadius(30)
                    }
                    
                    // Already have an account text
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 15))
                            .foregroundColor(.black)
                        
                        Button(action: {
                            showSignInSheet = true
                        }) {
                            Text("Sign In")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
                // Keep space reserved from the start to avoid mission statement jumping position.
                .opacity(showRestOfContent ? 1 : 0)
                .offset(y: showRestOfContent ? 0 : 18)
                .blur(radius: showRestOfContent ? 0 : 6)
                .animation(shouldPlayIntroAnimation ? .easeOut(duration: 0.6).delay(0.05) : nil, value: showRestOfContent)
                .allowsHitTesting(showRestOfContent)
                .accessibilityHidden(!showRestOfContent)
            }
        }
        .sheet(isPresented: $showSignInSheet) {
            signInSheet
        }
        .onAppear {
            guard !didConfigureAppearance else { return }
            didConfigureAppearance = true
            
            if shouldPlayIntroAnimation {
                userPreferences.hasPlayedWelcomeIntro = true
                
                // 1. Text fades in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.35)) {
                        showMissionStatement = true
                    }
                }
                
                // 2. Buttons fade in shortly after
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                     withAnimation(.easeOut(duration: 0.6)) {
                         showRestOfContent = true
                     }
                }
            }
        }
    }
    
    // Sign In Sheet
    var signInSheet: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Google Sign In Button
                Button(action: {
                    handleGoogleSignIn()
                }) {
                    HStack {
                        if let uiImage = Self.googleLogoUIImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        } else {
                            GoogleLogoView(size: 24)
                        }
                        
                        Text("Sign in with Google")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(isSigningIn)
                .padding(.horizontal, 32)
                
                if isSigningIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Terms and Privacy Policy
                VStack(spacing: 4) {
                    Text("By continuing you agree to Quote AI's")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Text("Terms and Conditions")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black)
                        
                        Text("and")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        
                        Text("Privacy Policy")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSignInSheet = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private func handleGoogleSignIn() {
        isSigningIn = true
        errorMessage = nil
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to present sign-in"
            isSigningIn = false
            return
        }
        
        Task {
            do {
                try await supabaseManager.signInWithGoogle(presentingViewController: rootViewController)
                // On success, close sheet
                isSigningIn = false
                showSignInSheet = false
            } catch {
                // Ignore user cancellation error (code -5)
                let nsError = error as NSError
                if nsError.code == -5 {
                    isSigningIn = false
                    return
                }
                
                errorMessage = "Sign-in failed: \(error.localizedDescription)"
                isSigningIn = false
            }
        }
    }
}

#Preview {
    WelcomeView(onGetStarted: {})
}
