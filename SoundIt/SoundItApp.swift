import FirebaseCore
import SwiftUI

@main
struct SoundItApp: App {
    @State private var authManager: AuthManager
    @State private var viewModel: SoundViewModel

    init() {
        FirebaseApp.configure()
        SoundItAppearance.configure()
        let auth = AuthManager()
        _authManager = State(initialValue: auth)
        _viewModel = State(initialValue: SoundViewModel(
            service: APIVideoService(baseURL: APIConfig.baseURL, authManager: auth)
        ))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    ZStack {
                        SoundItGradients.posterFade.ignoresSafeArea()
                        VStack(spacing: SoundItSpacing.lg) {
                            SoundItLogo(size: 40)
                            ProgressView()
                                .tint(SoundItColors.mustardGold)
                                .controlSize(.large)
                        }
                    }
                } else {
                    ContentView(
                        viewModel: viewModel,
                        authManager: authManager
                    )
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
