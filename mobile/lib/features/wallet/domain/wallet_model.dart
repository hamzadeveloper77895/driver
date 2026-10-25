class WalletTransactionModel {
  final String id;
  final double amount;
  final String transactionType;
  final String description;
  final String createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionType: json['transaction_type'] as String? ?? 'CREDIT',
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class WalletModel {
  final double balance;
  final String currency;
  final List<WalletTransactionModel> transactions;

  const WalletModel({
    required this.balance,
    this.currency = 'USD',
    this.transactions = const [],
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final list = json['transactions'] as List<dynamic>? ?? [];
    return WalletModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      transactions: list.map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
