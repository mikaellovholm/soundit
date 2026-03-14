import Foundation
import UIKit

struct VideoStore: Sendable {
    static let maxVideos = 10

    static var videosDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Videos", isDirectory: true)
    }

    private static var manifestURL: URL {
        videosDirectory.appendingPathComponent("videos.json")
    }

    private func ensureDirectory() throws {
        try FileManager.default.createDirectory(
            at: Self.videosDirectory,
            withIntermediateDirectories: true
        )
    }

    func loadAll() -> [PersistedVideo] {
        guard let data = try? Data(contentsOf: Self.manifestURL),
              let videos = try? JSONDecoder().decode([PersistedVideo].self, from: data) else {
            return []
        }
        return videos.sorted { $0.createdAt > $1.createdAt }
    }

    func save(videoAt sourceURL: URL, text: String, format: String, thumbnail: UIImage?) throws -> PersistedVideo {
        try ensureDirectory()

        let id = UUID()
        let videoFilename = "\(id.uuidString).mp4"
        let thumbFilename = "\(id.uuidString)_thumb.jpg"

        let destVideo = Self.videosDirectory.appendingPathComponent(videoFilename)
        try FileManager.default.copyItem(at: sourceURL, to: destVideo)

        if let data = thumbnail?.jpegData(compressionQuality: 0.7) {
            let destThumb = Self.videosDirectory.appendingPathComponent(thumbFilename)
            try data.write(to: destThumb)
        }

        let video = PersistedVideo(
            id: id,
            text: text,
            format: format,
            videoFilename: videoFilename,
            thumbnailFilename: thumbFilename,
            createdAt: Date()
        )

        var all = loadAll()
        all.insert(video, at: 0)

        // Enforce limit — delete oldest
        while all.count > Self.maxVideos {
            let removed = all.removeLast()
            deleteFiles(for: removed)
        }

        try writeManifest(all)
        return video
    }

    func delete(id: UUID) {
        var all = loadAll()
        if let index = all.firstIndex(where: { $0.id == id }) {
            let removed = all.remove(at: index)
            deleteFiles(for: removed)
            try? writeManifest(all)
        }
    }

    func videoURL(for video: PersistedVideo) -> URL {
        Self.videosDirectory.appendingPathComponent(video.videoFilename)
    }

    // MARK: - Private

    private func writeManifest(_ videos: [PersistedVideo]) throws {
        let data = try JSONEncoder().encode(videos)
        try data.write(to: Self.manifestURL, options: .atomic)
    }

    private func deleteFiles(for video: PersistedVideo) {
        let fm = FileManager.default
        try? fm.removeItem(at: Self.videosDirectory.appendingPathComponent(video.videoFilename))
        try? fm.removeItem(at: Self.videosDirectory.appendingPathComponent(video.thumbnailFilename))
    }

}
