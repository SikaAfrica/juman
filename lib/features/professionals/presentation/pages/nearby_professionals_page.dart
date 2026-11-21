import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/widgets/djuman_app_bar.dart';
import '../../data/datasources/professionals_remote_datasource.dart';
import '../../data/models/professional.dart';
import '../../../../core/services/api_service.dart';

class NearbyProfessionalsPage extends ConsumerStatefulWidget {
  const NearbyProfessionalsPage({super.key});

  @override
  ConsumerState<NearbyProfessionalsPage> createState() =>
      _NearbyProfessionalsPageState();
}

class _NearbyProfessionalsPageState
    extends ConsumerState<NearbyProfessionalsPage> {
  double _radiusKm = 10;
  String? _selectedCategory;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isLoadingProfessionals = false;
  List<Professional> _professionals = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      // Vérifier les permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Le service de localisation est désactivé';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Permission de localisation refusée';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Permission de localisation refusée définitivement';
          _isLoadingLocation = false;
        });
        return;
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // Charger les professionnels à proximité
      _loadNearbyProfessionals();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadNearbyProfessionals() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoadingProfessionals = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService.instance;
      final datasource = ProfessionalsRemoteDatasource(apiService);

      final professionals = await datasource.getNearbyProfessionals(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        radiusKm: _radiusKm,
        category: _selectedCategory,
        limit: 50,
      );

      setState(() {
        _professionals = professionals;
        _isLoadingProfessionals = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur chargement professionnels: $e';
        _isLoadingProfessionals = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DjumanAppBar(title: 'À proximité'),
      body: Column(
        children: [
          // Filtres
          _buildFilters(),
          const Divider(height: 1),
          // Liste des professionnels
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rayon de recherche
          Row(
            children: [
              const Icon(Icons.radio_button_unchecked, size: 20),
              const SizedBox(width: 8),
              const Text('Rayon: '),
              Expanded(
                child: Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '${_radiusKm.toInt()} km',
                  onChanged: (value) {
                    setState(() {
                      _radiusKm = value;
                    });
                    _loadNearbyProfessionals();
                  },
                ),
              ),
              Text('${_radiusKm.toInt()} km'),
            ],
          ),
          const SizedBox(height: 12),
          // Catégorie (placeholder - à implémenter avec liste des catégories)
          Row(
            children: [
              const Icon(Icons.category, size: 20),
              const SizedBox(width: 8),
              const Text('Catégorie: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedCategory,
                hint: const Text('Toutes'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Toutes')),
                  DropdownMenuItem(value: 'plumber', child: Text('Plombier')),
                  DropdownMenuItem(value: 'electrician', child: Text('Électricien')),
                  DropdownMenuItem(value: 'mechanic', child: Text('Mécanicien')),
                  DropdownMenuItem(value: 'hairdresser', child: Text('Coiffeur')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                  _loadNearbyProfessionals();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Obtention de votre position...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_isLoadingProfessionals) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_professionals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Aucun professionnel à proximité'),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'augmenter le rayon de recherche',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _professionals.length,
      itemBuilder: (context, index) {
        final professional = _professionals[index];
        return _ProfessionalCard(professional: professional);
      },
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final Professional professional;

  const _ProfessionalCard({super.key, required this.professional});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Naviguer vers le détail du professionnel
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo
              CircleAvatar(
                radius: 32,
                backgroundImage: professional.photoUrl != null
                    ? NetworkImage(professional.photoUrl!)
                    : null,
                child: professional.photoUrl == null
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
              const SizedBox(width: 16),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professional.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (professional.businessName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        professional.businessName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          professional.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${professional.reviewCount} avis]',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge vérifié
              if (professional.isVerified)
                const Icon(Icons.verified, color: Colors.blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
