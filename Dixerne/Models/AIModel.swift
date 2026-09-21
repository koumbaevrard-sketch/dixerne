import Foundation

/// Catalogue des modèles GGUF (backend llama.cpp) disponibles dans l'app.
/// Chaque entrée référence un modèle réel hébergé sur Hugging Face, au format quantisé.
enum AIModel: String, CaseIterable, Identifiable, Sendable {
    case qwen25_1_5b
    case qwen25_3b
    case gemma3_1b
    case phi4mini

    static let `default` = qwen25_1_5b

    var id: String { rawValue }

    /// Nom lisible dans l'interface.
    var name: String {
        switch self {
        case .qwen25_1_5b: "Qwen 2.5 1.5B — rapide"
        case .qwen25_3b: "Qwen 2.5 3B — équilibré"
        case .gemma3_1b: "Gemma 3 1B — léger"
        case .phi4mini: "Phi-4 Mini 3.8B — qualité"
        }
    }

    /// Identifiant du dépôt Hugging Face.
    var repoId: String {
        switch self {
        case .qwen25_1_5b: "Qwen/Qwen2.5-1.5B-Instruct-GGUF"
        case .qwen25_3b: "Qwen/Qwen2.5-3B-Instruct-GGUF"
        case .gemma3_1b: "lmstudio-community/gemma-3-1B-it-qat-GGUF"
        case .phi4mini: "unsloth/Phi-4-mini-instruct-GGUF"
        }
    }

    /// Nom exact du fichier .gguf dans le dépôt.
    var filename: String {
        switch self {
        case .qwen25_1_5b: "qwen2.5-1.5b-instruct-q4_k_m.gguf"
        case .qwen25_3b: "qwen2.5-3b-instruct-q4_k_m.gguf"
        case .gemma3_1b: "gemma-3-1B-it-QAT-Q4_0.gguf"
        case .phi4mini: "Phi-4-mini-instruct-Q4_K_M.gguf"
        }
    }

    /// Taille approximative à l'écran, pour informer l'utilisateur.
    var estimatedSize: String {
        switch self {
        case .qwen25_1_5b: "≈ 1,0 Go"
        case .qwen25_3b: "≈ 2,1 Go"
        case .gemma3_1b: "≈ 0,8 Go"
        case .phi4mini: "≈ 2,5 Go"
        }
    }
}
