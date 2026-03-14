import Foundation
import ImageIO
import UIKit

@Observable
final class ImageEntry: Identifiable {
    let id = UUID()
    let thumbnails: [UIImage]
    let uploadData: [Data]
    let imageCount: Int
    let createdAt = Date()

    var text: String = ""
    var format: VideoFormat = .reels

    var isLoading = false
    var videoFileURL: URL?
    var errorMessage: String?

    var status: Status {
        if isLoading { return .loading }
        if videoFileURL != nil { return .ready }
        if errorMessage != nil { return .error }
        return .idle
    }

    enum Status {
        case idle, loading, ready, error
    }

    init(images: [UIImage]) {
        imageCount = images.count
        thumbnails = images.map { $0.downsampled(maxDimension: 400) }
        uploadData = images.map { $0.downsampled(maxDimension: 2048).jpegData(compressionQuality: 0.8) ?? Data() }
    }

    var thumbnail: UIImage? { thumbnails.first }
}

#if DEBUG
extension UIImage {
    static func solidColor(_ color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
}
#endif

// MARK: - Persisted Video

struct PersistedVideo: Identifiable, Codable {
    let id: UUID
    let text: String
    let format: String
    let videoFilename: String
    let thumbnailFilename: String
    let createdAt: Date
}

// MARK: - Image Downsampling

extension UIImage {
    func downsampled(maxDimension: CGFloat) -> UIImage {
        let maxPixel = max(size.width * scale, size.height * scale)
        guard maxPixel > maxDimension else { return self }

        guard let data = jpegData(compressionQuality: 1.0) else { return self }
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return self }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else { return self }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Job Summary (for history)

struct JobSummary: Identifiable, Decodable {
    let id: String
    let status: String
    let createdAt: String
    let videoURL: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case id = "job_id"
        case status
        case createdAt = "created_at"
        case videoURL = "video_url"
        case error
    }

    var isCompleted: Bool { status == "completed" }
    var isFailed: Bool { status == "failed" }
    var isProcessing: Bool { status == "processing" || status == "pending" }
}
