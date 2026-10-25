import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: ApiConstants.keyAccessToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshToken = await _storage.read(key: ApiConstants.keyRefreshToken);
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
                final refreshResponse = await refreshDio.post(
                  '/auth/refresh-token',
                  data: {'refresh_token': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['access_token'];
                  final newRefreshToken = refreshResponse.data['refresh_token'];
                  await _storage.write(key: ApiConstants.keyAccessToken, value: newAccessToken);
                  await _storage.write(key: ApiConstants.keyRefreshToken, value: newRefreshToken);

                  // Retry the original failed request with the fresh token
                  error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final cloneReq = await dio.fetch(error.requestOptions);
                  return handler.resolve(cloneReq);
                }
              } catch (_) {
                await _storage.deleteAll();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}
