import Foundation
import UIKit

@Observable
final class ImageEntry: Identifiable {
    let id = UUID()
    let images: [UIImage]
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
        self.images = images
    }

    var thumbnail: UIImage? { images.first }
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
