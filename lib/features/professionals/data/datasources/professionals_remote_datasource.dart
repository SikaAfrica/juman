import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../models/professional.dart';
import '../models/service.dart';

class ProfessionalsRemoteDatasource {
  final ApiService _apiService;

  ProfessionalsRemoteDatasource(this._apiService);

  /// Lister les professionnels avec filtres
  /// Correspond à GET /djuman/professionals/
  Future<List<Professional>> getProfessionals({
    String? category,
    String? city,
    String? commune,
    bool verifiedOnly = false,
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/djuman/professionals/',
        queryParameters: {
          if (category != null) 'category': category,
          if (city != null) 'city': city,
          if (commune != null) 'commune': commune,
          'verified_only': verifiedOnly,
          'limit': limit,
          'skip': skip,
        },
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Professional.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Erreur chargement professionnels: $e');
    }
  }

  /// Rechercher des professionnels par texte
  /// Correspond à GET /djuman/professionals/search
  Future<List<Professional>> searchProfessionals({
    required String query,
    String? city,
    int limit = 50,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/djuman/professionals/search',
        queryParameters: {
          'query': query,
          if (city != null) 'city': city,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Professional.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Erreur recherche professionnels: $e');
    }
  }

  /// Trouver les professionnels à proximité (géolocalisation)
  /// Correspond à GET /djuman/professionals/nearby
  Future<List<Professional>> getNearbyProfessionals({
    required double lat,
    required double lng,
    double radiusKm = 10,
    String? category,
    int limit = 50,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/djuman/professionals/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius_km': radiusKm,
          if (category != null) 'category': category,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Professional.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Erreur professionnels à proximité: $e');
    }
  }

  Future<Professional?> getProfessionalById(String id) async {
    try {
      final response = await _apiService.dio.get('/djuman/professionals/$id');
      return Professional.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erreur chargement professionnel: $e');
    }
  }

  /// Récupérer le profil professionnel d'un utilisateur
  Future<Professional?> getMyProfessionalProfile(String userId) async {
    try {
      final response = await _apiService.dio.get(
        '/djuman/professionals/',
        queryParameters: {'user_id': userId},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      if (data.isNotEmpty) {
        return Professional.fromJson(data.first as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      throw Exception('Erreur chargement profil professionnel: $e');
    }
  }

  Future<Professional> createProfessional(
    String userId,
    ProfessionalCreate data,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/djuman/professionals/',
        data: data.toJson(),
        queryParameters: {'user_id': userId},
      );
      return Professional.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erreur création professionnel: $e');
    }
  }

  Future<Professional> updateProfessional(
    String id,
    ProfessionalUpdate data,
  ) async {
    try {
      final response = await _apiService.dio.put(
        '/djuman/professionals/$id',
        data: data.toJson(),
      );
      return Professional.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erreur mise à jour professionnel: $e');
    }
  }

  Future<List<Service>> getProfessionalServices(String professionalId) async {
    try {
      final response = await _apiService.dio.get(
        '/djuman/services',
        queryParameters: {'professional_id': professionalId},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Service.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Erreur chargement services: $e');
    }
  }
}
