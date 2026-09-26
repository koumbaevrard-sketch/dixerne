import Foundation
import LocalLLMClientCore
import LocalLLMClientLlama

/// Moteur d'inférence : gère le téléchargement, le chargement et l'exécution
/// d'un modèle GGUF (backend llama.cpp) via LocalLLMClient.
@Observable @MainActor
final class LLMEngine {
    private(set) var model: AIModel = .default
    private(set) var isLoading = false
    private(set) var progress: Double = 0.0
    private(set) var isLoaded = false
    private(set) var errorMessage: String?

    var persona: Persona = PersonaCatalog.default

    /// Faits durables (mémoire à long terme) injectés dans le prompt système.
    private(set) var facts: [String] = []

    private var session: LLMSession?
    private var loadTask: Task<Void, Never>?

    /// Messages bruts de la session (inclut le message système).
    var messages: [LLMInput.Message] {
        get { session?.messages ?? [] }
        set { session?.messages = newValue }
    }

    // MARK: - Prompt système (persona + mémoire durable)

    /// Construit le prompt système : persona + bloc mémoire durable.
    private func systemPrompt() -> String {
        var prompt = persona.systemPrompt
        if !facts.isEmpty {
            prompt += "\n\nMÉMOIRE DURABLE — ce que tu sais de ton interlocuteur (informations stables, à utiliser naturellement quand c'est pertinent, sans les réciter ni dire que tu les as mémorisées) :\n"
            prompt += facts.map { "- \($0)" }.joined(separator: "\n")
        }
        return prompt
    }

    /// Remplace le message système en tête de conversation sans effacer l'historique.
    private func rebuildSystemPrompt() {
        guard let session else { return }
        var msgs = session.messages
        if msgs.first?.role == .system {
            msgs[0] = .system(systemPrompt())
        } else {
            msgs.insert(.system(systemPrompt()), at: 0)
        }
        session.messages = msgs
    }

    func resetMessages() {
        messages = [.system(systemPrompt())]
    }

    /// Remplace le system prompt en tête de conversation sans effacer l'historique.
    func applyPersona(_ newPersona: Persona) {
        persona = newPersona
        rebuildSystemPrompt()
    }

    /// Met à jour la mémoire durable et réinjecte le prompt système.
    func setFacts(_ newFacts: [String]) {
        facts = newFacts
        rebuildSystemPrompt()
    }

    /// Restaure une conversation persistée dans la session courante.
    func restoreConversation(_ stored: [MemoryStore.StoredMessage]) {
        guard let session, !stored.isEmpty else { return }
        var msgs: [LLMInput.Message] = [.system(systemPrompt())]
        for m in stored {
            switch m.role {
            case "user": msgs.append(.user(m.content))
            case "assistant": msgs.append(.assistant(m.content))
            default: break
            }
        }
        session.messages = msgs
    }

    /// Photographie l'historique (sans le message système) pour persistance.
    /// Borné aux 60 derniers messages pour rester dans la fenêtre de contexte.
    func snapshotHistory() -> [MemoryStore.StoredMessage] {
        let kept = messages.filter { $0.role != .system && $0.role != .tool }
        return kept.suffix(60).map {
            MemoryStore.StoredMessage(role: $0.role.rawValue, content: $0.content)
        }
    }

    // MARK: - Chargement

    /// Télécharge (si besoin) puis charge le modèle en mémoire.
    func load(_ model: AIModel) async {
        cancelLoad()
        isLoading = true
        progress = 0.0
        errorMessage = nil
        defer { isLoading = false }

        // Libère le modèle précédent avant d'en charger un nouveau.
        session = nil
        isLoaded = false
        self.model = model

        let downloadModel: LLMSession.DownloadModel = .llama(
            id: model.repoId,
            model: model.filename,
            mmproj: nil,
            parameter: .init(
                context: 8192,
                options: .init(extraEOSTokens: [], verbose: false)
            )
        )

        loadTask = Task {
            do {
                try await downloadModel.downloadModel { @MainActor [weak self] progress in
                    self?.progress = progress
                }
                session = LLMSession(model: downloadModel, tools: [])
                isLoaded = true
                resetMessages()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        await loadTask?.value
    }

    func cancelLoad() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }

    /// Envoie un message et reçoit la réponse en streaming (jeton par jeton).
    func ask(_ text: String) async throws -> AsyncThrowingStream<String, any Error> {
        guard let session else {
            throw LLMError.failedToLoad(reason: "Modèle non chargé")
        }
        return session.streamResponse(to: text)
    }
}
