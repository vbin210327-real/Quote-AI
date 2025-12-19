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
                // Apple Sign In Button (Apple requires this to be equally prominent or first)
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .disabled(isSigningIn)
                .onTapGesture {
                    handleAppleSignIn()
                }
                .allowsHitTesting(!isSigningIn)

                // Google Sign-In Button
                Button(action: {
                    handleGoogleSignIn()
                }) {
                    HStack {
                        if let logoPath = Bundle.main.path(forResource: "google_logo", ofType: "png"),
                           let uiImage = UIImage(contentsOfFile: logoPath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        } else {
                            GoogleLogoView(size: 24)
                        }

                        Text("Continue with Google")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
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
