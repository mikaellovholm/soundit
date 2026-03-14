import FirebaseAuth

@Observable
@MainActor
final class AuthManager {
    var user: FirebaseAuth.User?
    var isSignedIn: Bool { user != nil }
    var isLoading = true

    init() {
        self.user = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isLoading = false
            }
        }

        if user == nil {
            Task { await signInAnonymously() }
        } else {
            isLoading = false
        }
    }

    func signInAnonymously() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            self.user = result.user
        } catch {
            // Will retry on next launch
        }
        isLoading = false
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func idToken() async throws -> String {
        guard let user else { throw AuthError.notSignedIn }
        return try await user.getIDToken()
    }
}

enum AuthError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn: "Not signed in"
        }
    }
}
