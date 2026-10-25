class FareEstimateModel {
  final double baseFare;
  final double extraMinuteRate;
  final int estimatedDurationMinutes;
  final double estimatedDistanceKm;
  final double nightCharges;
  final double taxes;
  final double discount;
  final double totalFare;
  final String currency;

  double get nightCharge => nightCharges;

  const FareEstimateModel({
    required this.baseFare,
    required this.extraMinuteRate,
    required this.estimatedDurationMinutes,
    required this.estimatedDistanceKm,
    required this.nightCharges,
    required this.taxes,
    required this.discount,
    required this.totalFare,
    this.currency = 'USD',
  });

  factory FareEstimateModel.fromJson(Map<String, dynamic> json) {
    return FareEstimateModel(
      baseFare: (json['base_fare'] as num?)?.toDouble() ?? 25.0,
      extraMinuteRate: (json['extra_minute_rate'] as num?)?.toDouble() ?? 0.20,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int? ?? 120,
      estimatedDistanceKm: (json['estimated_distance_km'] as num?)?.toDouble() ?? 20.0,
      nightCharges: (json['night_charges'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalFare: (json['total_fare'] as num?)?.toDouble() ?? 25.0,
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}
