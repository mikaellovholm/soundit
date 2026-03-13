import Foundation
import UIKit

@Observable
@MainActor
final class SoundViewModel {
    var entries: [ImageEntry] = []

    private let service: SoundtrackServiceProtocol

    init(service: SoundtrackServiceProtocol = MockSoundtrackService()) {
        self.service = service
    }

    func addImage(_ image: UIImage) {
        let entry = ImageEntry(image: image)
        entries.insert(entry, at: 0)
        generateSoundtrack(for: entry)
    }

    func retry(_ entry: ImageEntry) {
        generateSoundtrack(for: entry)
    }

    func delete(_ entry: ImageEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    private func generateSoundtrack(for entry: ImageEntry) {
        entry.isLoading = true
        entry.errorMessage = nil

        Task {
            do {
                let result = try await service.generateSoundtrack(for: entry.image)
                entry.soundtrack = result
            } catch {
                entry.errorMessage = error.localizedDescription
            }
            entry.isLoading = false
        }
    }
}
