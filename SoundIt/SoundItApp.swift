import SwiftUI

@main
struct SoundItApp: App {
    @State private var viewModel = SoundViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
