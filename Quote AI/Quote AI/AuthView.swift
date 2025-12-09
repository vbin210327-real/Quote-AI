//
//  AuthView.swift
//  Quote AI
//
//  Authentication screen with Google Sign-In
//

import SwiftUI
import GoogleSignInSwift

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
            
            // Google Sign-In Button
            VStack(spacing: 16) {
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
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
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
                errorMessage = "Sign-in failed: \(error.localizedDescription)"
                isSigningIn = false
            }
        }
    }
}

#Preview {
    AuthView()
}
