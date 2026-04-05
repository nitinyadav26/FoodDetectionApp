import Foundation
import FirebaseAuth

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isSignedIn = false
    @Published var currentUser: User?
    @Published var isLoading = true

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isSignedIn = user != nil
                self?.isLoading = false
            }
        }
    }

    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        await MainActor.run {
            self.currentUser = result.user
            self.isSignedIn = true
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isSignedIn = true
        }
    }

    func createAccount(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isSignedIn = true
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        self.currentUser = nil
        self.isSignedIn = false
    }

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.delete()
        await MainActor.run {
            self.currentUser = nil
            self.isSignedIn = false
        }
    }
}
