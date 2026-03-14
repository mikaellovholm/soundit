import SwiftUI
import PhotosUI

struct ContentView: View {
    @State var viewModel: SoundViewModel
    var authManager: AuthManager?
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showSourcePicker = false
    @State private var showPhotoPicker = false
    @State private var activeSheet: SheetType?
    @State private var pendingCameraEntry: ImageEntry?

    enum SheetType: Identifiable {
        case compose(ImageEntry)
        case player(ImageEntry)
        case history

        var id: String {
            switch self {
            case .compose(let e): "compose-\(e.id)"
            case .player(let e): "player-\(e.id)"
            case .history: "history"
            }
        }
    }

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
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button { activeSheet = .history } label: {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                        if authManager != nil {
                            Divider()
                            Button(role: .destructive) {
                                try? authManager?.signOut()
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSourcePicker = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showSourcePicker) {
                Button("Photo Library") { showPhotoPicker = true }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Camera") { showCamera = true }
                }
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotos,
                maxSelectionCount: 20,
                matching: .images
            )
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    let entry = viewModel.addImages([image])
                    pendingCameraEntry = entry
                }
                .ignoresSafeArea()
            }
            .onChange(of: showCamera) { old, new in
                if old && !new, let entry = pendingCameraEntry {
                    pendingCameraEntry = nil
                    activeSheet = .compose(entry)
                }
            }
            .onChange(of: selectedPhotos) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    var images: [UIImage] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            images.append(image)
                        }
                    }
                    if !images.isEmpty {
                        let entry = viewModel.addImages(images)
                        activeSheet = .compose(entry)
                    }
                    selectedPhotos = []
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .compose(let entry):
                    ComposeView(entry: entry, viewModel: viewModel)
                case .player(let entry):
                    PlayerView(entry: entry)
                case .history:
                    HistoryView(viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Videos", systemImage: "film")
        } description: {
            Text("Tap + to add photos and generate a soundtrack video.")
        }
    }

    private var entryGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(viewModel.entries) { entry in
                    EntryCell(entry: entry)
                        .onTapGesture {
                            switch entry.status {
                            case .idle, .error:
                                activeSheet = .compose(entry)
                            case .ready:
                                activeSheet = .player(entry)
                            case .loading:
                                break
                            }
                        }
                        .contextMenu {
                            if entry.status == .error || entry.status == .idle {
                                Button("Edit") { activeSheet = .compose(entry) }
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
            ZStack(alignment: .topTrailing) {
                Image(uiImage: entry.thumbnail ?? UIImage())
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()

                if entry.images.count > 1 {
                    Text("\(entry.images.count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(6)
                }
            }

            HStack {
                switch entry.status {
                case .idle:
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                    Text("Tap to compose")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .loading:
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .ready:
                    Image(systemName: "film")
                        .foregroundStyle(Color.accentColor)
                    Text(entry.text)
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
