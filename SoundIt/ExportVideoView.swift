import SwiftUI

struct ComposeView: View {
    let entry: ImageEntry
    let viewModel: SoundViewModel
    @State private var text: String = ""
    @State private var format: VideoFormat = .reels
    @FocusState private var textFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if entry.images.count == 1 {
                        Image(uiImage: entry.images[0])
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 8)
                            .padding(.top)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(entry.images.enumerated()), id: \.offset) { _, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 210)
                        .padding(.top)
                    }

                    TextField("Describe the vibe...", text: $text, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...5)
                        .padding(.horizontal)
                        .focused($textFieldFocused)
                        .submitLabel(.done)
                        .onSubmit { textFieldFocused = false }

                    Picker("Format", selection: $format) {
                        ForEach(VideoFormat.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    Text(dimensionLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        entry.text = text
                        entry.format = format
                        viewModel.generate(entry: entry)
                        dismiss()
                    } label: {
                        Text("Generate")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture { textFieldFocused = false }
            .navigationTitle("New Soundtrack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") { textFieldFocused = false }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            text = entry.text
            format = entry.format
        }
    }

    private var dimensionLabel: String {
        let size = format.size
        return "\(Int(size.width)) \u{00d7} \(Int(size.height))"
    }
}
