import Foundation
import UIKit
import os

// MARK: - Protocol

protocol VideoServiceProtocol {
    func generateVideo(imageData: [Data], text: String, format: VideoFormat) async throws -> URL
    func listJobs() async throws -> [JobSummary]
}

extension VideoServiceProtocol {
    func listJobs() async throws -> [JobSummary] { [] }
}

// MARK: - Mock Service

struct MockVideoService: VideoServiceProtocol {
    func generateVideo(imageData: [Data], text: String, format: VideoFormat) async throws -> URL {
        try await Task.sleep(for: .seconds(2))
        let image = imageData.first.flatMap { UIImage(data: $0) } ?? UIImage()
        let audioData = generateSineWave()
        return try await VideoExporter.export(image: image, audioData: audioData, format: format)
    }

    private func generateSineWave() -> Data {
        let sampleRate: Double = 44100
        let duration: Double = 8.0
        let sampleCount = Int(sampleRate * duration)

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

        data.append(contentsOf: "RIFF".utf8)
        data.append(littleEndian: chunkSize)
        data.append(contentsOf: "WAVE".utf8)

        data.append(contentsOf: "fmt ".utf8)
        data.append(littleEndian: Int32(16))
        data.append(littleEndian: Int16(1))
        data.append(littleEndian: numChannels)
        data.append(littleEndian: Int32(sampleRate))
        data.append(littleEndian: byteRate)
        data.append(littleEndian: blockAlign)
        data.append(littleEndian: bitsPerSample)

        data.append(contentsOf: "data".utf8)
        data.append(littleEndian: dataSize)

        for sample in samples {
            data.append(littleEndian: sample)
        }

        return data
    }
}

// MARK: - API Service

struct APIVideoService: VideoServiceProtocol {
    let baseURL: URL
    let authManager: AuthManager
    private static let logger = Logger(subsystem: "se.lovholm.soundit.app", category: "API")

    func generateVideo(imageData: [Data], text: String, format: VideoFormat) async throws -> URL {
        let token = try await authManager.idToken()
        let jobID = try await createJob(imageData: imageData, text: text, format: format, token: token)
        let videoURLString = try await pollUntilComplete(jobID: jobID, token: token)
        guard let videoURL = URL(string: videoURLString) else {
            throw ServiceError.invalidResponse
        }
        return try await downloadVideo(from: videoURL)
    }

    func listJobs() async throws -> [JobSummary] {
        let token = try await authManager.idToken()
        var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/jobs"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw ServiceError.serverError
        }

        return try JSONDecoder().decode(JobListResponse.self, from: data).jobs
    }

    // MARK: - Private

    private func createJob(imageData: [Data], text: String, format: VideoFormat, token: String) async throws -> String {
        let boundary = UUID().uuidString
        var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/jobs"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body = Data()

        for (index, data) in imageData.enumerated() {
            body.appendMultipart("--\(boundary)\r\n")
            body.appendMultipart("Content-Disposition: form-data; name=\"images[]\"; filename=\"photo\(index).jpg\"\r\n")
            body.appendMultipart("Content-Type: image/jpeg\r\n\r\n")
            body.append(data)
            body.appendMultipart("\r\n")
        }

        body.appendMultipart("--\(boundary)\r\n")
        body.appendMultipart("Content-Disposition: form-data; name=\"text\"\r\n\r\n")
        body.appendMultipart(text)
        body.appendMultipart("\r\n")

        body.appendMultipart("--\(boundary)\r\n")
        body.appendMultipart("Content-Disposition: form-data; name=\"format\"\r\n\r\n")
        body.appendMultipart(format.apiValue)
        body.appendMultipart("\r\n")

        body.appendMultipart("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.serverError
        }

        if http.statusCode == 401 { throw ServiceError.unauthorized }
        guard 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            Self.logger.error("createJob failed: \(http.statusCode) — \(body)")
            throw ServiceError.serverError
        }

        return try JSONDecoder().decode(CreateJobResponse.self, from: data).jobID
    }

    private func pollUntilComplete(jobID: String, token: String) async throws -> String {
        var delay: Duration = .seconds(1)
        let maxDelay: Duration = .seconds(10)
        let timeout: Duration = .seconds(600)
        let start = ContinuousClock.now

        while true {
            try Task.checkCancellation()

            if ContinuousClock.now - start > timeout {
                throw ServiceError.jobTimeout
            }

            try await Task.sleep(for: delay)

            var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/jobs/\(jobID)"))
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                let body = String(data: data, encoding: .utf8) ?? "no body"
                Self.logger.error("pollJob failed: \((response as? HTTPURLResponse)?.statusCode ?? 0) — \(body)")
                throw ServiceError.serverError
            }

            let job = try JSONDecoder().decode(JobStatusResponse.self, from: data)
            Self.logger.info("pollJob \(jobID): \(job.status)")

            switch job.status {
            case "completed":
                guard let videoURL = job.videoURL else {
                    throw ServiceError.invalidResponse
                }
                return videoURL
            case "failed":
                Self.logger.error("job failed: \(job.error ?? "no error message")")
                throw ServiceError.jobFailed(job.error ?? "Unknown error")
            case "pending", "processing":
                delay = min(delay * 2, maxDelay)
            default:
                throw ServiceError.invalidResponse
            }
        }
    }

    private func downloadVideo(from url: URL) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: url)
        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        try data.write(to: localURL)
        return localURL
    }

    // MARK: - Response types

    private struct CreateJobResponse: Decodable {
        let jobID: String
        let status: String

        enum CodingKeys: String, CodingKey {
            case jobID = "job_id"
            case status
        }
    }

    private struct JobStatusResponse: Decodable {
        let jobID: String
        let status: String
        let videoURL: String?
        let error: String?

        enum CodingKeys: String, CodingKey {
            case jobID = "job_id"
            case status
            case videoURL = "video_url"
            case error
        }
    }

    private struct JobListResponse: Decodable {
        let jobs: [JobSummary]
    }
}

// MARK: - Errors

enum ServiceError: LocalizedError {
    case invalidImage
    case serverError
    case invalidResponse
    case unauthorized
    case jobFailed(String)
    case jobTimeout

    var errorDescription: String? {
        switch self {
        case .invalidImage: "Could not process image"
        case .serverError: "Server returned an error"
        case .invalidResponse: "Invalid response from server"
        case .unauthorized: "Authentication required"
        case .jobFailed(let message): "Generation failed: \(message)"
        case .jobTimeout: "Generation timed out"
        }
    }
}

// MARK: - API Configuration

enum APIConfig {
    static let baseURL = URL(string: "https://soundit-275672990515.europe-west1.run.app")!
}

// MARK: - Data helpers

private extension Data {
    mutating func appendMultipart(_ string: String) {
        append(Data(string.utf8))
    }

    mutating func append<T: FixedWidthInteger>(littleEndian value: T) {
        var v = value.littleEndian
        append(Data(bytes: &v, count: MemoryLayout<T>.size))
    }
}
