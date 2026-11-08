# Génération des dossiers natifs complets

Le ZIP fournit le code Flutter, le manifeste Android et les réglages iOS réseau. Les fichiers de projet natifs complets sont spécifiques à la version de Flutter et à l'environnement local.

Dans le dossier du projet, exécuter :
```bash
flutter create --platforms=android,ios .
```
Puis vérifier que les permissions du manifeste Android correspondent à `android/app/src/main/AndroidManifest.xml` et fusionner les clés iOS du fichier `ios/Runner/Info.plist` dans le plist généré.

Sur Windows : Android peut être compilé et testé. Pour compiler iOS, utiliser un Mac avec Xcode.
