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
    @State private var showSignInSheet = false
    @State private var isSigningIn = false
    @State private var errorMessage: String?
    
    // Animation States
    @State private var startMotivateAnimation = false
    @State private var startSubtitleAnimation = false
    
    var body: some View {
        ZStack {
            // Background Image
            if let bgPath = Bundle.main.path(forResource: "welcome_background", ofType: "png"),
               let uiImage = UIImage(contentsOfFile: bgPath) {
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
            
            VStack(spacing: 0) {
                Spacer()
                
                // Mission Statement
                VStack(spacing: 0) {
                    // "Quote to motivate" with strikethrough on "motivate"
                    HStack(spacing: 0) {
                        TypewriterView(
                            text: "Quote to ",
                            font: .system(size: 36, weight: .bold),
                            textColor: Color(hex: "EAEAEA"),
                            isItalic: true,
                            speed: 0.1,
                            isActive: true, // First one starts immediately
                            onComplete: {
                                startMotivateAnimation = true
                            }
                        )
                        
                        TypewriterView(
                            text: "motivate",
                            font: .system(size: 36, weight: .bold),
                            textColor: Color.gray.opacity(0.6),
                            isItalic: true,
                            isStrikethrough: true,
                            strikeColor: Color.gray.opacity(0.8),
                            speed: 0.1,
                            isActive: startMotivateAnimation, // Waits for "Quote to "
                            onComplete: {
                                startSubtitleAnimation = true
                            }
                        )
                    }
                    .multilineTextAlignment(.center)
                    
                    TypewriterView(
                        text: "become the best\nversion of yourself",
                        font: .system(size: 36, weight: .bold),
                        textColor: Color(hex: "EAEAEA"),
                        isItalic: true,
                        speed: 0.05,
                        startDelay: 0.2, // Slight pause after "motivate"
                        isActive: startSubtitleAnimation // Waits for "motivate"
                    )
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                    .padding(.top, 4)
                }
                .padding(.bottom, 150) // Adjust spacing to match design
                
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
        }
        .sheet(isPresented: $showSignInSheet) {
            signInSheet
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
