import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/djuman_app_bar.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../professionals/data/datasources/professionals_remote_datasource.dart';
import '../../../professionals/data/models/professional.dart';
import '../../../../core/services/api_service.dart';

class ProfessionalProfilePage extends ConsumerStatefulWidget {
  const ProfessionalProfilePage({super.key});

  @override
  ConsumerState<ProfessionalProfilePage> createState() => _ProfessionalProfilePageState();
}

class _ProfessionalProfilePageState extends ConsumerState<ProfessionalProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _cityController = TextEditingController();
  final _communeController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  Professional? _professional;
  String? _errorMessage;
  List<ServiceCategory> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _loadProfessionalProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _experienceYearsController.dispose();
    _cityController.dispose();
    _communeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfessionalProfile() async {
    final authState = ref.watch(authProvider);
    final userId = authState.userId;

    if (userId == null) {
      setState(() {
        _errorMessage = 'Vous devez être connecté';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService.instance;
      final datasource = ProfessionalsRemoteDatasource(apiService);

      final professional = await datasource.getMyProfessionalProfile(userId);

      if (professional != null) {
        setState(() {
          _professional = professional;
          _displayNameController.text = professional.displayName;
          _businessNameController.text = professional.businessName ?? '';
          _descriptionController.text = professional.description;
          _phoneController.text = professional.phone;
          _emailController.text = professional.email ?? '';
          _whatsappController.text = professional.whatsapp ?? '';
          _experienceYearsController.text = professional.experienceYears.toString();
          _cityController.text = professional.location['city'] ?? '';
          _communeController.text = professional.location['commune'] ?? '';
          _selectedCategories = professional.categories;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Aucun profil professionnel trouvé. Créez-en un.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.watch(authProvider);
    final userId = authState.userId;

    if (userId == null) {
      setState(() {
        _errorMessage = 'Vous devez être connecté';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService.instance;
      final datasource = ProfessionalsRemoteDatasource(apiService);

      final location = {
        'city': _cityController.text.trim(),
        'commune': _communeController.text.trim(),
      };

      if (_professional == null) {
        // Créer un nouveau profil
        final professionalCreate = ProfessionalCreate(
          displayName: _displayNameController.text.trim(),
          businessName: _businessNameController.text.trim().isEmpty
              ? null
              : _businessNameController.text.trim(),
          description: _descriptionController.text.trim(),
          categories: _selectedCategories,
          location: location,
          serviceArea: [_cityController.text.trim()],
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          whatsapp: _whatsappController.text.trim().isEmpty
              ? null
              : _whatsappController.text.trim(),
          experienceYears: int.tryParse(_experienceYearsController.text) ?? 0,
        );

        await datasource.createProfessional(userId, professionalCreate);
      } else {
        // Mettre à jour le profil existant
        final professionalUpdate = ProfessionalUpdate(
          displayName: _displayNameController.text.trim(),
          businessName: _businessNameController.text.trim().isEmpty
              ? null
              : _businessNameController.text.trim(),
          description: _descriptionController.text.trim(),
          categories: _selectedCategories,
          location: location,
          serviceArea: [_cityController.text.trim()],
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          whatsapp: _whatsappController.text.trim().isEmpty
              ? null
              : _whatsappController.text.trim(),
          experienceYears: int.tryParse(_experienceYearsController.text),
        );

        await datasource.updateProfessional(_professional!.id, professionalUpdate);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil enregistré avec succès')),
        );
        await _loadProfessionalProfile();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DjumanAppBar(title: 'Mon profil professionnel'),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _professional == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfessionalProfile,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Nom d'affichage
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'affichage *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ce champ est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Nom de l'entreprise
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'entreprise (optionnel)',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                hintText: 'Décrivez vos services et votre expertise...',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ce champ est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Catégories
            const Text('Catégories *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ServiceCategory.values.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(_getCategoryDisplayName(category)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Ville
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Ville *',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ce champ est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Commune
            TextFormField(
              controller: _communeController,
              decoration: const InputDecoration(
                labelText: 'Commune (optionnel)',
                prefixIcon: Icon(Icons.place),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Téléphone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ce champ est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optionnel)',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // WhatsApp
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'WhatsApp (optionnel)',
                prefixIcon: Icon(Icons.chat),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Années d'expérience
            TextFormField(
              controller: _experienceYearsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Années d\'expérience',
                prefixIcon: Icon(Icons.work_history),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Bouton sauvegarder
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enregistrer mon profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.plumber:
        return 'Plombier';
      case ServiceCategory.electrician:
        return 'Électricien';
      case ServiceCategory.mason:
        return 'Maçon';
      case ServiceCategory.carpenter:
        return 'Menuisier';
      case ServiceCategory.painter:
        return 'Peintre';
      case ServiceCategory.mechanic:
        return 'Mécanicien';
      case ServiceCategory.hairdresser:
        return 'Coiffeur';
      case ServiceCategory.tutor:
        return 'Répétiteur';
      case ServiceCategory.housekeeper:
        return 'Ménage';
      case ServiceCategory.gardening:
        return 'Jardinage';
      default:
        return category.name;
    }
  }
}
