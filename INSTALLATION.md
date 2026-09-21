# Installer « Dixerne » sur votre iPhone 14 Pro

Le CI compile et **vérifie** le code. Pour **installer** l'app sur l'iPhone, il faut un Mac (ou un PC) à côté de vous, un câble Lightning, et un **Apple ID gratuit** — pas besoin du compte développeur à 99 $/an.

## Prérequis

- **iPhone 14 Pro** sous iOS 17 ou plus.
- Un **Mac récent** (Xcode 16+ nécessite macOS 14 Sonoma ou plus). Si votre MacBook Pro est un Apple Silicon (M1, fin 2020), une simple mise à jour macOS gratuite suffit. S'il est Intel en Big Sur 11.7, il ne peut pas faire tourner Xcode 16 — utilisez alors un autre Mac ou la méthode « Sideload » ci-dessous.
- **Apple ID gratuit** (celui que vous utilisez pour iCloud/App Store).
- ~3 Go libres sur l'iPhone pour le modèle.

## Méthode A — Xcode (recommandée, la plus fiable)

1. Sur le Mac : `brew install xcodegen`, puis dans le dossier du projet `xcodegen generate`.
2. Ouvrez `Dixerne.xcodeproj` dans Xcode.
3. Branchez l'iPhone, sélectionnez-le comme destination (il apparaît dans le menu en haut).
4. Xcode → Settings → Accounts → ajoutez votre **Apple ID** gratuit.
5. Onglet *Signing & Capabilities* de la target → cochez *Automatically manage signing*, team = votre identifiant.
6. Vérifiez que l'identifiant de bundle est unique (ex. `com.vous.dixerne`) dans `project.yml` → régénérez si modifié.
7. **Run** (▶). L'app s'installe. À la première ouverture : Réglages → Général → Gestion VPN et appareil → faites confiance à votre certificat.

> Signature gratuite = valable **7 jours**, puis il faut re-Run depuis Xcode (ou re-signer). Limite inhérente au compte gratuit d'Apple, pas au projet.

## Méthode B — Sideload (Mac ou Windows, sans Xcode)

1. Récupérez l'IPA (archive compilée en CI ou via Xcode → Archive → Distribute → Development).
2. Utilisez **Sideloadly** (Mac/Win) ou **AltStore** : connectez-vous avec votre Apple ID gratuit, glissez l'IPA.
3. Renouvellement tous les 7 jours (AltStore le fait automatiquement en Wi-Fi si l'ordinateur est à portée).

## Premier lancement

1. Ouvrez l'app → icône 🧠 (en haut à droite) → choisissez **Qwen 2.5 1.5B** (≈1 Go) → « Télécharger ».
2. Une fois le modèle chargé, discutez avec Dix. Le micro fait la dictée, l'icône 📷/📸 extrait le texte d'une photo, le haut-parleur lit les réponses.

## Dépannage

- **« Aucun texte détecté »** : image trop floue ou sans texte ; pointez un document bien éclairé.
- **App se ferme en chargement** : le modèle 3B est trop lourd pour 6 Go avec d'autres apps ouvertes → utilisez le 1.5B.
- **Latence** : préférez le 1.5B pour une fluidité maximale sur A16.
