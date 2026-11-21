# DJUMAN - Plateforme de Services Professionnels

DJUMAN signifie "Métier" en baoulé. C'est la plateforme de services professionnels de l'écosystème Sika.

## Vision
Faire de DJUMAN la plateforme de référence en Afrique pour la recherche, la réservation et le paiement de prestations de services, en permettant à chaque particulier ou entreprise de trouver rapidement un professionnel qualifié et de confiance.

## Mission
Digitaliser les métiers et les services en mettant en relation les clients avec des professionnels qualifiés, afin de simplifier la recherche, la prise de rendez-vous, le paiement et le suivi des prestations.

## Catégories de métiers (9)
- 🏠 **Habitat**: Plombier, Électricien, Maçon, Menuisier, Carreleur, Peintre, Soudeur, Vitrier, Couvreur, Plâtrier
- ❄ **Climatisation & Énergie**: Climatisation, Réfrigération, Installation solaire, Groupe électrogène, Électricien industriel
- 🔧 **Réparation**: Téléphones, Ordinateurs, Télévisions, Électroménager, Moto, Automobile, Vélo
- 🚗 **Automobile**: Mécanicien, Électricien auto, Carrossier, Peintre automobile, Vulcanisateur, Dépannage
- 🧹 **Entretien**: Femme de ménage, Nettoyage bureaux, Nettoyage industriel, Jardinage, Désinfection
- ✂ **Beauté & Bien-être**: Coiffeur, Coiffeuse, Barbier, Esthéticienne, Maquilleur, Styliste, Couturier, Spa, Massage
- 📷 **Événementiel**: Photographe, Caméraman, DJ, Animateur, Décorateur, Traiteur, Location de matériel
- 📚 **Formation**: Répétiteur, Formateur, Coach sportif, Coach professionnel, Formateur informatique
- 🏢 **Services aux entreprises**: Comptable, Consultant, Développeur informatique, Graphiste, Community Manager

## Architecture Backend (sikapi/modules/djuman/)
- **models.py**: Professional, Service, Booking, Review, Category
- **services.py**: ProfessionalService, BookingService, ReviewService, CategoryService
- **routes/**:
  - professionals.py: CRUD professionnels, recherche, vérification
  - services.py: CRUD services proposés
  - bookings.py: CRUD réservations, annulation, liste pending
  - reviews.py: CRUD avis clients
  - categories.py: CRUD catégories de métiers

## Architecture Flutter (templates/djuman/)
- **core/**:
  - config/djuman_environment.dart: Configuration environnement (dev/staging/prod)
  - services/api_service.dart: Singleton Dio avec intercepteur auth
  - services/auth_token_coordinator.dart: Gestion tokens (stockage, refresh)
  - services/satellite_auth_interceptor.dart: Intercepteur pour headers Authorization
  - providers/api_service_provider.dart: Riverpod providers Dio/ApiService
  - providers/auth_provider.dart: State management authentification
  - providers/router_provider.dart: Configuration GoRouter
  - widgets/auth_modal.dart: Modal de connexion

- **features/shell/**:
  - presentation/pages/djuman_shell_page.dart: Shell avec BottomNavigationBar

- **features/search/**:
  - presentation/pages/search_page.dart: Recherche avec filtres catégories

- **features/professionals/**:
  - data/models/professional.dart: Models Professional, ProfessionalCreate, ProfessionalUpdate
  - data/models/service.dart: Models Service, ServiceCreate, ServiceUpdate
  - data/datasources/professionals_remote_datasource.dart: API calls professionnels
  - presentation/providers/professionals_provider.dart: Riverpod providers
  - presentation/pages/professionals_page.dart: Liste professionnels
  - presentation/pages/professional_detail_page.dart: Détail professionnel

- **features/bookings/**:
  - data/models/booking.dart: Models Booking, BookingCreate, BookingUpdate
  - data/models/review.dart: Models Review, ReviewCreate
  - data/datasources/bookings_remote_datasource.dart: API calls réservations
  - presentation/providers/bookings_provider.dart: Riverpod providers
  - presentation/pages/bookings_page.dart: Liste réservations
  - presentation/pages/booking_detail_page.dart: Détail réservation

- **features/profile/**:
  - presentation/pages/profile_page.dart: Profil utilisateur
  - presentation/pages/professional_profile_page.dart: Profil professionnel

## Navigation Flutter
BottomNavigationBar avec 5 onglets:
1. **Recherche** - Recherche professionnels par catégorie, ville, mots-clés
2. **Professionnels** - Liste des professionnels
3. **Réservations** - Mes réservations
4. **Messages** - Messagerie (Intégration Idjowlê - à venir)
5. **Profil** - Profil utilisateur et professionnel

## Intégrations Écosystème
- **Idjowlê**: Messagerie instantanée client-professionnel, appels audio/vidéo
- **GEF**: Paiements sécurisés, facturation automatique, comptabilité
- **LOTO/MOTO**: Transport de matériel, livraison pièces de rechange
- **ATTA**: Achat de fournitures (matériaux, outils, équipements)

## API Endpoints
- `POST /djuman/professionals/` - Créer profil professionnel
- `GET /djuman/professionals/` - Lister professionnels (filtres: category, city, search)
- `GET /djuman/professionals/:id` - Détail professionnel
- `PUT /djuman/professionals/:id` - Mettre à jour professionnel
- `POST /djuman/services/` - Créer service
- `GET /djuman/services/` - Lister services
- `POST /djuman/bookings/` - Créer réservation
- `GET /djuman/bookings/` - Lister mes réservations
- `GET /djuman/bookings/pending` - Réservations pending (professionnel)
- `POST /djuman/bookings/:id/cancel` - Annuler réservation
- `POST /djuman/reviews/` - Créer avis
- `GET /djuman/reviews/` - Lister avis professionnel
- `POST /djuman/categories/` - Créer catégorie (admin)
- `GET /djuman/categories/` - Lister catégories

## Installation

### Backend
1. Le module DJUMAN est déjà intégré dans `sikapi/main.py`
2. Les routes sont disponibles sous `/djuman/*`
3. MongoDB collections: `djuman_professionals`, `djuman_services`, `djuman_bookings`, `djuman_reviews`, `djuman_categories`

### Frontend
1. Installer les dépendances:
```bash
cd templates/djuman
flutter pub get
```

2. Générer les fichiers JSON serialization:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Lancer l'application:
```bash
flutter run
```

## Configuration
L'URL de l'API est configurée dans `lib/core/config/djuman_environment.dart`:
- Development: `http://127.0.0.1:8000`
- Staging: `https://staging-api.sika.app`
- Production: `https://api.sika.app`

## Thème DJUMAN
- **Couleur primaire**: Jaune (or) - #F2B41A (RGB: 242, 180, 26)
- **Couleur secondaire**: Bleu foncé (navy) - #112B5C (RGB: 17, 43, 92)
- **Couleur d'accent**: Vert - #00C853
- **Couleur d'arrière-plan**: Gris clair - #F5F7FA
- **Couleur de surface**: Blanc - #FFFFFF
- **Couleur d'erreur**: Rouge - #DC2626
- **AppBar**: Dégradé Jaune or (#F2B41A) → Bleu navy (#112B5C)

## Modèle économique
- Commission sur les prestations réalisées
- Abonnements Premium pour les professionnels
- Mise en avant sponsorisée des profils
- Services de vérification et de certification
- Publicités ciblées

## Place dans l'écosystème Sika
DJUMAN devient le hub des services de l'écosystème Sîka - la porte d'entrée numérique de tous les métiers et services de proximité, apportant confiance, simplicité et efficacité.
