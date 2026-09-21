# Installer Dixerne sur iPhone (AltStore / SideStore)

Ce guide explique comment installer **Dixerne** sur un iPhone (testé sur iPhone 14 Pro, iOS 17+)
avec un **Apple ID gratuit**, sans payer l'abonnement développeur Apple (99 $/an).

Le build CI produit une app **non signée** (compilée gratuitement sur les runners macOS de GitHub Actions).
Tu la signes toi-même avec ton Apple ID via **AltStore** (ou SideStore), puis tu l'installes.

---

## Ce qu'il te faut

- **iPhone 14 Pro** (iOS 17 ou plus) + câble USB Lightning
- **Un Mac** (macOS 10.14.4 ou plus — Big Sur convient) pour AltServer
- **Un Apple ID gratuit** (avec ou sans double authentification)
- **WiFi** au premier lancement (téléchargement du modèle)

---

## Étape 1 — Récupérer l'IPA

1. Ouvre : https://github.com/koumbaevrard-sketch/dixerne/actions
2. Clique sur le **dernier run vert** (Build iOS)
3. En bas, télécharge l'artefact **`Dixerne-ipa`**
4. Dézippe → tu obtiens **`Dixerne.ipa`**

---

## Étape 2 — Installer AltServer sur le Mac

1. Télécharge AltServer : https://altstore.io
2. Ouvre le `.zip`, glisse **AltServer.app** dans Applications, lance-le
3. Une icône apparaît dans la **barre de menu** (en haut à droite)

> Si AltServer te demande d'activer un plugin **Mail**, tu peux soit l'activer
> (Préférences Mail → Gérer les modules), soit passer par l'installation USB décrite ci-dessous.

---

## Étape 3 — Installer AltStore sur l'iPhone

1. **Branche l'iPhone au Mac** en USB (déverrouille l'iPhone, autorise « Faire confiance »)
2. Dans la barre de menu, clique l'icône **AltServer** → **« Install AltStore »** → choisis ton iPhone
3. Saisis **ton Apple ID** et ton mot de passe
   - Si tu as la **double authentification (2FA)** : crée un **mot de passe d'app** sur
     appleid.apple.com → « Mots de passe d'app » → utilise-le ici à la place du mot de passe
4. **AltStore** apparaît sur l'écran d'accueil de l'iPhone

---

## Étape 4 — Faire confiance au développeur

Sur l'iPhone :

1. Réglages → Général → **VPN & gestion de l'appareil**
2. Touche ton Apple ID → **« Faire confiance »**

(Si tu ne vois pas ce menu, lance d'abord AltStore une fois.)

---

## Étape 5 — Installer Dixerne

1. Transfère **`Dixerne.ipa`** sur l'iPhone (AirDrop, ou via l'app Fichiers)
2. Ouvre **AltStore** → onglet **« My Apps »** → bouton **« + »**
3. Choisis **`Dixerne.ipa`** → AltStore signe et installe (quelques secondes)
4. **Dixerne** apparaît sur l'écran d'accueil

---

## Étape 6 — Premier lancement

1. Ouvre **Dixerne**
2. Au premier lancement, va dans **Réglages modèle** et télécharge
   **Qwen2.5-1.5B-Instruct (Q4_K_M, ~1 Go)** depuis HuggingFace — **WiFi requis**, une seule fois
3. Le modèle reste stocké sur l'appareil : tout tourne ensuite **100 % hors ligne**

---

## Renouvellement (tous les 7 jours)

La signature gratuite expire après **7 jours**. Deux options :

- **Automatique** : laisse AltServer ouvert sur le Mac, iPhone sur le même WiFi →
  AltStore se renouvelle tout seul
- **Manuel** : rebranche l'iPhone au Mac → AltStore → « **Refresh All** »

---

## Alternative : SideStore (sans Mac au quotidien)

SideStore renouvelle la signature directement depuis l'iPhone, sans AltServer.
Configuration plus technique (serveur Anisette). Guide officiel : https://sidestore.io

---

## Limites honnêtes

- **Signature gratuite** = 7 jours, renouvellement requis (pas de côté Apple payant)
- **Voix TTS** = voix Apple standard (FR féminine). Le timbre « rauque/sensuel » précis de Dix
  n'est pas réalisable gratuitement en on-device ; c'est un best-effort, améliorable plus tard
  (Piper on-device ou voix cloud, avec ton accord)
- **Latence** : modèle 1.5B sur A16 → ~15-40 jetons/s (léger délai avant la réponse, normal)
- **Entitlement mémoire** : l'app demande `increased-memory-limit`. Si AltStore refuse de signer
  à cause de cet entitlement, retire-le de `Dixerne/Dixerne.entitlements` et relance le build CI
