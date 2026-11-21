// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

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

Service _$ServiceFromJson(Map<String, dynamic> json) => Service(
      id: json['id'] as String?,
      professionalId: json['professional_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: $enumDecode(_$ServiceCategoryEnumMap, json['category'] as String),
      basePrice: (json['base_price'] as num).toDouble(),
      priceUnit: json['price_unit'] as String,
      estimatedDuration: json['estimated_duration'] as int?,
      requiresVisit: json['requires_visit'] as bool? ?? true,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ServiceToJson(Service instance) => <String, dynamic>{
      'id': instance.id,
      'professional_id': instance.professionalId,
      'name': instance.name,
      'description': instance.description,
      'category': _$ServiceCategoryEnumMap[instance.category],
      'base_price': instance.basePrice,
      'price_unit': instance.priceUnit,
      'estimated_duration': instance.estimatedDuration,
      'requires_visit': instance.requiresVisit,
      'active': instance.active,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

ServiceCreate _$ServiceCreateFromJson(Map<String, dynamic> json) =>
    ServiceCreate(
      professionalId: json['professional_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: $enumDecode(_$ServiceCategoryEnumMap, json['category'] as String),
      basePrice: (json['base_price'] as num).toDouble(),
      priceUnit: json['price_unit'] as String,
      estimatedDuration: json['estimated_duration'] as int?,
      requiresVisit: json['requires_visit'] as bool? ?? true,
    );

Map<String, dynamic> _$ServiceCreateToJson(ServiceCreate instance) =>
    <String, dynamic>{
      'professional_id': instance.professionalId,
      'name': instance.name,
      'description': instance.description,
      'category': _$ServiceCategoryEnumMap[instance.category],
      'base_price': instance.basePrice,
      'price_unit': instance.priceUnit,
      'estimated_duration': instance.estimatedDuration,
      'requires_visit': instance.requiresVisit,
    };

ServiceUpdate _$ServiceUpdateFromJson(Map<String, dynamic> json) =>
    ServiceUpdate(
      name: json['name'] as String?,
      description: json['description'] as String?,
      category: json['category'] == null
          ? null
          : $enumDecode(_$ServiceCategoryEnumMap, json['category'] as String),
      basePrice: json['base_price'] as double?,
      priceUnit: json['price_unit'] as String?,
      estimatedDuration: json['estimated_duration'] as int?,
      requiresVisit: json['requires_visit'] as bool?,
      active: json['active'] as bool?,
    );

Map<String, dynamic> _$ServiceUpdateToJson(ServiceUpdate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'category': instance.category == null
          ? null
          : _$ServiceCategoryEnumMap[instance.category],
      'base_price': instance.basePrice,
      'price_unit': instance.priceUnit,
      'estimated_duration': instance.estimatedDuration,
      'requires_visit': instance.requiresVisit,
      'active': instance.active,
    };
