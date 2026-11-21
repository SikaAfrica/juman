import 'package:json_annotation/json_annotation.dart';

part 'quote.g.dart';

@JsonSerializable()
class QuoteRequest {
  final String professionalId;
  final String serviceId;
  final String description;
  final Map<String, dynamic> location; // {address, coordinates: {lat, lng}}
  final DateTime? preferredDate;
  final List<String> photos;

  QuoteRequest({
    required this.professionalId,
    required this.serviceId,
    required this.description,
    required this.location,
    this.preferredDate,
    this.photos = const [],
  });

  factory QuoteRequest.fromJson(Map<String, dynamic> json) =>
      _$QuoteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$QuoteRequestToJson(this);
}

@JsonSerializable()
class QuoteResponse {
  final String bookingId;
  final double estimatedPrice;
  final int? estimatedDuration; // minutes
  final String? notes;

  QuoteResponse({
    required this.bookingId,
    required this.estimatedPrice,
    this.estimatedDuration,
    this.notes,
  });

  factory QuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$QuoteResponseFromJson(json);

  Map<String, dynamic> toJson() => _$QuoteResponseToJson(this);
}

@JsonSerializable()
class Quote {
  final String id;
  final String clientId;
  final String professionalId;
  final String serviceId;
  final String description;
  final Map<String, dynamic> location;
  final DateTime? preferredDate;
  final List<String> photos;
  final String status; // pending, responded
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? estimatedPrice;
  final int? estimatedDuration;
  final String? notes;

  Quote({
    required this.id,
    required this.clientId,
    required this.professionalId,
    required this.serviceId,
    required this.description,
    required this.location,
    this.preferredDate,
    this.photos = const [],
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.estimatedPrice,
    this.estimatedDuration,
    this.notes,
  });

  factory Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);

  Map<String, dynamic> toJson() => _$QuoteToJson(this);
}
