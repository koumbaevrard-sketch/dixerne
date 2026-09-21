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

    private var session: LLMSession?
    private var loadTask: Task<Void, Never>?

    /// Messages bruts de la session (inclut le message système).
    var messages: [LLMInput.Message] {
        get { session?.messages ?? [] }
        set { session?.messages = newValue }
    }

    func resetMessages() {
        messages = [.system(persona.systemPrompt)]
    }

    /// Remplace le system prompt en tête de conversation sans effacer l'historique.
    func applyPersona(_ newPersona: Persona) {
        persona = newPersona
        guard let session else { return }
        var msgs = session.messages
        if msgs.first?.role == .system {
            msgs[0] = .system(newPersona.systemPrompt)
        } else {
            msgs.insert(.system(newPersona.systemPrompt), at: 0)
        }
        session.messages = msgs
    }

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
