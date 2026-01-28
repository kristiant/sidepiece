import Foundation

/// A named collection of key bindings that can be switched between
struct Profile: Identifiable, Codable, Equatable {
    
    // MARK: - Properties
    
    let id: UUID
    var name: String
    var bindings: [KeyBinding]
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialisation
    
    init(
        id: UUID = UUID(),
        name: String,
        bindings: [KeyBinding] = [],
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.bindings = bindings
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    /// Number of configured bindings
    var bindingCount: Int {
        bindings.count
    }
    
    /// Number of enabled bindings
    var enabledBindingCount: Int {
        bindings.filter(\.isEnabled).count
    }
    
    // MARK: - Binding Operations
    
    /// Get the binding for a specific key, if one exists
    func binding(for key: NumpadKey) -> KeyBinding? {
        bindings.first { $0.key == key }
    }
    
    /// Returns a copy with an added or updated binding
    func withBinding(_ binding: KeyBinding) -> Profile {
        var copy = self
        if let index = copy.bindings.firstIndex(where: { $0.key == binding.key }) {
            copy.bindings[index] = binding
        } else {
            copy.bindings.append(binding)
        }
        copy.updatedAt = Date()
        return copy
    }
    
    /// Returns a copy with a binding removed for the given key
    func withoutBinding(for key: NumpadKey) -> Profile {
        var copy = self
        copy.bindings.removeAll { $0.key == key }
        copy.updatedAt = Date()
        return copy
    }
}

// MARK: - Default Profile

extension Profile {
    
    /// Creates a default profile with sample bindings
    static func createDefault() -> Profile {
        let samples = Snippet.samples
        
        var bindings: [KeyBinding] = []
        
        // Map first 6 samples to numpad 1-6
        let numpadKeys: [NumpadKey] = [.num1, .num2, .num3, .num4, .num5, .num6]
        
        for (index, key) in numpadKeys.enumerated() where index < samples.count {
            let binding = KeyBinding(key: key, snippet: samples[index])
            bindings.append(binding)
        }
        
        return Profile(
            name: "Default",
            bindings: bindings,
            isActive: true
        )
    }
}
