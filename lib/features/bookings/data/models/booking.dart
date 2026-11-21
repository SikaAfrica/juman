import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

@JsonSerializable()
class Booking {
  final String id;
  final String clientId;
  final String professionalId;
  final String serviceId;
  final DateTime scheduledDate;
  final int durationMinutes;
  final String? location;
  final String? notes;
  final double? totalPrice;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    required this.clientId,
    required this.professionalId,
    required this.serviceId,
    required this.scheduledDate,
    this.durationMinutes = 60,
    this.location,
    this.notes,
    this.totalPrice,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);

  Map<String, dynamic> toJson() => _$BookingToJson(this);
}

@JsonSerializable()
class BookingCreate {
  final String professionalId;
  final String serviceId;
  final DateTime scheduledDate;
  final int durationMinutes;
  final String? location;
  final String? notes;

  BookingCreate({
    required this.professionalId,
    required this.serviceId,
    required this.scheduledDate,
    this.durationMinutes = 60,
    this.location,
    this.notes,
  });

  factory BookingCreate.fromJson(Map<String, dynamic> json) =>
      _$BookingCreateFromJson(json);

  Map<String, dynamic> toJson() => _$BookingCreateToJson(this);
}

@JsonSerializable()
class BookingUpdate {
  final DateTime? scheduledDate;
  final int? durationMinutes;
  final String? location;
  final String? notes;
  final BookingStatus? status;

  BookingUpdate({
    this.scheduledDate,
    this.durationMinutes,
    this.location,
    this.notes,
    this.status,
  });

  factory BookingUpdate.fromJson(Map<String, dynamic> json) =>
      _$BookingUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$BookingUpdateToJson(this);
}
