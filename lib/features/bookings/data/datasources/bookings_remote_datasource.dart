import 'package:dio/dio.dart';
import '../../../../core/services/api_service.dart';
import '../models/booking.dart';
import '../models/review.dart';

class BookingsRemoteDatasource {
  final ApiService _apiService;

  BookingsRemoteDatasource(this._apiService);

  /// Lister les réservations d'un client
  /// GET /djuman/bookings/?client_id={client_id}
  Future<List<Booking>> getMyBookings(String userId) async {
    try {
      final response = await _apiService.dio.get(
        '/djuman/bookings/',
        queryParameters: {'client_id': userId},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Booking.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Erreur chargement réservations: $e');
    }
  }

  /// Lister les réservations en attente d'un professionnel
  /// GET /djuman/bookings/pending?professional_id={professional_id}
  Future<List<Booking>> getPendingBookings(String professionalId) async {
    try {
      final response = await _apiService.dio.get(
        '/djuman/bookings/pending',
        queryParameters: {'professional_id': professionalId},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Booking.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Erreur chargement réservations en attente: $e');
    }
  }

  /// Récupérer une réservation par ID
  /// GET /djuman/bookings/{booking_id}
  Future<Booking?> getBookingById(String id) async {
    try {
      final response = await _apiService.dio.get('/djuman/bookings/$id');
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erreur chargement réservation: $e');
    }
  }

  /// Créer une réservation
  /// POST /djuman/bookings/?client_id={client_id}
  Future<Booking> createBooking(
    String clientId,
    BookingCreate data,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/djuman/bookings/',
        data: data.toJson(),
        queryParameters: {'client_id': clientId},
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erreur création réservation: $e');
    }
  }

  /// Mettre à jour une réservation
  /// PUT /djuman/bookings/{booking_id}
  Future<Booking> updateBooking(
    String id,
    BookingUpdate data,
  ) async {
    try {
      final response = await _apiService.dio.put(
        '/djuman/bookings/$id',
        data: data.toJson(),
      );
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erreur mise à jour réservation: $e');
    }
  }

  /// Annuler une réservation
  /// POST /djuman/bookings/{booking_id}/cancel
  Future<Booking> cancelBooking(String id) async {
    try {
      final response = await _apiService.dio.post('/djuman/bookings/$id/cancel');
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erreur annulation réservation: $e');
    }
  }

  /// Créer un avis
  /// POST /djuman/reviews/?reviewer_id={reviewer_id}
  Future<Review> createReview(
    String reviewerId,
    ReviewCreate data,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/djuman/reviews/',
        data: data.toJson(),
        queryParameters: {'reviewer_id': reviewerId},
      );
      return Review.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Erreur création avis: $e');
    }
  }

  /// Lister les avis d'un professionnel
  /// GET /djuman/reviews/?professional_id={professional_id}
  Future<List<Review>> getProfessionalReviews(String professionalId) async {
    try {
      final response = await _apiService.dio.get(
        '/djuman/reviews/',
        queryParameters: {'professional_id': professionalId},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Erreur chargement avis: $e');
    }
  }
}
