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
                VStack(spacing: SoundItSpacing.lg) {
                    if entry.images.count == 1 {
                        Image(uiImage: entry.images[0])
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .clipShape(RoundedRectangle(cornerRadius: SoundItRadius.card))
                            .soundItCardShadow()
                            .padding(.top, SoundItSpacing.md)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: SoundItSpacing.xs) {
                                ForEach(Array(entry.images.enumerated()), id: \.offset) { _, image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: SoundItRadius.card))
                                }
                            }
                            .padding(.horizontal, SoundItSpacing.md)
                        }
                        .frame(height: 210)
                        .padding(.top, SoundItSpacing.md)
                    }

                    TextField("Describe the vibe...", text: $text, prompt: Text("Describe the vibe...").foregroundStyle(SoundItColors.smoke), axis: .vertical)
                        .font(SoundItFont.body())
                        .foregroundStyle(SoundItColors.cream)
                        .lineLimit(2...5)
                        .padding(SoundItSpacing.sm)
                        .background(SoundItColors.midnight)
                        .clipShape(RoundedRectangle(cornerRadius: SoundItRadius.button))
                        .overlay(RoundedRectangle(cornerRadius: SoundItRadius.button).stroke(SoundItColors.leather, lineWidth: 1))
                        .tint(SoundItColors.mustardGold)
                        .padding(.horizontal, SoundItSpacing.md)
                        .focused($textFieldFocused)
                        .submitLabel(.done)
                        .onSubmit { textFieldFocused = false }

                    Picker("Format", selection: $format) {
                        ForEach(VideoFormat.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, SoundItSpacing.md)

                    Text(dimensionLabel)
                        .font(SoundItFont.caption())
                        .foregroundStyle(SoundItColors.smoke)

                    Button {
                        entry.text = text
                        entry.format = format
                        viewModel.generate(entry: entry)
                        dismiss()
                    } label: {
                        Text("Generate")
                    }
                    .buttonStyle(SoundItPrimaryButtonStyle())
                    .padding(.horizontal, SoundItSpacing.md)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.vertical, SoundItSpacing.md)
            }
            .scrollDismissesKeyboard(.immediately)
            .contentShape(Rectangle())
            .onTapGesture { textFieldFocused = false }
            .soundItBackground()
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
