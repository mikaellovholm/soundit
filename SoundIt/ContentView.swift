import SwiftUI
import PhotosUI

struct ContentView: View {
    @State var viewModel: SoundViewModel
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showSourcePicker = false
    @State private var selectedEntry: ImageEntry?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.entries.isEmpty {
                    emptyState
                } else {
                    entryGrid
                }
            }
            .navigationTitle("SoundIt")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSourcePicker = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showSourcePicker) {
                PhotosPicker("Photo Library", selection: $selectedPhoto, matching: .images)
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Camera") { showCamera = true }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    viewModel.addImage(image)
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.addImage(image)
                    }
                    selectedPhoto = nil
                }
            }
            .sheet(item: $selectedEntry) { entry in
                PlayerView(entry: entry)
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Soundtracks", systemImage: "music.note")
        } description: {
            Text("Tap + to add a photo and generate a soundtrack.")
        }
    }

    private var entryGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(viewModel.entries) { entry in
                    EntryCell(entry: entry)
                        .onTapGesture {
                            if entry.status == .ready {
                                selectedEntry = entry
                            }
                        }
                        .contextMenu {
                            if entry.status == .error {
                                Button("Retry") { viewModel.retry(entry) }
                            }
                            Button("Delete", role: .destructive) { viewModel.delete(entry) }
                        }
                }
            }
            .padding()
        }
    }
}

// MARK: - Entry Cell

private struct EntryCell: View {
    let entry: ImageEntry

    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: entry.image)
                .resizable()
                .scaledToFill()
                .frame(height: 150)
                .clipped()

            HStack {
                switch entry.status {
                case .idle:
                    Text("Waiting...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .loading:
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .ready:
                    Image(systemName: "music.note")
                        .foregroundStyle(Color.accentColor)
                    Text(entry.soundtrack?.title ?? "")
                        .font(.caption)
                        .lineLimit(1)
                case .error:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Failed")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
