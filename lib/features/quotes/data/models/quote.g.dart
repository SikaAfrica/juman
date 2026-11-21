// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuoteRequest _$QuoteRequestFromJson(Map<String, dynamic> json) =>
    QuoteRequest(
      professionalId: json['professional_id'] as String,
      serviceId: json['service_id'] as String,
      description: json['description'] as String,
      location: json['location'] as Map<String, dynamic>,
      preferredDate: json['preferred_date'] == null
          ? null
          : DateTime.parse(json['preferred_date'] as String),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$QuoteRequestToJson(QuoteRequest instance) =>
    <String, dynamic>{
      'professional_id': instance.professionalId,
      'service_id': instance.serviceId,
      'description': instance.description,
      'location': instance.location,
      'preferred_date': instance.preferredDate?.toIso8601String(),
      'photos': instance.photos,
    };

QuoteResponse _$QuoteResponseFromJson(Map<String, dynamic> json) =>
    QuoteResponse(
      bookingId: json['booking_id'] as String,
      estimatedPrice: (json['estimated_price'] as num).toDouble(),
      estimatedDuration: json['estimated_duration'] as int?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$QuoteResponseToJson(QuoteResponse instance) =>
    <String, dynamic>{
      'booking_id': instance.bookingId,
      'estimated_price': instance.estimatedPrice,
      'estimated_duration': instance.estimatedDuration,
      'notes': instance.notes,
    };

Quote _$QuoteFromJson(Map<String, dynamic> json) => Quote(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      professionalId: json['professional_id'] as String,
      serviceId: json['service_id'] as String,
      description: json['description'] as String,
      location: json['location'] as Map<String, dynamic>,
      preferredDate: json['preferred_date'] == null
          ? null
          : DateTime.parse(json['preferred_date'] as String),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      estimatedPrice: json['estimated_price'] as double?,
      estimatedDuration: json['estimated_duration'] as int?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$QuoteToJson(Quote instance) => <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'professional_id': instance.professionalId,
      'service_id': instance.serviceId,
      'description': instance.description,
      'location': instance.location,
      'preferred_date': instance.preferredDate?.toIso8601String(),
      'photos': instance.photos,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'estimated_price': instance.estimatedPrice,
      'estimated_duration': instance.estimatedDuration,
      'notes': instance.notes,
    };
