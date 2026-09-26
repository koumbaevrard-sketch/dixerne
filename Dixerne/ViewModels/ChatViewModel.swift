import Foundation
import UIKit
import LocalLLMClientCore

/// État observable de la conversation : relie l'UI au moteur LLM et aux services voix/vision.
@Observable @MainActor
final class ChatViewModel {
    private let engine: LLMEngine
    let speech: SpeechService
    private let memory: MemoryStore

    var inputText = ""
    var lastError: String?

    private var generateTask: Task<Void, Never>?
    private var generatingText = ""
    private var pendingUserMessage: String?
    /// Historique chargé depuis le disque, à réinjecter après le chargement du modèle.
    private var pendingHistory: [MemoryStore.StoredMessage]?

    init() {
        engine = LLMEngine()
        speech = SpeechService()
        memory = MemoryStore.shared
        engine.setFacts(memory.loadFacts())
        let history = memory.loadHistory()
        pendingHistory = history.isEmpty ? nil : history
        engine.resetMessages()
    }

    // MARK: - État exposé à l'UI

    var messages: [LLMInput.Message] {
        var msgs = engine.messages.filter { $0.role != .system }
        if let pendingUserMessage, msgs.last?.role != .user {
            msgs.append(.user(pendingUserMessage))
        }
        if !generatingText.isEmpty, msgs.last?.role != .assistant {
            msgs.append(.assistant(generatingText))
        }
        return msgs
    }

    var isGenerating: Bool { generateTask != nil }
    var currentModel: AIModel { engine.model }
    var isModelLoaded: Bool { engine.isLoaded }
    var isLoadingModel: Bool { engine.isLoading }
    var loadProgress: Double { engine.progress }
    var modelErrorMessage: String? { engine.errorMessage }
    var currentPersona: Persona { engine.persona }

    // MARK: - Actions

    func loadModel(_ model: AIModel) async {
        cancelGeneration()
        await engine.load(model)
        if engine.isLoaded, let pendingHistory {
            engine.restoreConversation(pendingHistory)
            self.pendingHistory = nil
        }
    }

    func selectPersona(_ persona: Persona) {
        engine.applyPersona(persona)
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating else { return }
        guard engine.isLoaded else {
            lastError = "Aucun modèle chargé. Ouvrez le sélecteur de modèles pour en télécharger un."
            return
        }
        inputText = ""
        lastError = nil
        handleMemoryCommand(text)
        runGeneration(prompt: text, pending: text)
    }

    /// Extrait le texte d'une image (OCR on-device) puis l'envoie au modèle.
    func sendImageText(_ image: UIImage) async {
        guard engine.isLoaded, !isGenerating else { return }
        do {
            let ocr = try await VisionService.recognizeText(in: image)
            let trimmed = ocr.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                lastError = "Aucun texte détecté dans cette image. (L'analyse de scène type VLM est une évolution future.)"
                return
            }
            let prompt = "Voici le texte extrait d'une image (OCR). Analyse-le et réponds de façon utile :\n\n\(trimmed)"
            runGeneration(prompt: prompt, pending: "📷 Texte extrait d'une image")
        } catch {
            lastError = error.localizedDescription
        }
    }

    func cancelGeneration() {
        generateTask?.cancel()
        generateTask = nil
        generatingText = ""
        pendingUserMessage = nil
    }

    func clearChat() {
        cancelGeneration()
        engine.resetMessages()
        memory.clearHistory()
    }

    // MARK: - Mémoire à long terme

    /// Détecte les commandes « retiens que … » / « oublie … » et met à jour la mémoire durable.
    private func handleMemoryCommand(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        let addPrefixes = [
            "retiens que ", "souviens-toi que ", "rappelle-toi que ",
            "mémorise que ", "memorise que ", "note que "
        ]
        for prefix in addPrefixes where lower.hasPrefix(prefix) {
            let fact = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !fact.isEmpty else { return }
            var facts = engine.facts
            if !facts.contains(where: { $0.caseInsensitiveCompare(fact) == .orderedSame }) {
                facts.append(fact)
                engine.setFacts(facts)
                memory.saveFacts(facts)
            }
            return
        }

        let forgetPrefixes = [
            "oublie ", "efface de ta mémoire ", "efface de ta memoire ",
            "supprime de ta mémoire ", "supprime de ta memoire "
        ]
        for prefix in forgetPrefixes where lower.hasPrefix(prefix) {
            let term = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !term.isEmpty else { return }
            var facts = engine.facts
            let before = facts.count
            if term == "tout" || term == "tous" {
                facts.removeAll()
            } else {
                facts.removeAll { $0.lowercased().contains(term) }
            }
            if facts.count != before {
                engine.setFacts(facts)
                memory.saveFacts(facts)
            }
            return
        }
    }

    // MARK: - Interne

    private func runGeneration(prompt: String, pending: String) {
        pendingUserMessage = pending
        generateTask = Task {
            generatingText = ""
            do {
                let stream = try await engine.ask(prompt)
                for try await token in stream {
                    generatingText += token
                }
            } catch {
                lastError = error.localizedDescription
            }
            pendingUserMessage = nil
            generatingText = ""
            generateTask = nil
            memory.saveHistory(engine.snapshotHistory())
        }
    }
}
