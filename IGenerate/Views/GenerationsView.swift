import SwiftUI

struct GenerationsView: View {
    @EnvironmentObject var store: GenerationStore
    @State private var selected: Generation?

    private let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    var body: some View {
        NavigationStack {
            Group {
                if store.generations.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(store.generations) { generation in
                                thumbnail(generation)
                                    .onTapGesture { selected = generation }
                            }
                        }
                    }
                }
            }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("Generations")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selected) { generation in
                GenerationDetailView(generation: generation)
                    .environmentObject(store)
            }
        }
        .tint(Theme.ink)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.stack")
                .font(.system(size: 32))
                .foregroundColor(Theme.subtleText)
            Text("No generations yet")
                .font(.subheadline)
                .foregroundColor(Theme.subtleText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func thumbnail(_ generation: Generation) -> some View {
        GeometryReader { geo in
            Group {
                if let image = store.image(for: generation) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle().fill(Theme.line)
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct GenerationDetailView: View {
    @EnvironmentObject var store: GenerationStore
    @Environment(\.dismiss) private var dismiss
    let generation: Generation

    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let image = store.image(for: generation) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(generation.isEdit ? "EDIT" : "GENERATED")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.subtleText)
                        Text(generation.prompt)
                            .font(.body)
                            .foregroundColor(Theme.ink)
                        Text(generation.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(Theme.subtleText)
                    }
                    .padding(.horizontal, 16)

                    HStack(spacing: 12) {
                        if let image = store.image(for: generation) {
                            ShareLink(item: Image(uiImage: image), preview: SharePreview(generation.prompt, image: Image(uiImage: image))) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.ink))
                                .foregroundColor(Theme.ink)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .background(Theme.paper.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete this generation?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    store.delete(generation)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .tint(Theme.ink)
    }
}

#Preview {
    GenerationsView().environmentObject(GenerationStore())
}
