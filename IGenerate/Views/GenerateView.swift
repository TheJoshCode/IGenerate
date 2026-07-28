import SwiftUI
import PhotosUI

struct GenerateView: View {
    @EnvironmentObject var store: GenerationStore

    @State private var prompt: String = ""
    @State private var pickedItem: PhotosPickerItem?
    @State private var referenceImage: PlatformImage?
    @State private var resultImage: PlatformImage?
    @State private var showResult = false

    private var isEditMode: Bool { referenceImage != nil }
    private var isBusy: Bool { store.isGenerating || store.isLoadingModel }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    header

                    referencePicker

                    promptField

                    if let message = store.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundColor(Theme.ink)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.line))
                    }

                    generateButton

                    if let resultImage {
                        resultPreview(resultImage)
                    }
                }
                .padding(20)
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("IGenerate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.paper, for: .navigationBar)
        }
        .tint(Theme.ink)
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(isEditMode ? "Edit an image" : "Generate an image")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.ink)
            Text("Runs fully offline, on this device.")
                .font(.footnote)
                .foregroundColor(Theme.subtleText)
        }
    }

    private var referencePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REFERENCE IMAGE (OPTIONAL)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.subtleText)

            PhotosPicker(selection: $pickedItem, matching: .images) {
                if let referenceImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: referenceImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.line))

                        Button {
                            self.referenceImage = nil
                            self.pickedItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Theme.paper)
                                .background(Circle().fill(Theme.ink))
                        }
                        .padding(8)
                    }
                } else {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("Add a photo to edit instead of generating from scratch")
                            .font(.subheadline)
                    }
                    .foregroundColor(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.line))
                }
            }
            .onChange(of: pickedItem) { _, newItem in
                Task {
                    guard let newItem,
                          let data = try? await newItem.loadTransferable(type: Data.self),
                          let image = PlatformImage(data: data) else { return }
                    referenceImage = image
                }
            }
        }
    }

    private var promptField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROMPT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.subtleText)

            ZStack(alignment: .topLeading) {
                if prompt.isEmpty {
                    Text(isEditMode
                         ? "Describe how to change the photo…"
                         : "Describe the image you want…")
                        .foregroundColor(Theme.placeholder)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                }
                TextEditor(text: $prompt)
                    .frame(height: 110)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .foregroundColor(Theme.ink)
            }
            .monoField()
        }
    }

    private var generateButton: some View {
        Button {
            Task { await runGeneration() }
        } label: {
            if isBusy {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Theme.paper)
                    Text(store.progressMessage.isEmpty ? "Working…" : store.progressMessage)
                }
                .frame(maxWidth: .infinity)
            } else {
                Text(isEditMode ? "Edit Image" : "Generate")
            }
        }
        .buttonStyle(PrimaryButtonStyle(isDisabled: isBusy))
        .disabled(isBusy)
    }

    private func resultPreview(_ image: PlatformImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RESULT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.subtleText)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.line))

            Text("Saved to Generations")
                .font(.footnote)
                .foregroundColor(Theme.subtleText)
        }
    }

    // MARK: Actions

    private func runGeneration() async {
        let generation = await store.generate(prompt: prompt, referenceImage: referenceImage)
        if let generation {
            resultImage = store.image(for: generation)
        }
    }
}

#Preview {
    GenerateView().environmentObject(GenerationStore())
}
