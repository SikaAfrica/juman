import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/djuman_app_bar.dart';

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({super.key});

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DjumanAppBar(
        title: 'Mes réservations',
      ),
      body: const Center(
        child: Text('Liste des réservations'),
      ),
    );
  }
}
