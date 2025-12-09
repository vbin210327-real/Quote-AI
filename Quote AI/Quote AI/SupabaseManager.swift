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

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    let client: SupabaseClient
    
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
    
    // Sign out
    func signOut() async throws {
        try await client.auth.signOut()
        GIDSignIn.sharedInstance.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
