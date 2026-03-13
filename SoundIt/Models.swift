import Foundation
import UIKit

struct SoundtrackResult {
    let title: String
    let audioData: Data
}

@Observable
final class ImageEntry: Identifiable {
    let id = UUID()
    let image: UIImage
    let createdAt = Date()

    var isLoading = false
    var soundtrack: SoundtrackResult?
    var errorMessage: String?

    var status: Status {
        if isLoading { return .loading }
        if soundtrack != nil { return .ready }
        if errorMessage != nil { return .error }
        return .idle
    }

    enum Status {
        case idle, loading, ready, error
    }

    init(image: UIImage) {
        self.image = image
    }
}
