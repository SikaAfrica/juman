import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../data/datasources/quotes_remote_datasource.dart';
import '../../data/models/quote.dart';

/// Provider pour le datasource Quotes
final quotesDatasourceProvider = Provider<QuotesRemoteDatasource>((ref) {
  final apiService = ApiService.instance;
  return QuotesRemoteDatasource(apiService);
});

/// Provider pour lister les demandes de devis de l'utilisateur
final myQuotesProvider = FutureProvider.family<List<Quote>, String>((ref, role) async {
  final authState = ref.watch(authProvider);
  final userId = authState.userId ?? '';
  
  if (userId.isEmpty) {
    return [];
  }
  
  final datasource = ref.watch(quotesDatasourceProvider);
  return datasource.listMyQuotes(userId, role);
});

/// Provider pour créer une demande de devis
class CreateQuoteNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final QuotesRemoteDatasource _datasource;

  CreateQuoteNotifier(this._datasource) : super(const AsyncValue.data({}));

  Future<void> createQuote(String clientId, QuoteRequest quoteRequest) async {
    state = const AsyncValue.loading();
    try {
      final result = await _datasource.createQuoteRequest(clientId, quoteRequest);
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final createQuoteProvider =
    StateNotifierProvider<CreateQuoteNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) {
    final datasource = ref.watch(quotesDatasourceProvider);
    return CreateQuoteNotifier(datasource);
  },
);

/// Provider pour répondre à une demande de devis
class RespondQuoteNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final QuotesRemoteDatasource _datasource;

  RespondQuoteNotifier(this._datasource) : super(const AsyncValue.data({}));

  Future<void> respondQuote(
    String professionalId,
    String quoteId,
    QuoteResponse quoteResponse,
  ) async {
    state = const AsyncValue.loading();
    try {
      final result =
          await _datasource.respondQuote(professionalId, quoteId, quoteResponse);
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final respondQuoteProvider =
    StateNotifierProvider<RespondQuoteNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) {
    final datasource = ref.watch(quotesDatasourceProvider);
    return RespondQuoteNotifier(datasource);
  },
);
