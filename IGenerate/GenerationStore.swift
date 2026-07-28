import Foundation
import SwiftUI
import MLXKlein
import MLXToolKit

@MainActor
final class GenerationStore: ObservableObject {

    // MARK: Published state

    @Published private(set) var generations: [Generation] = []
    @Published var isModelLoaded = false
    @Published var isLoadingModel = false
    @Published var isGenerating = false
    @Published var progressMessage: String = ""
    @Published var errorMessage: String?

    // MARK: Model

    private var package: Klein4BT2IPackage?

    // MARK: Storage

    private let fileManager = FileManager.default

    private var generationsDirectory: URL {
        let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Generations", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var indexFileURL: URL {
        generationsDirectory.appendingPathComponent("index.json")
    }

    init() {
        loadIndex()
    }

    // MARK: - Model lifecycle

    /// Loads the Klein model into memory the first time it's needed.
    /// int4 quantization keeps the resident footprint around ~11 GB, fitting 16GB-class devices.
    func loadModelIfNeeded() async {
        guard package == nil else { return }
        isLoadingModel = true
        progressMessage = "Loading model…"
        defer { isLoadingModel = false }

        do {
            let pkg = Klein4BT2IPackage(configuration: .init(
                quant: .int4,
                snapshotPath: nil // nil -> auto-materialize weights from mlx-community on first run
            ))
            try await pkg.load()
            self.package = pkg
            self.isModelLoaded = true
        } catch {
            self.errorMessage = "Couldn't load the model: \(error.localizedDescription)"
        }
    }

    func unloadModel() async {
        await package?.unload()
        package = nil
        isModelLoaded = false
    }

    // MARK: - Generation

    /// Runs a text-to-image generation, or a multi-reference edit if `referenceImage` is provided.
    @discardableResult
    func generate(prompt: String,
                   referenceImage: PlatformImage?,
                   width: Int = 1024,
                   height: Int = 1024,
                   seed: Int = Int.random(in: 0..<Int(UInt32.max))) async -> Generation? {

        errorMessage = nil

        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Enter a prompt first."
            return nil
        }

        await loadModelIfNeeded()
        guard let package else { return nil }

        isGenerating = true
        progressMessage = referenceImage == nil ? "Generating…" : "Editing…"
        defer {
            isGenerating = false
            progressMessage = ""
        }

        do {
            let outputImage: PlatformImage
            let isEdit = referenceImage != nil

            if let referenceImage {
                let response = try await package.run(IEditRequest(
                    images: [referenceImage],
                    prompt: prompt,
                    width: width,
                    height: height,
                    seed: seed
                )) as! IEditResponse
                outputImage = response.image
            } else {
                let response = try await package.run(T2IRequest(
                    prompt: prompt,
                    width: width,
                    height: height,
                    seed: seed
                )) as! T2IResponse
                outputImage = response.image
            }

            let generation = try save(image: outputImage,
                                       prompt: prompt,
                                       isEdit: isEdit,
                                       seed: seed,
                                       width: width,
                                       height: height)
            generations.insert(generation, at: 0)
            saveIndex()
            return generation

        } catch {
            errorMessage = "Generation failed: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - Persistence

    private func save(image: PlatformImage,
                       prompt: String,
                       isEdit: Bool,
                       seed: Int,
                       width: Int,
                       height: Int) throws -> Generation {
        let fileName = "\(UUID().uuidString).png"
        let url = generationsDirectory.appendingPathComponent(fileName)
        guard let data = image.pngData else {
            throw StoreError.encodingFailed
        }
        try data.write(to: url)

        return Generation(prompt: prompt,
                           fileName: fileName,
                           isEdit: isEdit,
                           seed: seed,
                           width: width,
                           height: height)
    }

    func image(for generation: Generation) -> PlatformImage? {
        let url = generationsDirectory.appendingPathComponent(generation.fileName)
        return PlatformImage(contentsOfFile: url.path)
    }

    func delete(_ generation: Generation) {
        let url = generationsDirectory.appendingPathComponent(generation.fileName)
        try? fileManager.removeItem(at: url)
        generations.removeAll { $0.id == generation.id }
        saveIndex()
    }

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexFileURL),
              let saved = try? JSONDecoder().decode([Generation].self, from: data) else {
            return
        }
        generations = saved.sorted { $0.createdAt > $1.createdAt }
    }

    private func saveIndex() {
        guard let data = try? JSONEncoder().encode(generations) else { return }
        try? data.write(to: indexFileURL)
    }

    enum StoreError: LocalizedError {
        case encodingFailed
        var errorDescription: String? {
            "Couldn't encode the generated image."
        }
    }
}

// MARK: - Cross-platform image typealias

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
extension UIImage {
    var pngData_: Data? { self.pngData() }
    convenience init?(contentsOfFile path: String) {
        self.init(contentsOfFile: path, scale: 1)
    }
}
extension PlatformImage {
    var pngData: Data? { self.pngData_ }
}
#else
import AppKit
typealias PlatformImage = NSImage
extension NSImage {
    var pngData: Data? {
        guard let tiff = self.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
#endif
