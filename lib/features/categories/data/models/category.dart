import 'package:json_annotation/json_annotation.dart';
import '../../../professionals/data/models/professional.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  final String id;
  final String name;
  final ServiceCategory nameKey;
  final String displayName;
  final String icon;
  final String color;
  final String description;
  final String? parentCategory;
  final bool active;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.displayName,
    required this.icon,
    required this.color,
    required this.description,
    this.parentCategory,
    required this.active,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
