import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/shell/presentation/pages/djuman_shell_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/professionals/presentation/pages/professionals_page.dart';
import '../../features/professionals/presentation/pages/professional_detail_page.dart';
import '../../features/professionals/presentation/pages/nearby_professionals_page.dart';
import '../../features/bookings/presentation/pages/bookings_page.dart';
import '../../features/bookings/presentation/pages/booking_detail_page.dart';
import '../../features/bookings/presentation/pages/booking_create_page.dart';
import '../../features/bookings/presentation/pages/review_create_page.dart';
import '../../features/quotes/presentation/pages/quotes_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/messages/presentation/pages/messages_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/professional_profile_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/search',
    debugLogDiagnostics: true,
    routes: [
      ShellRoute(
        builder: (context, state, child) => DjumanShellPage(child: child),
        routes: [
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => const MaterialPage(child: SearchPage()),
          ),
          GoRoute(
            path: '/professionals',
            name: 'professionals',
            pageBuilder: (context, state) => const MaterialPage(child: ProfessionalsPage()),
          ),
          GoRoute(
            path: '/professionals/nearby',
            name: 'nearby_professionals',
            pageBuilder: (context, state) => const MaterialPage(child: NearbyProfessionalsPage()),
          ),
          GoRoute(
            path: '/professionals/:id',
            name: 'professional_detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaterialPage(child: ProfessionalDetailPage(professionalId: id));
            },
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            pageBuilder: (context, state) => const MaterialPage(child: CategoriesPage()),
          ),
          GoRoute(
            path: '/bookings',
            name: 'bookings',
            pageBuilder: (context, state) => const MaterialPage(child: BookingsPage()),
          ),
          GoRoute(
            path: '/bookings/create',
            name: 'booking_create',
            pageBuilder: (context, state) {
              final professionalId = state.uri.queryParameters['professional_id'] ?? '';
              final serviceName = state.uri.queryParameters['service_name'];
              final serviceId = state.uri.queryParameters['service_id'];
              return MaterialPage(
                child: BookingCreatePage(
                  professionalId: professionalId,
                  serviceName: serviceName,
                  serviceId: serviceId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/bookings/:id',
            name: 'booking_detail',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return MaterialPage(child: BookingDetailPage(bookingId: id));
            },
          ),
          GoRoute(
            path: '/reviews/create',
            name: 'review_create',
            pageBuilder: (context, state) {
              final professionalId = state.uri.queryParameters['professional_id'] ?? '';
              final professionalName = state.uri.queryParameters['professional_name'];
              final bookingId = state.uri.queryParameters['booking_id'];
              return MaterialPage(
                child: ReviewCreatePage(
                  professionalId: professionalId,
                  professionalName: professionalName,
                  bookingId: bookingId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/quotes',
            name: 'quotes',
            pageBuilder: (context, state) => const MaterialPage(child: QuotesPage()),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            pageBuilder: (context, state) => const MaterialPage(child: MessagesPage()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const MaterialPage(child: ProfilePage()),
          ),
          GoRoute(
            path: '/profile/professional',
            name: 'professional_profile',
            pageBuilder: (context, state) => const MaterialPage(child: ProfessionalProfilePage()),
          ),
        ],
      ),
    ],
  );
});
