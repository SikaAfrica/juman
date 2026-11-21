// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'professional.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

const _$ServiceCategoryEnumMap = {
  ServiceCategory.plumber: 'plumber',
  ServiceCategory.electrician: 'electrician',
  ServiceCategory.mason: 'mason',
  ServiceCategory.carpenter: 'carpenter',
  ServiceCategory.tiler: 'tiler',
  ServiceCategory.painter: 'painter',
  ServiceCategory.welder: 'welder',
  ServiceCategory.glazier: 'glazier',
  ServiceCategory.roofer: 'roofer',
  ServiceCategory.plasterer: 'plasterer',
  ServiceCategory.acTechnician: 'ac_technician',
  ServiceCategory.refrigeration: 'refrigeration',
  ServiceCategory.solarInstallation: 'solar_installation',
  ServiceCategory.generator: 'generator',
  ServiceCategory.industrialElectrician: 'industrial_electrician',
  ServiceCategory.electricalMaintenance: 'electrical_maintenance',
  ServiceCategory.phoneRepair: 'phone_repair',
  ServiceCategory.computerRepair: 'computer_repair',
  ServiceCategory.tvRepair: 'tv_repair',
  ServiceCategory.applianceRepair: 'appliance_repair',
  ServiceCategory.motorcycleRepair: 'motorcycle_repair',
  ServiceCategory.autoRepair: 'auto_repair',
  ServiceCategory.bicycleRepair: 'bicycle_repair',
  ServiceCategory.mechanic: 'mechanic',
  ServiceCategory.autoElectrician: 'auto_electrician',
  ServiceCategory.bodywork: 'bodywork',
  ServiceCategory.autoPainter: 'auto_painter',
  ServiceCategory.tireRepair: 'tire_repair',
  ServiceCategory.roadsideAssistance: 'roadside_assistance',
  ServiceCategory.housekeeper: 'housekeeper',
  ServiceCategory.officeCleaning: 'office_cleaning',
  ServiceCategory.industrialCleaning: 'industrial_cleaning',
  ServiceCategory.gardening: 'gardening',
  ServiceCategory.disinfection: 'disinfection',
  ServiceCategory.poolMaintenance: 'pool_maintenance',
  ServiceCategory.hairdresser: 'hairdresser',
  ServiceCategory.barber: 'barber',
  ServiceCategory.aesthetician: 'esthetician',
  ServiceCategory.makeupArtist: 'makeup_artist',
  ServiceCategory.stylist: 'stylist',
  ServiceCategory.tailor: 'tailor',
  ServiceCategory.spa: 'spa',
  ServiceCategory.massage: 'massage',
  ServiceCategory.photographer: 'photographer',
  ServiceCategory.cameraman: 'cameraman',
  ServiceCategory.dj: 'dj',
  ServiceCategory.animator: 'animator',
  ServiceCategory.decorator: 'decorator',
  ServiceCategory.caterer: 'caterer',
  ServiceCategory.equipmentRental: 'equipment_rental',
  ServiceCategory.tutor: 'tutor',
  ServiceCategory.trainer: 'trainer',
  ServiceCategory.sportsCoach: 'sports_coach',
  ServiceCategory.professionalCoach: 'professional_coach',
  ServiceCategory.itTrainer: 'it_trainer',
  ServiceCategory.privateTeacher: 'private_teacher',
  ServiceCategory.accountant: 'accountant',
  ServiceCategory.consultant: 'consultant',
  ServiceCategory.developer: 'developer',
  ServiceCategory.graphicDesigner: 'graphic_designer',
  ServiceCategory.communityManager: 'community_manager',
  ServiceCategory.translator: 'translator',
  ServiceCategory.secretary: 'secretary',
};

