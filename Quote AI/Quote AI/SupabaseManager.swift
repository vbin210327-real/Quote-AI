//
//  SupabaseManager.swift
//  Quote AI
//
//  Manages Supabase authentication
//

import Foundation
import Combine
import Supabase
import GoogleSignIn
import AuthenticationServices

// Apple Sign In Coordinator - Bridges delegate callbacks to async/await
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorization, Error>?
    private weak var presentingWindow: UIWindow?

    init(window: UIWindow?) {
        self.presentingWindow = window
        super.init()
    }

    func signIn() async throws -> ASAuthorization {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentingWindow ?? UIWindow()
    }
}

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    let client: SupabaseClient
    private var appleSignInCoordinator: AppleSignInCoordinator?

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        
        Task {
            await checkSession()
        }
    }
    
    // Check if user has an active session
    func checkSession() async {
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // Sign in with Google
    func signInWithGoogle(presentingViewController: UIViewController) async throws {
        // Initialize Google Sign-In with iOS Client ID only
        let config = GIDConfiguration(clientID: SupabaseConfig.googleIOSClientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start Google Sign-In flow
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        )
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get ID token"
            ])
        }
        
        // Get access token
        let accessToken = result.user.accessToken.tokenString
        
        // Sign in to Supabase with Google tokens
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
        
        self.currentUser = session.user
        self.isAuthenticated = true
    }

    // Sign in with Apple
    func signInWithApple() async throws {
        // Get the key window for presenting the Apple Sign In sheet
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            throw NSError(domain: "AppleSignIn", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Unable to find window for presentation"
            ])
        }

        // Create coordinator and keep strong reference during sign-in
        let coordinator = AppleSignInCoordinator(window: window)
        self.appleSignInCoordinator = coordinator

        defer {
            self.appleSignInCoordinator = nil
        }

        // Perform Apple Sign In
        let authorization = try await coordinator.signIn()

        // Extract credentials from authorization
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw NSError(domain: "AppleSignIn", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get Apple ID credentials"
            ])
        }

        // Sign in to Supabase with Apple token
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: identityToken
            )
        )

        self.currentUser = session.user
        self.isAuthenticated = true
    }

    // Sign out
    func signOut() async throws {
        try await client.auth.signOut()
        GIDSignIn.sharedInstance.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
