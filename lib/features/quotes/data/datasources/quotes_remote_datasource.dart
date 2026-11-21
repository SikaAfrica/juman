import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../models/quote.dart';

class QuotesRemoteDatasource {
  final ApiService _apiService;

  QuotesRemoteDatasource(this._apiService);

  /// Créer une demande de devis
  /// POST /djuman/quotes/?client_id={client_id}
  Future<Map<String, dynamic>> createQuoteRequest(
    String clientId,
    QuoteRequest quoteRequest,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/djuman/quotes/',
        data: quoteRequest.toJson(),
        queryParameters: {'client_id': clientId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Erreur création demande de devis: $e');
    }
  }

  /// Répondre à une demande de devis
  /// POST /djuman/quotes/{quote_id}/respond?professional_id={professional_id}
  Future<Map<String, dynamic>> respondQuote(
    String professionalId,
    String quoteId,
    QuoteResponse quoteResponse,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/djuman/quotes/$quoteId/respond',
        data: quoteResponse.toJson(),
        queryParameters: {'professional_id': professionalId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception('Erreur réponse devis: $e');
    }
  }

  /// Récupérer une demande de devis par ID
  /// GET /djuman/quotes/{quote_id}
  Future<Quote> getQuote(String quoteId) async {
    try {
      final response = await _apiService.dio.get('/djuman/quotes/$quoteId');
      return Quote.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erreur récupération devis: $e');
    }
  }

  /// Lister les demandes de devis d'un utilisateur
  /// GET /djuman/quotes/?user_id={user_id}&role={role}
  /// role: "client" ou "professional"
  Future<List<Quote>> listMyQuotes(String userId, String role) async {
    try {
      final response = await _apiService.dio.get(
        '/djuman/quotes/',
        queryParameters: {
          'user_id': userId,
          'role': role,
        },
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Quote.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Erreur liste devis: $e');
    }
  }
}
