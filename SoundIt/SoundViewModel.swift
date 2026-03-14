import Foundation
import UIKit

@Observable
@MainActor
final class SoundViewModel {
    var entries: [ImageEntry] = []
    var jobs: [JobSummary] = []
    var savedVideos: [PersistedVideo] = []

    private let service: VideoServiceProtocol
    let videoStore = VideoStore()

    init(service: VideoServiceProtocol = MockVideoService()) {
        self.service = service
        savedVideos = videoStore.loadAll()
    }

    var visibleSavedVideos: [PersistedVideo] {
        let activeURLs = Set(entries.compactMap { $0.videoFileURL?.lastPathComponent })
        return savedVideos.filter { !activeURLs.contains($0.videoFilename) }
    }

    var hasContent: Bool {
        !entries.isEmpty || !visibleSavedVideos.isEmpty
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
                    imageData: entry.uploadData,
                    text: entry.text,
                    format: entry.format
                )
                entry.videoFileURL = url
                // Persist to Documents off the main thread
                let store = videoStore
                let text = entry.text
                let formatRaw = entry.format.rawValue
                let thumb = entry.thumbnails.first
                let originalTempURL = url
                let persisted = try? await Task.detached(priority: .utility) {
                    let result = try store.save(
                        videoAt: originalTempURL,
                        text: text,
                        format: formatRaw,
                        thumbnail: thumb
                    )
                    // Clean up temp file after successful persistence
                    try? FileManager.default.removeItem(at: originalTempURL)
                    return result
                }.value
                if let persisted {
                    entry.videoFileURL = videoStore.videoURL(for: persisted)
                    savedVideos.insert(persisted, at: 0)
                    if savedVideos.count > VideoStore.maxVideos {
                        savedVideos = Array(savedVideos.prefix(VideoStore.maxVideos))
                    }
                }
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

    func deleteSavedVideo(_ video: PersistedVideo) {
        let store = videoStore
        let id = video.id
        Task.detached { store.delete(id: id) }
        savedVideos.removeAll { $0.id == video.id }
    }

    func loadJobs() async {
        do {
            jobs = try await service.listJobs()
        } catch {
            // History load failure is non-critical
        }
    }
}
