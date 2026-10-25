import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import 'user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, newUser }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repo.getCurrentUser();
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> requestOtp(String phone, {String role = 'CUSTOMER'}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      await _repo.requestOtp(phone, role: role);
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp, {String role = 'CUSTOMER'}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      final user = await _repo.verifyOtp(phone, otp, role: role);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: 'Invalid OTP. Please try again.');
      return false;
    }
  }

  Future<bool> switchRole(String targetRole) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      final user = await _repo.switchRole(targetRole);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> updateProfile({String? fullName, String? email}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      final updated = await _repo.updateProfile(fullName: fullName, email: email);
      state = state.copyWith(status: AuthStatus.authenticated, user: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
