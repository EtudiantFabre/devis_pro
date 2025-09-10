# DevisPro - Générateur de Devis Professionnels

## 📱 Description

DevisPro est une application mobile Flutter qui permet de créer, gérer et partager des devis professionnels de manière simple et efficace. L'application fonctionne entièrement hors ligne et est prête pour l'intégration future d'un système d'abonnement premium.

## ✨ Fonctionnalités

### 🆓 Fonctionnalités Gratuites

- **Création de devis** : Créez des devis professionnels illimités
- **Gestion des clients** : Ajoutez, modifiez et supprimez vos clients
- **Gestion des produits** : Gérez votre catalogue de produits et services
- **Export PDF** : Générez et partagez vos devis en format PDF
- **Mode hors ligne** : Fonctionne sans connexion Internet
- **Base de données locale** : Stockage sécurisé avec SQLite

### 🌟 Fonctionnalités Premium (À venir)

- **Synchronisation Cloud** : Sauvegarde et synchronisation sur tous vos appareils
- **Analytics Avancées** : Tableaux de bord détaillés et statistiques
- **Personnalisation** : Logos personnalisés, couleurs et templates
- **Intégrations** : Connexion aux outils comptables et CRM
- **Support Prioritaire** : Assistance technique dédiée
- **Sauvegarde Automatique** : Sauvegarde quotidienne automatique

## 🏗️ Architecture Technique

### Base de Données (SQLite)
- **clients** : Informations des clients
- **produits** : Catalogue des produits et services
- **devis** : Devis créés avec leurs métadonnées
- **items_devis** : Articles détaillés de chaque devis

### Structure du Projet
```
lib/
├── models/           # Modèles de données
│   ├── client.dart
│   ├── produit.dart
│   ├── devis.dart
│   └── item_devis.dart
├── database/         # Gestion de la base de données
│   └── database_helper.dart
├── screens/          # Écrans de l'application
│   ├── main_navigation.dart
│   ├── home_screen.dart
│   ├── create_quote_screen.dart
│   ├── manage_clients_products_screen.dart
│   ├── quote_detail_screen.dart
│   └── subscription_screen.dart
├── services/         # Services métier
│   └── pdf_service.dart
├── theme/           # Thème et styles
│   └── app_theme.dart
└── main.dart        # Point d'entrée de l'application
```

## 🚀 Installation et Configuration

### Prérequis
- Flutter SDK (version 3.5.4 ou supérieure)
- Dart SDK
- Android Studio / VS Code avec extensions Flutter

### Installation
1. Clonez le projet
2. Naviguez vers le dossier du projet
3. Installez les dépendances :
   ```bash
   flutter pub get
   ```
4. Lancez l'application :
   ```bash
   flutter run
   ```

### Dépendances Principales
- **sqflite** : Base de données SQLite locale
- **pdf** : Génération de documents PDF
- **printing** : Impression et partage de PDF
- **path_provider** : Gestion des chemins de fichiers
- **share_plus** : Partage de fichiers
- **intl** : Formatage des dates et devises
- **provider** : Gestion d'état

## 📱 Utilisation

### 1. Écran d'Accueil
- Vue d'ensemble des devis récents
- Statistiques rapides
- Accès rapide aux fonctionnalités principales

### 2. Création de Devis
- Sélection ou ajout d'un client
- Ajout de produits avec quantités et prix
- Calcul automatique du total
- Génération d'un numéro de devis unique
- Notes optionnelles

### 3. Gestion Clients & Produits
- **Onglet Clients** : CRUD complet des clients
- **Onglet Produits** : CRUD complet des produits
- Interface intuitive avec recherche et filtres

### 4. Export et Partage
- Génération PDF professionnel
- Partage par email ou autres applications
- Impression directe

### 5. Abonnement Premium
- Interface prête pour les futurs abonnements
- Comparaison des fonctionnalités gratuites vs premium
- Gestion des plans d'abonnement

## 🎨 Design et Interface

### Thème
- **Couleurs principales** : Bleu (#6B73FF), Violet (#9B59B6), Vert (#2ECC71)
- **Style** : Moderne, minimaliste, couleurs douces
- **Interface** : Material Design 3 avec personnalisations

### Navigation
- Navigation par onglets en bas
- 4 sections principales : Accueil, Nouveau Devis, Clients & Produits, Premium

## 🔧 Développement

### Ajout de Nouvelles Fonctionnalités
1. Créez le modèle de données si nécessaire
2. Ajoutez les méthodes dans `DatabaseHelper`
3. Créez l'écran correspondant
4. Intégrez dans la navigation

### Personnalisation du Thème
Modifiez `lib/theme/app_theme.dart` pour ajuster :
- Couleurs
- Typographie
- Espacements
- Styles des composants

### Base de Données
La base de données est créée automatiquement au premier lancement. Pour modifier le schéma :
1. Incrémentez la version dans `DatabaseHelper`
2. Ajoutez la migration dans `_onCreate`

## 📄 Génération PDF

Le service PDF génère des documents professionnels avec :
- En-tête avec logo et informations de l'entreprise
- Informations du client et du devis
- Tableau détaillé des articles
- Calcul automatique des totaux
- Pied de page personnalisé

## 🔒 Sécurité et Confidentialité

- **Données locales** : Toutes les données sont stockées localement
- **Pas de collecte** : Aucune donnée n'est envoyée vers des serveurs externes
- **Chiffrement** : Protection des données sensibles
- **Sauvegarde** : Possibilité de sauvegarde locale

## 🚀 Déploiement

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 📈 Roadmap

### Version 1.1
- [ ] Synchronisation cloud
- [ ] Templates de devis personnalisables
- [ ] Notifications push
- [ ] Mode sombre

### Version 1.2
- [ ] Intégrations comptables
- [ ] Analytics avancées
- [ ] Export Excel
- [ ] Signature électronique

### Version 2.0
- [ ] Application web
- [ ] API REST
- [ ] Multi-utilisateurs
- [ ] Gestion des stocks

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour contribuer :
1. Forkez le projet
2. Créez une branche pour votre fonctionnalité
3. Committez vos changements
4. Poussez vers la branche
5. Ouvrez une Pull Request

## 📞 Support

Pour toute question ou problème :
- Créez une issue sur GitHub
- Consultez la documentation
- Contactez l'équipe de développement

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

---

**DevisPro** - Créez des devis professionnels en toute simplicité ! 🚀
