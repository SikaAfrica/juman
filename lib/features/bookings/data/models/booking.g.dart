// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      professionalId: json['professional_id'] as String,
      serviceId: json['service_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      totalPrice: (json['total_price'] as num?)?.toDouble(),
      status: $enumDecode(_$BookingStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'professional_id': instance.professionalId,
      'service_id': instance.serviceId,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'duration_minutes': instance.durationMinutes,
      'location': instance.location,
      'notes': instance.notes,
      'total_price': instance.totalPrice,
      'status': _$BookingStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

BookingCreate _$BookingCreateFromJson(Map<String, dynamic> json) =>
    BookingCreate(
      professionalId: json['professional_id'] as String,
      serviceId: json['service_id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$BookingCreateToJson(BookingCreate instance) =>
    <String, dynamic>{
      'professional_id': instance.professionalId,
      'service_id': instance.serviceId,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'duration_minutes': instance.durationMinutes,
      'location': instance.location,
      'notes': instance.notes,
    };

BookingUpdate _$BookingUpdateFromJson(Map<String, dynamic> json) =>
    BookingUpdate(
      scheduledDate: json['scheduled_date'] == null
          ? null
          : DateTime.parse(json['scheduled_date'] as String),
      durationMinutes: json['duration_minutes'] as int?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] == null
          ? null
          : $enumDecode(_$BookingStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$BookingUpdateToJson(BookingUpdate instance) =>
    <String, dynamic>{
      'scheduled_date': instance.scheduledDate?.toIso8601String(),
      'duration_minutes': instance.durationMinutes,
      'location': instance.location,
      'notes': instance.notes,
      'status': instance.status == null
          ? null
          : _$BookingStatusEnumMap[instance.status],
    };

const _$BookingStatusEnumMap = {
  BookingStatus.pending: 'pending',
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.inProgress: 'in_progress',
  BookingStatus.completed: 'completed',
  BookingStatus.cancelled: 'cancelled',
};
