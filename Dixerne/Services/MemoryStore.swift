import Foundation

/// Persistance locale de la mémoire de Dix, 100 % hors ligne :
/// - historique de conversation (`dix_history.json`)
/// - faits durables sur l'utilisateur (`dix_memory.json`)
/// Tout vit dans le dossier Documents du bac à sable de l'app.
final class MemoryStore {
    static let shared = MemoryStore()

    /// Un message de conversation persisté (rôle + texte), indépendant de LocalLLMClient.
    struct StoredMessage: Codable, Equatable {
        let role: String   // "user" | "assistant" (le message système est régénéré, jamais stocké)
        let content: String
    }

    private let historyURL: URL
    private let factsURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        historyURL = docs.appendingPathComponent("dix_history.json")
        factsURL = docs.appendingPathComponent("dix_memory.json")
    }

    // MARK: - Historique de conversation

    func loadHistory() -> [StoredMessage] {
        guard let data = try? Data(contentsOf: historyURL),
              let msgs = try? JSONDecoder().decode([StoredMessage].self, from: data) else {
            return []
        }
        return msgs
    }

    func saveHistory(_ msgs: [StoredMessage]) {
        guard let data = try? JSONEncoder().encode(msgs) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }

    func clearHistory() {
        try? FileManager.default.removeItem(at: historyURL)
    }

    // MARK: - Faits durables (mémoire à long terme)

    func loadFacts() -> [String] {
        guard let data = try? Data(contentsOf: factsURL),
              let facts = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return facts
    }

    func saveFacts(_ facts: [String]) {
        guard let data = try? JSONEncoder().encode(facts) else { return }
        try? data.write(to: factsURL, options: .atomic)
    }

    func clearFacts() {
        try? FileManager.default.removeItem(at: factsURL)
    }
}
