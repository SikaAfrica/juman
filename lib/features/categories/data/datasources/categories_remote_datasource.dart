import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../models/category.dart';

class CategoriesRemoteDatasource {
  final ApiService _apiService;

  CategoriesRemoteDatasource(this._apiService);

  /// Lister les catégories actives
  /// GET /djuman/categories/
  Future<List<Category>> listCategories({bool activeOnly = true}) async {
    try {
      final response = await _apiService.dio.get(
        '/djuman/categories/',
        queryParameters: {'active_only': activeOnly},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Erreur chargement catégories: $e');
    }
  }

  /// Récupérer une catégorie par ID
  /// GET /djuman/categories/{category_id}
  Future<Category?> getCategory(String categoryId) async {
    try {
      final response = await _apiService.dio.get('/djuman/categories/$categoryId');
      return Category.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erreur chargement catégorie: $e');
    }
  }

  /// Récupérer une catégorie par name_key
  /// GET /djuman/categories/key/{name_key}
  Future<Category?> getCategoryByKey(String nameKey) async {
    try {
      final response = await _apiService.dio.get('/djuman/categories/key/$nameKey');
      return Category.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erreur chargement catégorie: $e');
    }
  }
}
