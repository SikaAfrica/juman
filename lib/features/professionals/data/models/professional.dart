import 'package:json_annotation/json_annotation.dart';

part 'professional.g.dart';

enum ServiceCategory {
  // Habitat
  plumber,
  electrician,
  mason,
  carpenter,
  tiler,
  painter,
  welder,
  glazier,
  roofer,
  plasterer,

  // Climatisation & Énergie
  acTechnician,
  refrigeration,
  solarInstallation,
  generator,
  industrialElectrician,
  electricalMaintenance,

  // Réparation
  phoneRepair,
  computerRepair,
  tvRepair,
  applianceRepair,
  motorcycleRepair,
  autoRepair,
  bicycleRepair,

  // Automobile
  mechanic,
  autoElectrician,
  bodywork,
  autoPainter,
  tireRepair,
  roadsideAssistance,

  // Entretien
  housekeeper,
  officeCleaning,
  industrialCleaning,
  gardening,
  disinfection,
  poolMaintenance,

  // Beauté & Bien-être
  hairdresser,
  barber,
  aesthetician,
  makeupArtist,
  stylist,
  tailor,
  spa,
  massage,

  // Événementiel
  photographer,
  cameraman,
  dj,
  animator,
  decorator,
  caterer,
  equipmentRental,

  // Formation
  tutor,
  trainer,
  sportsCoach,
  professionalCoach,
  itTrainer,
  privateTeacher,

  // Services aux entreprises
  accountant,
  consultant,
  developer,
  graphicDesigner,
  communityManager,
  translator,
  secretary,
}

enum ProfessionalStatus {
  active,
  inactive,
  suspended,
}

@JsonSerializable()
class Professional {
  final String id;
  final String userId;
  final String? businessName;
  final String displayName;
  final String? photoUrl;
  final String description;
  final List<ServiceCategory> categories;
  final Map<String, dynamic> location; // {city, commune, quarter, coordinates}
  final List<String> serviceArea; // Zones d'intervention
  final String phone;
  final String? email;
  final String? whatsapp;
  final int experienceYears;
  final List<String> certifications;
  final List<Map<String, dynamic>> portfolio; // [{image_url, description}]
  final double rating;
  final int reviewCount;
  final int totalBookings;
  final Map<String, dynamic> availability; // {day: {start, end}}
  final bool isVerified;
  final bool isPremium;
  final ProfessionalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Professional({
    required this.id,
    required this.userId,
    this.businessName,
    required this.displayName,
    this.photoUrl,
    required this.description,
    required this.categories,
    required this.location,
    required this.serviceArea,
    required this.phone,
    this.email,
    this.whatsapp,
    this.experienceYears = 0,
    this.certifications = const [],
    this.portfolio = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.totalBookings = 0,
    this.availability = const {},
    this.isVerified = false,
    this.isPremium = false,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Professional.fromJson(Map<String, dynamic> json) =>
      _$ProfessionalFromJson(json);

  Map<String, dynamic> toJson() => _$ProfessionalToJson(this);
}

@JsonSerializable()
class ProfessionalCreate {
  final String? businessName;
  final String displayName;
  final String? photoUrl;
  final String description;
  final List<ServiceCategory> categories;
  final Map<String, dynamic> location;
  final List<String> serviceArea;
  final String phone;
  final String? email;
  final String? whatsapp;
  final int experienceYears;
  final List<String> certifications;
  final List<Map<String, dynamic>> portfolio;
  final Map<String, dynamic> availability;

  ProfessionalCreate({
    this.businessName,
    required this.displayName,
    this.photoUrl,
    required this.description,
    required this.categories,
    required this.location,
    required this.serviceArea,
    required this.phone,
    this.email,
    this.whatsapp,
    this.experienceYears = 0,
    this.certifications = const [],
    this.portfolio = const [],
    this.availability = const {},
  });

  factory ProfessionalCreate.fromJson(Map<String, dynamic> json) =>
      _$ProfessionalCreateFromJson(json);

  Map<String, dynamic> toJson() => _$ProfessionalCreateToJson(this);
}

@JsonSerializable()
class ProfessionalUpdate {
  final String? businessName;
  final String? displayName;
  final String? photoUrl;
  final String? description;
  final List<ServiceCategory>? categories;
  final Map<String, dynamic>? location;
  final List<String>? serviceArea;
  final String? phone;
  final String? email;
  final String? whatsapp;
  final int? experienceYears;
  final List<String>? certifications;
  final List<Map<String, dynamic>>? portfolio;
  final Map<String, dynamic>? availability;

  ProfessionalUpdate({
    this.businessName,
    this.displayName,
    this.photoUrl,
    this.description,
    this.categories,
    this.location,
    this.serviceArea,
    this.phone,
    this.email,
    this.whatsapp,
    this.experienceYears,
    this.certifications,
    this.portfolio,
    this.availability,
  });

  factory ProfessionalUpdate.fromJson(Map<String, dynamic> json) =>
      _$ProfessionalUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ProfessionalUpdateToJson(this);
}
