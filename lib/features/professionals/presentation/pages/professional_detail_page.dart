import 'package:flutter/material.dart';
import '../../../../core/widgets/djuman_app_bar.dart';

class ProfessionalDetailPage extends StatelessWidget {
  final String professionalId;
  
  const ProfessionalDetailPage({super.key, required this.professionalId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DjumanAppBar(
        title: 'Détail du professionnel',
      ),
      body: Center(
        child: Text('Profil: $professionalId'),
      ),
    );
  }
}
