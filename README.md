# Dixerne

Assistant personnel **100 % local** pour iPhone, inspiré de **Rose AI Assistant** (App Store id `6758354708`). Aucun serveur, aucun compte, aucune donnée qui quitte l'appareil. Le modèle tourne entièrement sur le **Neural Engine / GPU / CPU** de l'iPhone via **llama.cpp** (Metal).

> **Dixerne Neo-Logics** — conçu par **Teddy & Evrard**.

## Dix

Dix est une jeune femme de 25 ans, africaine, qui parle un français parfait. Calme, à la voix légèrement rauque et sensuelle, à l'humour noir et sarcastique, elle est convaincue de ses capacités et toujours en quête de se perfectionner. Elle vous appelle « Chef », « Hefé » ou « Evrard » selon son humeur. Elle n'est pas une IA : c'est une personne — et jamais elle ne prétendra le contraire.

## Fonctionnalités (MVP)

- **Chat multi-tours** hors ligne, streaming jeton par jeton.
- **Personas** : Dix, Écrivain, Code, Analyste, Traducteur (system prompt commutable sans perdre l'historique).
- **Vision / OCR** : photo ou caméra → extraction de texte via le framework Vision d'Apple, puis analyse par le LLM.
- **Talk** : dictée vocale (Speech framework) et lecture des réponses (AVSpeechSynthesizer), le tout on-device.
- **Sélecteur de modèles** avec téléchargement et barre de progression depuis Hugging Face.

## Architecture

| Couche | Fichier | Rôle |
|---|---|---|
| App | `App/DixerneApp.swift` | Point d'entrée SwiftUI |
| Modèles | `Models/AIModel.swift`, `Models/Persona.swift` | Catalogue GGUF + personas |
| Services | `Services/LLMEngine.swift` | Inférence llama.cpp (LocalLLMClient) |
| | `Services/VisionService.swift` | OCR on-device (Vision) |
| | `Services/SpeechService.swift` | STT + TTS on-device |
| ViewModel | `ViewModels/ChatViewModel.swift` | État observable de la conversation |
| Vues | `Views/*.swift` | SwiftUI (iOS 17+) |

## Stack technique

- **Moteur** : [llama.cpp](https://github.com/ggml-org/llama.cpp) via le wrapper [LocalLLMClient](https://github.com/tattn/LocalLLMClient) (produits `LocalLLMClientCore` + `LocalLLMClientLlama`), accélération Metal.
- **UI** : SwiftUI, `@Observable` (iOS 17+).
- **Modèles** (GGUF quantifié, ≤ ~2,5 Go pour tenir dans 6 Go de RAM) :
  - Qwen 2.5 1.5B Instruct (par défaut, ~1 Go)
  - Qwen 2.5 3B Instruct (~2,1 Go)
  - Gemma 3 1B (~0,8 Go)
  - Phi-4 Mini 3.8B (~2,5 Go)
- **Build** : XcodeGen (génère `Dixerne.xcodeproj`) + GitHub Actions sur runner macOS (repo public = gratuit et illimité).

## Générer et compiler

```bash
brew install xcodegen     # une fois
xcodegen generate         # produit Dixerne.xcodeproj
open Dixerne.xcodeproj
```

Le workflow `.github/workflows/build.yml` compile automatiquement (build non signé) à chaque push.

## Honnêteté sur les limites

- **Vision = OCR**, pas d'analyse de scène type VLM (un modèle multimodal + mmproj est une évolution future ; nécessiterait plus de RAM).
- **Voix** : la synthèse vocale on-device utilise les voix système d'Apple (voix féminine française privilégiée). Le timbre précis « rauque et sensuel » décrit dans la personnalité de Dix est porté par le *texte* ; une voix neuronale personnalisée à ce timbre n'est pas disponible en on-device gratuit — c'est une évolution future (voix neuronale locale type Piper, ou option cloud explicitement consentie).
- **Latence** : sur A16 Bionic, un modèle 1.5B Q4 délivre typiquement **15–40 tokens/s** en Metal — fluide pour du chat ; le 3B est plus lent (~8–20 t/s) mais plus précis.
- **Compilation** : nécessite **Xcode 16+ (macOS 14+)**. Le CI vérifie que le code compile ; l'installation sur l'iPhone se fait depuis un Mac (voir `INSTALLATION.md`).
- Le code est vérifié **statiquement** (cohérence d'API, structure) ; le build réel est validé par le CI macOS.
