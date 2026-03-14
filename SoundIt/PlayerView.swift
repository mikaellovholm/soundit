import SwiftUI
import AVKit
import Photos

struct PlayerView: View {
    let entry: ImageEntry
    @State private var player: AVPlayer?
    @State private var showShareSheet = false
    @State private var savedToPhotos = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: SoundItSpacing.md) {
                if let player {
                    VideoPlayer(player: player)
                        .clipShape(RoundedRectangle(cornerRadius: SoundItRadius.card))
                        .soundItCardShadow()
                } else {
                    VStack(spacing: SoundItSpacing.md) {
                        Image(systemName: "film")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(SoundItColors.leather)
                        Text("NO VIDEO")
                            .font(SoundItFont.headline())
                            .foregroundStyle(SoundItColors.smoke)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(SoundItFont.body())
                        .foregroundStyle(SoundItColors.coffyRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SoundItSpacing.md)
                }

                if savedToPhotos {
                    Label("Saved to Photos", systemImage: "checkmark.circle.fill")
                        .font(SoundItFont.caption())
                        .foregroundStyle(SoundItColors.success)
                }

                Spacer()

                VStack(spacing: SoundItSpacing.sm) {
                    Button {
                        saveToPhotos()
                    } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(SoundItPrimaryButtonStyle())

                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(SoundItSecondaryButtonStyle())
                }
                .padding(.horizontal, SoundItSpacing.md)
            }
            .padding(SoundItSpacing.md)
            .soundItBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = entry.videoFileURL {
                    ShareSheet(url: url)
                }
            }
        }
        .onAppear {
            if let url = entry.videoFileURL {
                player = AVPlayer(url: url)
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func saveToPhotos() {
        guard let url = entry.videoFileURL else { return }
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    savedToPhotos = true
                    errorMessage = nil
                } else {
                    errorMessage = error?.localizedDescription ?? "Failed to save"
                }
            }
        }
    }
}

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