Professional _$ProfessionalFromJson(Map<String, dynamic> json) => Professional(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessName: json['business_name'] as String?,
      displayName: json['display_name'] as String,
      photoUrl: json['photo_url'] as String?,
      description: json['description'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => $enumDecode(_$ServiceCategoryEnumMap, e as String))
          .toList(),
      location: json['location'] as Map<String, dynamic>,
      serviceArea: (json['service_area'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      phone: json['phone'] as String,
      email: json['email'] as String?,
      whatsapp: json['whatsapp'] as String?,
      experienceYears: json['experience_years'] as int? ?? 0,
      certifications: (json['certifications'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      portfolio: (json['portfolio'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      totalBookings: json['total_bookings'] as int? ?? 0,
      availability: json['availability'] as Map<String, dynamic>? ?? {},
      isVerified: json['is_verified'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      status: $enumDecode(_$ProfessionalStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ProfessionalToJson(Professional instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'business_name': instance.businessName,
      'display_name': instance.displayName,
      'photo_url': instance.photoUrl,
      'description': instance.description,
      'categories': instance.categories
          .map((e) => _$ServiceCategoryEnumMap[e]!)
          .toList(),
      'location': instance.location,
      'service_area': instance.serviceArea,
      'phone': instance.phone,
      'email': instance.email,
      'whatsapp': instance.whatsapp,
      'experience_years': instance.experienceYears,
      'certifications': instance.certifications,
      'portfolio': instance.portfolio,
      'rating': instance.rating,
      'review_count': instance.reviewCount,
      'total_bookings': instance.totalBookings,
      'availability': instance.availability,
      'is_verified': instance.isVerified,
      'is_premium': instance.isPremium,
      'status': _$ProfessionalStatusEnumMap[instance.status],
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$ProfessionalStatusEnumMap = {
  ProfessionalStatus.active: 'active',
  ProfessionalStatus.inactive: 'inactive',
  ProfessionalStatus.suspended: 'suspended',
};

ProfessionalCreate _$ProfessionalCreateFromJson(Map<String, dynamic> json) =>
    ProfessionalCreate(
      businessName: json['business_name'] as String?,
      displayName: json['display_name'] as String,
      photoUrl: json['photo_url'] as String?,
      description: json['description'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => $enumDecode(_$ServiceCategoryEnumMap, e as String))
          .toList(),
      location: json['location'] as Map<String, dynamic>,
      serviceArea: (json['service_area'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      phone: json['phone'] as String,
      email: json['email'] as String?,
      whatsapp: json['whatsapp'] as String?,
      experienceYears: json['experience_years'] as int? ?? 0,
      certifications: (json['certifications'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      portfolio: (json['portfolio'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      availability: json['availability'] as Map<String, dynamic>? ?? {},
    );

Map<String, dynamic> _$ProfessionalCreateToJson(ProfessionalCreate instance) =>
    <String, dynamic>{
      'business_name': instance.businessName,
      'display_name': instance.displayName,
      'photo_url': instance.photoUrl,
      'description': instance.description,
      'categories': instance.categories
          .map((e) => _$ServiceCategoryEnumMap[e]!)
          .toList(),
      'location': instance.location,
      'service_area': instance.serviceArea,
      'phone': instance.phone,
      'email': instance.email,
      'whatsapp': instance.whatsapp,
      'experience_years': instance.experienceYears,
      'certifications': instance.certifications,
      'portfolio': instance.portfolio,
      'availability': instance.availability,
    };

ProfessionalUpdate _$ProfessionalUpdateFromJson(Map<String, dynamic> json) =>
    ProfessionalUpdate(
      businessName: json['business_name'] as String?,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      description: json['description'] as String?,
      categories: json['categories'] == null
          ? null
          : (json['categories'] as List<dynamic>)
              .map((e) => $enumDecode(_$ServiceCategoryEnumMap, e as String))
              .toList(),
      location: json['location'] as Map<String, dynamic>?,
      serviceArea: json['service_area'] == null
          ? null
          : (json['service_area'] as List<dynamic>).map((e) => e as String).toList(),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      whatsapp: json['whatsapp'] as String?,
      experienceYears: json['experience_years'] as int?,
      certifications: json['certifications'] == null
          ? null
          : (json['certifications'] as List<dynamic>).map((e) => e as String).toList(),
      portfolio: json['portfolio'] == null
          ? null
          : (json['portfolio'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
      availability: json['availability'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ProfessionalUpdateToJson(ProfessionalUpdate instance) =>
    <String, dynamic>{
      'business_name': instance.businessName,
      'display_name': instance.displayName,
      'photo_url': instance.photoUrl,
      'description': instance.description,
      'categories': instance.categories
          ?.map((e) => _$ServiceCategoryEnumMap[e]!)
          .toList(),
      'location': instance.location,
      'service_area': instance.serviceArea,
      'phone': instance.phone,
      'email': instance.email,
      'whatsapp': instance.whatsapp,
      'experience_years': instance.experienceYears,
      'certifications': instance.certifications,
      'portfolio': instance.portfolio,
      'availability': instance.availability,
    };
