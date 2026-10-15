import Foundation

struct Profile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var bindings: [KeyBinding] = []
    var isActive = false
    var createdAt = Date()
    var updatedAt = Date()

    func binding(for key: NumpadKey) -> KeyBinding? {
        bindings.first { $0.key == key }
    }

    func withBinding(_ binding: KeyBinding) -> Profile {
        var copy = self
        if let i = copy.bindings.firstIndex(where: { $0.key == binding.key }) {
            copy.bindings[i] = binding
        } else {
            copy.bindings.append(binding)
        }
        copy.updatedAt = Date()
        return copy
    }

    func withoutBinding(for key: NumpadKey) -> Profile {
        var copy = self
        copy.bindings.removeAll { $0.key == key }
        copy.updatedAt = Date()
        return copy
    }

    static func createDefault() -> Profile {
        let bindings = zip(NumpadKey.keys(in: .numbers).dropFirst(), Snippet.samples).map {
            KeyBinding(key: $0, action: .snippet(id: $1.id))
        }
        return Profile(name: "Default", bindings: bindings, isActive: true)
    }
}
