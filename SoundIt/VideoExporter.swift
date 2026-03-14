import AVFoundation
import UIKit

enum VideoFormat: String, CaseIterable, Identifiable {
    case reels = "Reels / Stories"
    case feed = "Feed"

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .reels: CGSize(width: 1080, height: 1920)
        case .feed: CGSize(width: 1920, height: 1080)
        }
    }
}

enum VideoExportError: LocalizedError {
    case noAudioTrack
    case writerFailed(String)
    case pixelBufferFailed

    var errorDescription: String? {
        switch self {
        case .noAudioTrack: "No audio track found"
        case .writerFailed(let msg): "Export failed: \(msg)"
        case .pixelBufferFailed: "Failed to create video frame"
        }
    }
}

final class VideoExporter: Sendable {

    static func export(
        image: UIImage,
        audioData: Data,
        format: VideoFormat
    ) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        // Write audio to temp file so AVAsset can read it
        let tempAudioURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        try audioData.write(to: tempAudioURL)
        defer { try? FileManager.default.removeItem(at: tempAudioURL) }

        let audioAsset = AVURLAsset(url: tempAudioURL)
        let duration = try await audioAsset.load(.duration)
        let audioTracks = try await audioAsset.loadTracks(withMediaType: .audio)
        guard let audioTrack = audioTracks.first else {
            throw VideoExportError.noAudioTrack
        }

        let videoSize = format.size

        // Set up writer
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        // Video input
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(videoSize.width),
            AVVideoHeightKey: Int(videoSize.height),
        ]
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: Int(videoSize.width),
                kCVPixelBufferHeightKey as String: Int(videoSize.height),
            ]
        )
        videoInput.expectsMediaDataInRealTime = false
        writer.add(videoInput)

        // Audio input
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128_000,
        ]
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput.expectsMediaDataInRealTime = false
        writer.add(audioInput)

        // Create the pixel buffer once (static image)
        guard let pixelBuffer = createPixelBuffer(from: image, size: videoSize) else {
            throw VideoExportError.pixelBufferFailed
        }

        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        // Write video frames (1 per second + final frame)
        let totalSeconds = Int(ceil(CMTimeGetSeconds(duration)))
        for second in 0...totalSeconds {
            let time = CMTime(seconds: Double(second), preferredTimescale: 600)
            while !videoInput.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(10))
            }
            adaptor.append(pixelBuffer, withPresentationTime: time)
        }
        videoInput.markAsFinished()

        // Copy audio samples
        let reader = try AVAssetReader(asset: audioAsset)
        let readerOutput = AVAssetReaderTrackOutput(
            track: audioTrack,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false,
            ]
        )
        reader.add(readerOutput)
        reader.startReading()

        while reader.status == .reading {
            if audioInput.isReadyForMoreMediaData {
                if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                    audioInput.append(sampleBuffer)
                } else {
                    break
                }
            } else {
                try await Task.sleep(for: .milliseconds(10))
            }
        }
        audioInput.markAsFinished()

        await writer.finishWriting()

        if writer.status == .failed {
            throw VideoExportError.writerFailed(writer.error?.localizedDescription ?? "Unknown")
        }

        return outputURL
    }

    // MARK: - Pixel Buffer

    private static func createPixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width), Int(size.height),
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        // Fill black
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // Draw image aspect-fit centered
        guard let cgImage = image.cgImage else { return nil }
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scale = min(size.width / imageSize.width, size.height / imageSize.height)
        let drawWidth = imageSize.width * scale
        let drawHeight = imageSize.height * scale
        let drawRect = CGRect(
            x: (size.width - drawWidth) / 2,
            y: (size.height - drawHeight) / 2,
            width: drawWidth,
            height: drawHeight
        )
        context.draw(cgImage, in: drawRect)

        return buffer
    }
}
