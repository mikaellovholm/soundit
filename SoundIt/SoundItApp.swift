import FirebaseCore
import SwiftUI

@main
struct SoundItApp: App {
    @State private var authManager: AuthManager

    init() {
        FirebaseApp.configure()
        SoundItAppearance.configure()
        _authManager = State(initialValue: AuthManager())
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
            .preferredColorScheme(.dark)
        }
    }
}
