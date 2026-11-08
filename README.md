# Guess The Word — Flutter LAN MVP

Application Flutter Android + iOS pour jouer à plusieurs sur le même réseau Wi‑Fi.
Un téléphone héberge la partie, les autres rejoignent via l'adresse IP affichée par l'hôte.

## Fonctionnalités incluses
- Création d'une salle sur le réseau Wi‑Fi local.
- Rejoindre une salle par adresse IP et port.
- Pseudonyme des joueurs.
- Questions emoji → mot anglais, avec catégories et niveaux.
- Réponses synchronisées par WebSocket, arbitrage des réponses par l'hôte.
- Chronomètre, points, classement et écran de fin.
- Mode entraînement local.
- Interface Flutter adaptative Android/iOS.

## Prérequis
- Flutter stable (Dart 3.3 ou supérieur).
- Android Studio + Android SDK pour Android.
- Xcode sur macOS pour compiler iOS (un build iOS ne peut pas être produit depuis Windows).
- Les téléphones doivent être sur le même réseau Wi‑Fi. Désactiver temporairement l'isolation AP/client du routeur si les appareils ne se voient pas.

## Lancer le projet
Depuis ce dossier :

```bash
flutter pub get
flutter run
```

Pour créer un APK de test :
```bash
flutter build apk --debug
```
Le fichier est généré dans `build/app/outputs/flutter-apk/app-debug.apk`.

Pour iOS (sur macOS avec Xcode) :
```bash
flutter build ios --debug
```

## Test multitéléphone
1. Installer/lancer l'application sur le téléphone hôte.
2. Choisir « Créer une salle ». L'application affiche l'IP locale et le port 4040.
3. Sur les autres téléphones, choisir « Rejoindre une salle », saisir l'IP affichée et le pseudonyme, puis se connecter.
4. L'hôte démarre la partie. Tous les appareils reçoivent les mêmes questions et scores.
5. Testez une réponse correcte depuis un téléphone et vérifiez le classement sur tous les appareils.

## Réseau et sécurité
- Le serveur WebSocket est hébergé directement par le téléphone hôte (`dart:io`).
- Le protocole est prévu pour un réseau local de confiance. Il n'y a pas de chiffrement TLS, d'authentification forte ni de protection contre un client modifié : ne pas exposer le port à Internet.
- L'hôte est l'autorité pour les questions, le chronomètre et les scores.
- Cette version utilise une adresse IP saisie manuellement. La découverte automatique des salles et les reconnexions transparentes pourront être ajoutées dans une prochaine itération.
- Les connexions locales nécessitent les autorisations réseau de l'OS et du routeur.

## Configuration Android
Le manifeste `android/app/src/main/AndroidManifest.xml` contient les permissions INTERNET, ACCESS_NETWORK_STATE et ACCESS_WIFI_STATE.

## Configuration iOS
`ios/Runner/Info.plist` doit contenir les descriptions de confidentialité `NSLocalNetworkUsageDescription` et `NSBonjourServices` si vous ajoutez plus tard la découverte Bonjour. L'app utilise actuellement l'adresse IP saisie et WebSocket local. La permission réseau local doit être acceptée au premier lancement.
Le fichier `ios/Runner/Info.plist` fourni est un fragment de configuration à fusionner dans le projet iOS généré par `flutter create` si votre version Flutter génère un Info.plist différent.

## Structure
- `lib/main.dart` : démarrage.
- `lib/models.dart` : joueurs, questions et état de partie.
- `lib/game_data.dart` : banque de questions d'exemple.
- `lib/lan_service.dart` : serveur/client WebSocket local.
- `lib/game_controller.dart` : logique autoritaire de partie et synchronisation.
- `lib/screens.dart` : interface complète.

## Important
Ce ZIP contient le code source Flutter, les fichiers de configuration réseau et les instructions de génération. Pour générer les projets natifs complets adaptés à votre installation Flutter, exécutez une seule fois :
```bash
flutter create --platforms=android,ios .
```
Si Flutter demande de remplacer des fichiers, conservez vos fichiers `lib/` et `pubspec.yaml`; vérifiez ensuite le manifeste Android et les clés iOS mentionnées ci-dessus.
