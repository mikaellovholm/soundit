import Foundation
import UIKit

@Observable
@MainActor
final class SoundViewModel {
    var entries: [ImageEntry] = []
    var jobs: [JobSummary] = []

    private let service: VideoServiceProtocol

    init(service: VideoServiceProtocol = MockVideoService()) {
        self.service = service
    }

    #if DEBUG
    static func preview() -> SoundViewModel {
        let vm = SoundViewModel()
        let colors: [(UIColor, String)] = [
            (.systemOrange, "Sunset vibes"),
            (.systemTeal, "Ocean chill"),
            (.systemPurple, "Night drive"),
            (.systemPink, "Dance floor"),
        ]
        for (i, (color, text)) in colors.enumerated() {
            let img = UIImage.solidColor(color, size: CGSize(width: 400, height: 600))
            let entry = ImageEntry(images: [img])
            entry.text = text
            if i == 0 { entry.isLoading = true }
            if i == 1 { entry.videoFileURL = URL(string: "file:///tmp/mock.mp4") }
            if i == 3 { entry.errorMessage = "Timed out" }
            vm.entries.append(entry)
        }
        return vm
    }
    #endif

    @discardableResult
    func addImages(_ images: [UIImage]) -> ImageEntry {
        let entry = ImageEntry(images: images)
        entries.insert(entry, at: 0)
        return entry
    }

    func generate(entry: ImageEntry) {
        entry.isLoading = true
        entry.errorMessage = nil
        entry.videoFileURL = nil

        Task {
            do {
                let url = try await service.generateVideo(
                    images: entry.images,
                    text: entry.text,
                    format: entry.format
                )
                entry.videoFileURL = url
            } catch {
                entry.errorMessage = error.localizedDescription
            }
            entry.isLoading = false
        }
    }

    func delete(_ entry: ImageEntry) {
        if let url = entry.videoFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        entries.removeAll { $0.id == entry.id }
    }

    func loadJobs() async {
        do {
            jobs = try await service.listJobs()
        } catch {
            // History load failure is non-critical
        }
    }
}
