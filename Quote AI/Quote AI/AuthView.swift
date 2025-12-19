//
//  AuthView.swift
//  Quote AI
//
//  Authentication screen with Google Sign-In
//

import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct AuthView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @State private var isSigningIn = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 30) {
            // App Logo/Title
            VStack(spacing: 12) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Quote AI")                    .font(.system(size: 36, weight: .bold))
                
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 80)
            
            Spacer()
            
            // Sign-In Buttons
            VStack(spacing: 16) {
                // Apple Sign In Button (Custom button with localized text)
                Button(action: {
                    handleAppleSignIn()
                }) {
                    HStack(spacing: 12) {
                        Spacer(minLength: 0)
                        Image(systemName: "applelogo")
                            .font(.system(size: 20, weight: .semibold))

                        Text(localization.string(for: "signIn.continueWithApple"))
                            .font(.headline)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .disabled(isSigningIn)

                // Google Sign-In Button
                Button(action: {
                    handleGoogleSignIn()
                }) {
                    HStack(spacing: 12) {
                        Spacer(minLength: 0)
                        if let logoPath = Bundle.main.path(forResource: "google_logo", ofType: "png"),
                           let uiImage = UIImage(contentsOfFile: logoPath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        } else {
                            GoogleLogoView(size: 24)
                                .frame(width: 24, height: 24)
                        }

                        Text("Continue with Google")
                            .font(.headline)
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
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .disabled(isSigningIn)

                if isSigningIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Privacy note
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemBackground))
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
                isSigningIn = false
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

    private func handleAppleSignIn() {
        isSigningIn = true
        errorMessage = nil

        Task {
            do {
                try await supabaseManager.signInWithApple()
                isSigningIn = false
            } catch {
                // Ignore user cancellation error (code 1001)
                let nsError = error as NSError
                if nsError.code == 1001 || nsError.domain == ASAuthorizationError.errorDomain {
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
    AuthView()
}
