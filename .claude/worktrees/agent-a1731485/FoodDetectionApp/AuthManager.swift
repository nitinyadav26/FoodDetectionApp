import Foundation
import FirebaseAuth
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isSignedIn = false
    @Published var currentUser: User?
    @Published var isLoading = true
    @Published var errorMessage: String?

    private var firebaseAvailable: Bool
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        // Check if Firebase is configured before accessing Auth
        let hasFirebase = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        self.firebaseAvailable = hasFirebase

        if hasFirebase {
            authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                DispatchQueue.main.async {
                    self?.currentUser = user
                    self?.isSignedIn = user != nil
                    self?.isLoading = false
                }
            }
        } else {
            // No Firebase — treat as signed in so user can use the app
            self.isSignedIn = true
            self.isLoading = false
            print("[FoodSense] Firebase Auth unavailable — running without authentication")
        }
    }

    func signInAnonymously() async throws {
        guard firebaseAvailable else {
            await MainActor.run {
                self.isSignedIn = true
                self.isLoading = false
            }
            return
        }
        do {
            let result = try await Auth.auth().signInAnonymously()
            await MainActor.run {
                self.currentUser = result.user
                self.isSignedIn = true
                self.errorMessage = nil
            }
        } catch {
            print("[FoodSense] Anonymous sign-in failed: \(error.localizedDescription)")
            // Let user through anyway
            await MainActor.run {
                self.isSignedIn = true
                self.isLoading = false
                self.errorMessage = nil
            }
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        guard firebaseAvailable else {
            await MainActor.run {
                self.errorMessage = "Authentication unavailable. Set up Firebase to enable sign-in."
            }
            return
        }
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isSignedIn = true
        }
    }

    func createAccount(email: String, password: String) async throws {
        guard firebaseAvailable else {
            await MainActor.run {
                self.errorMessage = "Authentication unavailable. Set up Firebase to enable accounts."
            }
            return
        }
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isSignedIn = true
        }
    }

    func signOut() throws {
        if firebaseAvailable {
            try Auth.auth().signOut()
        }
        self.currentUser = nil
        self.isSignedIn = false
    }

    func deleteAccount() async throws {
        guard firebaseAvailable, let user = Auth.auth().currentUser else { return }
        try await user.delete()
        await MainActor.run {
            self.currentUser = nil
            self.isSignedIn = false
        }
    }
}
