import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wallet_repository.dart';
import 'wallet_model.dart';

class WalletState {
  final WalletModel? wallet;
  final bool isLoading;
  final String? errorMessage;

  const WalletState({
    this.wallet,
    this.isLoading = false,
    this.errorMessage,
  });

  WalletState copyWith({
    WalletModel? wallet,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repo;

  WalletNotifier(this._repo) : super(const WalletState()) {
    fetchWallet();
  }

  Future<void> fetchWallet() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final w = await _repo.getWallet();
      state = state.copyWith(wallet: w, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> topUp(double amount) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repo.topUp(amount);
      state = state.copyWith(wallet: updated, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final walletNotifierProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return WalletNotifier(repo);
});
