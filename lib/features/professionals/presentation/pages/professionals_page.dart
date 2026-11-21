import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/djuman_app_bar.dart';
import '../../../../core/services/api_service.dart';
import '../../data/datasources/professionals_remote_datasource.dart';
import '../../data/models/professional.dart';

class ProfessionalsPage extends ConsumerStatefulWidget {
  const ProfessionalsPage({super.key});

  @override
  ConsumerState<ProfessionalsPage> createState() => _ProfessionalsPageState();
}

class _ProfessionalsPageState extends ConsumerState<ProfessionalsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _communeController = TextEditingController();

  String? _selectedCategory;
  bool _verifiedOnly = false;
  bool _isSearching = false;
  List<Professional> _professionals = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    _communeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfessionals({bool useSearch = false}) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService.instance;
      final datasource = ProfessionalsRemoteDatasource(apiService);

      List<Professional> professionals;

      if (useSearch && _searchController.text.trim().isNotEmpty) {
        // Utiliser la recherche textuelle
        professionals = await datasource.searchProfessionals(
          query: _searchController.text.trim(),
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          limit: 50,
        );
      } else {
        // Utiliser les filtres
        professionals = await datasource.getProfessionals(
          category: _selectedCategory,
          city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
          commune: _communeController.text.trim().isEmpty ? null : _communeController.text.trim(),
          verifiedOnly: _verifiedOnly,
          limit: 50,
        );
      }

      setState(() {
        _professionals = professionals;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DjumanAppBar(
        title: 'Professionnels',
        actions: [
          IconButton(
            icon: const Icon(Icons.location_searching),
            onPressed: () {
              // TODO: Naviguer vers NearbyProfessionalsPage
            },
            tooltip: 'À proximité',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildFilters(),
          const Divider(height: 1),
          // Liste des professionnels
          Expanded(
            child: _buildContent(),
          ),
        ],
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
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un professionnel...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadProfessionals();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (_) => _loadProfessionals(useSearch: true),
          ),
          const SizedBox(height: 12),
          // Filtres avancés
          ExpansionTile(
            title: const Text('Filtres avancés'),
            leading: const Icon(Icons.filter_list),
            children: [
              // Ville
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Commune
              TextField(
                controller: _communeController,
                decoration: const InputDecoration(
                  labelText: 'Commune',
                  prefixIcon: Icon(Icons.place),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Catégorie
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Toutes')),
                  DropdownMenuItem(value: 'plumber', child: Text('Plombier')),
                  DropdownMenuItem(value: 'electrician', child: Text('Électricien')),
                  DropdownMenuItem(value: 'mason', child: Text('Maçon')),
                  DropdownMenuItem(value: 'mechanic', child: Text('Mécanicien')),
                  DropdownMenuItem(value: 'hairdresser', child: Text('Coiffeur')),
                  DropdownMenuItem(value: 'tutor', child: Text('Répétiteur')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Vérifié uniquement
              CheckboxListTile(
                value: _verifiedOnly,
                title: const Text('Professionnels vérifiés uniquement'),
                onChanged: (value) {
                  setState(() {
                    _verifiedOnly = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Bouton appliquer
              ElevatedButton(
                onPressed: () => _loadProfessionals(),
                child: const Text('Appliquer les filtres'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadProfessionals(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_professionals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Aucun professionnel trouvé'),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            professional.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (professional.isVerified)
                          const Icon(Icons.verified, color: Colors.blue, size: 20),
                      ],
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
                    const SizedBox(height: 4),
                    if (professional.location['city'] != null)
                      Text(
                        professional.location['city'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
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
                          '(${professional.reviewCount} avis)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
