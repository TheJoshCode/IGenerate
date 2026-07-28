import Foundation

/// A single saved generation (text-to-image or image-edit result).
struct Generation: Identifiable, Codable, Equatable {
    let id: UUID
    let prompt: String
    let fileName: String
    let createdAt: Date
    let isEdit: Bool
    let seed: Int
    let width: Int
    let height: Int

    init(id: UUID = UUID(),
         prompt: String,
         fileName: String,
         createdAt: Date = Date(),
         isEdit: Bool,
         seed: Int,
         width: Int,
         height: Int) {
        self.id = id
        self.prompt = prompt
        self.fileName = fileName
        self.createdAt = createdAt
        self.isEdit = isEdit
        self.seed = seed
        self.width = width
        self.height = height
    }
}
