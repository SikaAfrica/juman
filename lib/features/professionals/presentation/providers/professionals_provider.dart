import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/professionals_remote_datasource.dart';
import '../../data/models/professional.dart';
import '../../../../core/services/api_service.dart';

final professionalsDatasourceProvider = Provider<ProfessionalsRemoteDatasource>((ref) {
  return ProfessionalsRemoteDatasource(ApiService.instance);
});

final professionalsListProvider = FutureProvider.family<List<Professional>, Map<String, dynamic>>((ref, params) async {
  final datasource = ref.watch(professionalsDatasourceProvider);
  return datasource.getProfessionals(
    category: params['category'],
    city: params['city'],
    search: params['search'],
    limit: params['limit'] ?? 20,
    offset: params['offset'] ?? 0,
  );
});

final professionalDetailProvider = FutureProvider.family<Professional?, String>((ref, id) async {
  final datasource = ref.watch(professionalsDatasourceProvider);
  return datasource.getProfessionalById(id);
});

final professionalServicesProvider = FutureProvider.family<List<dynamic>, String>((ref, professionalId) async {
  final datasource = ref.watch(professionalsDatasourceProvider);
  return datasource.getProfessionalServices(professionalId);
});
