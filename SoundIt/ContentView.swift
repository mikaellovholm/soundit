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
        case player(URL)
        case history

        var id: String {
            switch self {
            case .compose(let e): "compose-\(e.id)"
            case .player(let url): "player-\(url.absoluteString)"
            case .history: "history"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.hasContent {
                    entryGrid
                } else {
                    emptyState
                }
            }
            .soundItBackground()
            .navigationTitle("SoundIt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(SoundItColors.midnight, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SoundItLogo(size: 20)
                }
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
                            .fontWeight(.bold)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSourcePicker = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
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
                        .presentationBackground(SoundItColors.cocoa)
                case .player(let url):
                    PlayerView(videoURL: url)
                        .presentationBackground(SoundItColors.cocoa)
                case .history:
                    HistoryView(viewModel: viewModel)
                        .presentationBackground(SoundItColors.cocoa)
                }
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: SoundItSpacing.md) {
            Image(systemName: "film")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(SoundItColors.leather)
            Text("NO VIDEOS")
                .font(SoundItFont.headline())
                .foregroundStyle(SoundItColors.smoke)
            Text("Tap + to add photos and generate a soundtrack video.")
                .font(SoundItFont.body())
                .foregroundStyle(SoundItColors.smoke)
                .multilineTextAlignment(.center)
        }
        .padding(SoundItSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var entryGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: SoundItSpacing.sm)], spacing: SoundItSpacing.sm) {
                ForEach(viewModel.entries) { entry in
                    EntryCell(entry: entry)
                        .onTapGesture {
                            switch entry.status {
                            case .idle, .error:
                                activeSheet = .compose(entry)
                            case .ready:
                                if let url = entry.videoFileURL {
                                    activeSheet = .player(url)
                                }
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
                ForEach(viewModel.visibleSavedVideos) { video in
                    SavedVideoCell(video: video, videoStore: viewModel.videoStore)
                        .onTapGesture {
                            activeSheet = .player(viewModel.videoStore.videoURL(for: video))
                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                viewModel.deleteSavedVideo(video)
                            }
                        }
                }
            }
            .padding(SoundItSpacing.md)
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
                        .font(SoundItFont.caption(11))
                        .fontWeight(.bold)
                        .foregroundStyle(SoundItColors.cream)
                        .padding(.horizontal, SoundItSpacing.xs)
                        .padding(.vertical, SoundItSpacing.xxs)
                        .background(SoundItColors.midnight.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: SoundItRadius.badge))
                        .padding(SoundItSpacing.xs)
                }
            }

            HStack {
                switch entry.status {
                case .idle:
                    Image(systemName: "pencil")
                        .foregroundStyle(SoundItColors.smoke)
                    Text("Tap to compose")
                        .font(SoundItFont.caption())
                        .foregroundStyle(SoundItColors.smoke)
                case .loading:
                    ProgressView()
                        .controlSize(.small)
                        .tint(SoundItColors.mustardGold)
                    Text("Generating...")
                        .font(SoundItFont.caption())
                        .foregroundStyle(SoundItColors.mustardGold)
                case .ready:
                    Image(systemName: "film")
                        .foregroundStyle(SoundItColors.mustardGold)
                    Text(entry.text)
                        .font(SoundItFont.caption())
                        .foregroundStyle(SoundItColors.cream)
                        .lineLimit(1)
                case .error:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(SoundItColors.coffyRed)
                    Text("Failed")
                        .font(SoundItFont.caption())
                        .foregroundStyle(SoundItColors.coffyRed)
                }
                Spacer()
            }
            .padding(.horizontal, SoundItSpacing.xs)
            .padding(.vertical, SoundItSpacing.xs)
        }
        .soundItCard()
        .soundItCardShadow()
    }
}

// MARK: - Saved Video Cell

private struct SavedVideoCell: View {
    let video: PersistedVideo
    let videoStore: VideoStore
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()
            } else {
                Rectangle()
                    .fill(SoundItColors.midnight)
                    .frame(height: 150)
                    .overlay {
                        Image(systemName: "film")
                            .font(.title)
                            .foregroundStyle(SoundItColors.leather)
                    }
            }

            HStack {
                Image(systemName: "film")
                    .foregroundStyle(SoundItColors.mustardGold)
                Text(video.text)
                    .font(SoundItFont.caption())
                    .foregroundStyle(SoundItColors.cream)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, SoundItSpacing.xs)
            .padding(.vertical, SoundItSpacing.xs)
        }
        .soundItCard()
        .soundItCardShadow()
        .task {
            let thumbURL = VideoStore.videosDirectory
                .appendingPathComponent(video.thumbnailFilename)
            if let data = try? Data(contentsOf: thumbURL) {
                thumbnail = UIImage(data: data)
            }
        }
    }
}
