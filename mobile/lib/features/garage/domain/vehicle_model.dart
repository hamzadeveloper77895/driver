class VehicleModel {
  final String id;
  final String brand;
  final String model;
  final int? year;
  final String transmission; // MANUAL, AUTOMATIC
  final String fuelType;
  final String plateNumber;
  final String? color;
  final bool isDefault;

  String get displayName => '$brand $model';

  const VehicleModel({
    required this.id,
    required this.brand,
    required this.model,
    this.year,
    required this.transmission,
    this.fuelType = 'PETROL',
    required this.plateNumber,
    this.color,
    this.isDefault = false,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int?,
      transmission: json['transmission'] as String? ?? 'AUTOMATIC',
      fuelType: json['fuel_type'] as String? ?? 'PETROL',
      plateNumber: json['plate_number'] as String? ?? '',
      color: json['color'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'model': model,
    'year': year,
    'transmission': transmission,
    'fuel_type': fuelType,
    'plate_number': plateNumber,
    'color': color,
    'is_default': isDefault,
  };
}
