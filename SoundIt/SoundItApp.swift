import FirebaseCore
import SwiftUI

@main
struct SoundItApp: App {
    @State private var authManager: AuthManager

    init() {
        FirebaseApp.configure()
        _authManager = State(initialValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isLoading {
                ProgressView()
            } else {
                ContentView(
                    viewModel: SoundViewModel(
                        service: APIVideoService(
                            baseURL: APIConfig.baseURL,
                            authManager: authManager
                        )
                    ),
                    authManager: authManager
                )
            }
        }
    }
}
