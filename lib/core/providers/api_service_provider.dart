import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final dioProvider = Provider<Dio>((ref) {
  return ApiService.instance.dio;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService.instance;
});
