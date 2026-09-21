import Foundation
import UIKit
import LocalLLMClient

/// État observable de la conversation : relie l'UI au moteur LLM et aux services voix/vision.
@Observable @MainActor
final class ChatViewModel {
    private let engine: LLMEngine
    let speech: SpeechService

    var inputText = ""
    var lastError: String?

    private var generateTask: Task<Void, Never>?
    private var generatingText = ""
    private var pendingUserMessage: String?

    init() {
        engine = LLMEngine()
        speech = SpeechService()
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
        }
    }
}
