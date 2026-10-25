import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

abstract class AuthRepository {
  Future<void> requestOtp(String phone, {String role = 'CUSTOMER'});
  Future<UserModel> verifyOtp(String phone, String otp, {String role = 'CUSTOMER'});
  Future<UserModel> switchRole(String targetRole);
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateProfile({String? fullName, String? email, String? avatarUrl});
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> requestOtp(String phone, {String role = 'CUSTOMER'}) async {
    await _dio.post('/auth/request-otp', data: {'phone': phone, 'role': role});
  }

  @override
  Future<UserModel> verifyOtp(String phone, String otp, {String role = 'CUSTOMER'}) async {
    final response = await _dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'otp': otp,
      'role': role,
    });
    final data = response.data;
    await _storage.write(key: ApiConstants.keyAccessToken, value: data['access_token']);
    await _storage.write(key: ApiConstants.keyRefreshToken, value: data['refresh_token']);
    await _storage.write(key: ApiConstants.keyUserRole, value: data['user']['role']);
    return UserModel.fromJson(data['user']);
  }

  @override
  Future<UserModel> switchRole(String targetRole) async {
    final response = await _dio.post('/auth/switch-role', data: {'role': targetRole});
    final data = response.data;
    await _storage.write(key: ApiConstants.keyAccessToken, value: data['access_token']);
    await _storage.write(key: ApiConstants.keyRefreshToken, value: data['refresh_token']);
    await _storage.write(key: ApiConstants.keyUserRole, value: data['user']['role']);
    return UserModel.fromJson(data['user']);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserModel.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> updateProfile({String? fullName, String? email, String? avatarUrl}) async {
    final response = await _dio.put('/auth/me', data: {
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}

class MockAuthRepository implements AuthRepository {
  UserModel _currentUser = const UserModel(
    id: 'mock-user-123',
    phone: '+919876543210',
    fullName: 'Rahul Sharma',
    email: 'rahul@example.com',
    role: 'CUSTOMER',
  );

  @override
  Future<void> requestOtp(String phone, {String role = 'CUSTOMER'}) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<UserModel> verifyOtp(String phone, String otp, {String role = 'CUSTOMER'}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = UserModel(
      id: _currentUser.id,
      phone: _currentUser.phone,
      fullName: _currentUser.fullName,
      email: _currentUser.email,
      role: role,
    );
    return _currentUser;
  }

  @override
  Future<UserModel> switchRole(String targetRole) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = UserModel(
      id: _currentUser.id,
      phone: _currentUser.phone,
      fullName: _currentUser.fullName,
      email: _currentUser.email,
      role: targetRole,
    );
    return _currentUser;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }

  @override
  Future<UserModel> updateProfile({String? fullName, String? email, String? avatarUrl}) async {
    _currentUser = UserModel(
      id: _currentUser.id,
      phone: _currentUser.phone,
      fullName: fullName ?? _currentUser.fullName,
      email: email ?? _currentUser.email,
      avatarUrl: avatarUrl ?? _currentUser.avatarUrl,
      role: _currentUser.role,
    );
    return _currentUser;
  }

  @override
  Future<void> logout() async {}
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiConstants.useMockData ? MockAuthRepository() : AuthRepositoryImpl();
});
