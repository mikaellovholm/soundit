import Foundation
import UIKit
import AVFoundation

// MARK: - Protocol

protocol SoundtrackServiceProtocol {
    func generateSoundtrack(for image: UIImage) async throws -> SoundtrackResult
}

// MARK: - Mock Service

struct MockSoundtrackService: SoundtrackServiceProtocol {
    func generateSoundtrack(for image: UIImage) async throws -> SoundtrackResult {
        try await Task.sleep(for: .seconds(2))

        let titles = [
            "Sunrise Over Mountains",
            "Electric Dreams",
            "Ocean Breeze",
            "Midnight Jazz",
            "Forest Whispers",
            "Neon Pulse",
            "Golden Hour",
            "Rainy Day Café",
        ]
        let title = titles.randomElement()!
        let audioData = generateSineWave()
        return SoundtrackResult(title: title, audioData: audioData)
    }

    private func generateSineWave() -> Data {
        let sampleRate: Double = 44100
        let duration: Double = 8.0
        let sampleCount = Int(sampleRate * duration)

        // Generate a simple melody using sine waves
        let notes: [(frequency: Double, start: Double, end: Double)] = [
            (392.00, 0.0, 1.0),   // G4
            (440.00, 1.0, 2.0),   // A4
            (493.88, 2.0, 3.0),   // B4
            (523.25, 3.0, 4.0),   // C5
            (493.88, 4.0, 5.0),   // B4
            (440.00, 5.0, 6.0),   // A4
            (392.00, 6.0, 7.0),   // G4
            (349.23, 7.0, 8.0),   // F4
        ]

        var samples = [Int16](repeating: 0, count: sampleCount)
        let amplitude: Double = 0.4 * Double(Int16.max)

        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            var value: Double = 0

            for note in notes where t >= note.start && t < note.end {
                let noteT = t - note.start
                let noteDuration = note.end - note.start
                // Envelope: fade in 0.05s, fade out last 0.1s
                let fadeIn = min(noteT / 0.05, 1.0)
                let fadeOut = min((noteDuration - noteT) / 0.1, 1.0)
                let envelope = fadeIn * fadeOut
                value += sin(2.0 * .pi * note.frequency * t) * envelope
            }

            samples[i] = Int16(clamping: Int(value * amplitude))
        }

        return buildWAV(samples: samples, sampleRate: Int(sampleRate))
    }

    private func buildWAV(samples: [Int16], sampleRate: Int) -> Data {
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate * Int(numChannels) * Int(bitsPerSample / 8))
        let blockAlign = Int16(numChannels * (bitsPerSample / 8))
        let dataSize = Int32(samples.count * Int(bitsPerSample / 8))
        let chunkSize = 36 + dataSize

        var data = Data()

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(littleEndian: chunkSize)
        data.append(contentsOf: "WAVE".utf8)

        // fmt subchunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(littleEndian: Int32(16))         // subchunk size
        data.append(littleEndian: Int16(1))          // PCM format
        data.append(littleEndian: numChannels)
        data.append(littleEndian: Int32(sampleRate))
        data.append(littleEndian: byteRate)
        data.append(littleEndian: blockAlign)
        data.append(littleEndian: bitsPerSample)

        // data subchunk
        data.append(contentsOf: "data".utf8)
        data.append(littleEndian: dataSize)

        for sample in samples {
            data.append(littleEndian: sample)
        }

        return data
    }
}

// MARK: - API Service (ready to plug in)

struct APISoundtrackService: SoundtrackServiceProtocol {
    let baseURL: URL

    init(baseURL: URL = URL(string: "https://api.example.com")!) {
        self.baseURL = baseURL
    }

    func generateSoundtrack(for image: UIImage) async throws -> SoundtrackResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ServiceError.invalidImage
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: baseURL.appendingPathComponent("soundtrack"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".utf8)
        body.append(contentsOf: "Content-Type: image/jpeg\r\n\r\n".utf8)
        body.append(imageData)
        body.append(contentsOf: "\r\n--\(boundary)--\r\n".utf8)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw ServiceError.serverError
        }

        let json = try JSONDecoder().decode(APIResponse.self, from: data)
        guard let audioData = Data(base64Encoded: json.audio) else {
            throw ServiceError.invalidResponse
        }

        return SoundtrackResult(title: json.title, audioData: audioData)
    }

    private struct APIResponse: Decodable {
        let title: String
        let audio: String  // base64-encoded audio
    }
}

enum ServiceError: LocalizedError {
    case invalidImage
    case serverError
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidImage: "Could not process image"
        case .serverError: "Server returned an error"
        case .invalidResponse: "Invalid response from server"
        }
    }
}

// MARK: - Data helpers

private extension Data {
    mutating func append<T: FixedWidthInteger>(littleEndian value: T) {
        var v = value.littleEndian
        append(Data(bytes: &v, count: MemoryLayout<T>.size))
    }
}
