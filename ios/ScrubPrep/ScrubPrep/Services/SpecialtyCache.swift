import Foundation

/// Persists the last-fetched specialty list so the Home screen's specialty menu can render
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
        // See SelectedSpecialtyStore.save's comment — same abrupt-kill race applies here.
        UserDefaults.standard.synchronize()
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
        // UserDefaults normally shouldn't need an explicit synchronize() — the OS flushes
        // it at appropriate lifecycle points. But Xcode's Stop button sends an immediate
        // SIGKILL with no grace period (unlike backgrounding on a real device), so a
        // selection made right before hitting Stop can be lost before cfprefsd writes it
        // to disk. Forcing the flush here closes that window.
        UserDefaults.standard.synchronize()
    }
}
