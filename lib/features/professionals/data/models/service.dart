import 'package:json_annotation/json_annotation.dart';
import 'professional.dart';

part 'service.g.dart';

@JsonSerializable()
class Service {
  final String? id;
  final String professionalId;
  final String name;
  final String description;
  final ServiceCategory category;
  final double basePrice;
  final String priceUnit; // "hour", "day", "project"
  final int? estimatedDuration; // minutes
  final bool requiresVisit;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    this.id,
    required this.professionalId,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    required this.priceUnit,
    this.estimatedDuration,
    this.requiresVisit = true,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceToJson(this);
}

@JsonSerializable()
class ServiceCreate {
  final String professionalId;
  final String name;
  final String description;
  final ServiceCategory category;
  final double basePrice;
  final String priceUnit;
  final int? estimatedDuration;
  final bool requiresVisit;

  ServiceCreate({
    required this.professionalId,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    required this.priceUnit,
    this.estimatedDuration,
    this.requiresVisit = true,
  });

  factory ServiceCreate.fromJson(Map<String, dynamic> json) =>
      _$ServiceCreateFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceCreateToJson(this);
}

@JsonSerializable()
class ServiceUpdate {
  final String? name;
  final String? description;
  final ServiceCategory? category;
  final double? basePrice;
  final String? priceUnit;
  final int? estimatedDuration;
  final bool? requiresVisit;
  final bool? active;

  ServiceUpdate({
    this.name,
    this.description,
    this.category,
    this.basePrice,
    this.priceUnit,
    this.estimatedDuration,
    this.requiresVisit,
    this.active,
  });

  factory ServiceUpdate.fromJson(Map<String, dynamic> json) =>
      _$ServiceUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceUpdateToJson(this);
}
