import Foundation

/// Persists the last-fetched specialty list so the Home screen's specialty row can render
/// instantly on launch instead of waiting on a network round-trip every time.
enum SpecialtyCache {
    private static let key = "cachedSpecialties.v1"

    static func load() -> [Specialty] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Specialty].self, from: data) else {
            return []
        }
        return decoded
    }

    static func save(_ specialties: [Specialty]) {
        guard let data = try? JSONEncoder().encode(specialties) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

/// Persists which specialty the student had selected so it's remembered across app
/// launches — closing and reopening the app shouldn't reset back to "no specialty".
enum SelectedSpecialtyStore {
    private static let key = "selectedSpecialtyID.v1"

    static func load() -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    /// Pass `nil` to clear the persisted selection (e.g. when the user deselects).
    static func save(_ id: String?) {
        if let id {
            UserDefaults.standard.set(id, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
