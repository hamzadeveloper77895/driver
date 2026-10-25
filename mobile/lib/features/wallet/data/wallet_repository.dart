import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/wallet_model.dart';

abstract class WalletRepository {
  Future<WalletModel> getWallet();
  Future<WalletModel> topUp(double amount);
}

class WalletRepositoryImpl implements WalletRepository {
  final Dio _dio = ApiClient().dio;

  @override
  Future<WalletModel> getWallet() async {
    final response = await _dio.get('/wallet');
    return WalletModel.fromJson(response.data);
  }

  @override
  Future<WalletModel> topUp(double amount) async {
    final response = await _dio.post('/wallet/top-up', data: {'amount': amount});
    return WalletModel.fromJson(response.data);
  }
}

class MockWalletRepository implements WalletRepository {
  WalletModel _wallet = const WalletModel(balance: 100.0, currency: 'USD');

  @override
  Future<WalletModel> getWallet() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _wallet;
  }

  @override
  Future<WalletModel> topUp(double amount) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _wallet = WalletModel(
      balance: _wallet.balance + amount,
      currency: 'USD',
      transactions: [
        WalletTransactionModel(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          transactionType: 'CREDIT',
          description: 'Wallet Top-Up via Card',
          createdAt: DateTime.now().toIso8601String(),
        ),
        ..._wallet.transactions,
      ],
    );
    return _wallet;
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return ApiConstants.useMockData ? MockWalletRepository() : WalletRepositoryImpl();
});
