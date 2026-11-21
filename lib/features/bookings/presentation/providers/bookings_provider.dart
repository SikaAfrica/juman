import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/bookings_remote_datasource.dart';
import '../../data/models/booking.dart';
import '../../../../core/services/api_service.dart';

final bookingsDatasourceProvider = Provider<BookingsRemoteDatasource>((ref) {
  return BookingsRemoteDatasource(ApiService.instance);
});

final myBookingsProvider = FutureProvider.family<List<Booking>, String>((ref, userId) async {
  final datasource = ref.watch(bookingsDatasourceProvider);
  return datasource.getMyBookings(userId);
});

final pendingBookingsProvider = FutureProvider.family<List<Booking>, String>((ref, professionalId) async {
  final datasource = ref.watch(bookingsDatasourceProvider);
  return datasource.getPendingBookings(professionalId);
});

final bookingDetailProvider = FutureProvider.family<Booking?, String>((ref, id) async {
  final datasource = ref.watch(bookingsDatasourceProvider);
  return datasource.getBookingById(id);
});
