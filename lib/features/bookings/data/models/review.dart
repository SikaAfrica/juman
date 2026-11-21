import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

@JsonSerializable()
class Review {
  final String id;
  final String bookingId;
  final String professionalId;
  final String reviewerId;
  final String reviewerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.professionalId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) =>
      _$ReviewFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}

@JsonSerializable()
class ReviewCreate {
  final String bookingId;
  final String professionalId;
  final int rating;
  final String? comment;

  ReviewCreate({
    required this.bookingId,
    required this.professionalId,
    required this.rating,
    this.comment,
  });

  factory ReviewCreate.fromJson(Map<String, dynamic> json) =>
      _$ReviewCreateFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewCreateToJson(this);
}
