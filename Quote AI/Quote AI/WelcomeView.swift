//
//  WelcomeView.swift
//  Quote AI
//
//  Welcome screen displayed before onboarding
//

import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct WelcomeView: View {
    var onGetStarted: () -> Void
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var userPreferences = UserPreferences.shared
    @StateObject private var localization = LocalizationManager.shared
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
        GeometryReader { proxy in
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
                        Text(localization.string(for: "welcome.mission"))
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
                            Text(localization.string(for: "welcome.getStarted"))
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
                            Text(localization.string(for: "welcome.alreadyHaveAccount"))
                                .font(.system(size: 15))
                                .foregroundColor(.black)

                            Button(action: {
                                showSignInSheet = true
                            }) {
                                Text(localization.string(for: "welcome.signIn"))
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
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .overlay(alignment: .topTrailing) {
            Menu {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Button {
                        localization.setLanguage(language)
                    } label: {
                        Label {
                            Text("\(language.displayName) \(language.flag)")
                        } icon: {
                            if localization.currentLanguage == language {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(localization.currentLanguage.flag)
                        .font(.system(size: 18))
                    Text(localization.currentLanguage.rawValue.uppercased())
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemGray4))
                .cornerRadius(25)
            }
            .padding(.trailing, 20)
            .padding(.top, 10)
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
            VStack(spacing: 16) {
                Spacer()

                // Apple Sign In Button (Custom button with localized text)
                Button(action: {
                    handleAppleSignIn()
                }) {
                    HStack(spacing: 12) {
                        Spacer(minLength: 0)
                        Image(systemName: "applelogo")
                            .font(.system(size: 24, weight: .semibold))
                            .frame(width: 24, height: 24)

                        Text(localization.string(for: "welcome.signInWithApple"))
                            .font(.system(size: 18, weight: .semibold))
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(isSigningIn)
                .padding(.horizontal, 32)

                // Google Sign In Button
                Button(action: {
                    handleGoogleSignIn()
                }) {
                    HStack(spacing: 12) {
                        Spacer(minLength: 0)
                        if let uiImage = Self.googleLogoUIImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        } else {
                            GoogleLogoView(size: 24)
                                .frame(width: 24, height: 24)
                        }

                        Text(localization.string(for: "welcome.signInWithGoogle"))
                            .font(.system(size: 18, weight: .semibold))
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
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
                    Text(localization.string(for: "welcome.termsPrefix"))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                    HStack(spacing: 4) {
                        Text(localization.string(for: "welcome.termsAndConditions"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black)

                        Text(localization.string(for: "welcome.and"))
                            .font(.system(size: 13))
                            .foregroundColor(.gray)

                        Text(localization.string(for: "welcome.privacyPolicy"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .navigationTitle(localization.string(for: "welcome.signIn"))
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
            errorMessage = localization.string(for: "welcome.unableToSignIn")
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
                
                errorMessage = "\(localization.string(for: "welcome.signInFailed")) \(error.localizedDescription)"
                isSigningIn = false
            }
        }
    }

    private func handleAppleSignIn() {
        isSigningIn = true
        errorMessage = nil

        Task {
            do {
                try await supabaseManager.signInWithApple()
                // On success, close sheet
                isSigningIn = false
                showSignInSheet = false
            } catch {
                // Ignore user cancellation error (code 1001)
                let nsError = error as NSError
                if nsError.code == 1001 || nsError.domain == ASAuthorizationError.errorDomain {
                    isSigningIn = false
                    return
                }

                errorMessage = "\(localization.string(for: "welcome.signInFailed")) \(error.localizedDescription)"
                isSigningIn = false
            }
        }
    }
}

#Preview {
    WelcomeView(onGetStarted: {})
}
