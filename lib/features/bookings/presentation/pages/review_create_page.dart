import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/djuman_app_bar.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../data/datasources/bookings_remote_datasource.dart';
import '../../data/models/review.dart';
import '../../../../core/services/api_service.dart';

class ReviewCreatePage extends ConsumerStatefulWidget {
  final String professionalId;
  final String? professionalName;
  final String? bookingId;

  const ReviewCreatePage({
    super.key,
    required this.professionalId,
    this.professionalName,
    this.bookingId,
  });

  @override
  ConsumerState<ReviewCreatePage> createState() => _ReviewCreatePageState();
}

class _ReviewCreatePageState extends ConsumerState<ReviewCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  int _rating = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rating == 0) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une note';
      });
      return;
    }

    final authState = ref.watch(authProvider);
    final reviewerId = authState.userId;

    if (reviewerId == null || reviewerId.isEmpty) {
      setState(() {
        _errorMessage = 'Vous devez être connecté pour laisser un avis';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService.instance;
      final datasource = BookingsRemoteDatasource(apiService);

      final reviewCreate = ReviewCreate(
        professionalId: widget.professionalId,
        bookingId: widget.bookingId ?? '',
        rating: _rating,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      await datasource.createReview(reviewerId, reviewCreate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avis envoyé avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DjumanAppBar(title: 'Laisser un avis'),
      body: SingleChildScrollView(
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
              // Professional info
              if (widget.professionalName != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.professionalName!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Rating
              const Text(
                'Note',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _getRatingText(_rating),
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              // Comment
              TextFormField(
                controller: _commentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                  prefixIcon: Icon(Icons.comment),
                  border: OutlineInputBorder(),
                  hintText: 'Partagez votre expérience...',
                ),
              ),
              const SizedBox(height: 24),
              // Bouton submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Envoyer mon avis'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Médiocre';
      case 2:
        return 'Décevant';
      case 3:
        return 'Correct';
      case 4:
        return 'Très bien';
      case 5:
        return 'Excellent';
      default:
        return 'Sélectionnez une note';
    }
  }
}
