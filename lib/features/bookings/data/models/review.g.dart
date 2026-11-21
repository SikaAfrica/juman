// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      professionalId: json['professional_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      reviewerName: json['reviewer_name'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
      'id': instance.id,
      'booking_id': instance.bookingId,
      'professional_id': instance.professionalId,
      'reviewer_id': instance.reviewerId,
      'reviewer_name': instance.reviewerName,
      'rating': instance.rating,
      'comment': instance.comment,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

ReviewCreate _$ReviewCreateFromJson(Map<String, dynamic> json) =>
    ReviewCreate(
      bookingId: json['booking_id'] as String,
      professionalId: json['professional_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$ReviewCreateToJson(ReviewCreate instance) =>
    <String, dynamic>{
      'booking_id': instance.bookingId,
      'professional_id': instance.professionalId,
      'rating': instance.rating,
      'comment': instance.comment,
    };
