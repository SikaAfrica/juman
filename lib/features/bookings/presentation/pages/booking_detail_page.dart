import 'package:flutter/material.dart';
import '../../../../core/widgets/djuman_app_bar.dart';

class BookingDetailPage extends StatelessWidget {
  final String bookingId;
  
  const BookingDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DjumanAppBar(
        title: 'Détail de la réservation',
      ),
      body: Center(
        child: Text('Réservation: $bookingId'),
      ),
    );
  }
}
