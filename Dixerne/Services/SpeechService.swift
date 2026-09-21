import Foundation
import Observation
import Speech
import AVFoundation

/// Reconnaissance vocale (dictée) et synthèse vocale, toutes deux on-device.
@Observable @MainActor
final class SpeechService: NSObject {
    private(set) var isRecording = false
    private(set) var transcript = ""

    private let synthesizer = AVSpeechSynthesizer()
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override init() {
        super.init()
        synthesizer.delegate = self
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
    }

    var isAvailable: Bool { recognizer != nil }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func startRecording() throws {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { throw SpeechError.unavailable }

        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true
        // Force le traitement on-device quand c'est possible (zéro cloud).
        recognitionRequest.requiresOnDeviceRecognition = recognizer?.supportsOnDeviceRecognition == true

        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            if let result {
                self.transcript = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        transcript = ""
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    /// Synthèse vocale on-device (voix féminine française si disponible).
    func speak(_ text: String, language: String = "fr-FR") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice(language: language)
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }

    /// Choisit une voix féminine de la langue demandée quand elle existe, sinon la voix par défaut.
    private func preferredVoice(language: String) -> AVSpeechSynthesisVoice? {
        let prefix = String(language.prefix(2))
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix(prefix) }
        let female = candidates.first { voice in
            voice.name.localizedCaseInsensitiveContains("audrey")
                || voice.name.localizedCaseInsensitiveContains("female")
                || voice.name.localizedCaseInsensitiveContains("femme")
        }
        return female ?? AVSpeechSynthesisVoice(language: language)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    enum SpeechError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            switch self {
            case .unavailable: "Reconnaissance vocale indisponible."
            }
        }
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {}
