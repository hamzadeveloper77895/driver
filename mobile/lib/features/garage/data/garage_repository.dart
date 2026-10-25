import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/vehicle_model.dart';

abstract class GarageRepository {
  Future<List<VehicleModel>> getVehicles();
  Future<VehicleModel> addVehicle({
    required String brand,
    required String model,
    int? year,
    required String transmission,
    required String plateNumber,
    String? fuelType,
    String? color,
  });
  Future<void> deleteVehicle(String id);
}

class GarageRepositoryImpl implements GarageRepository {
  final Dio _dio = ApiClient().dio;

  @override
  Future<List<VehicleModel>> getVehicles() async {
    final response = await _dio.get('/garage/vehicles');
    final list = response.data as List<dynamic>;
    return list.map((e) => VehicleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<VehicleModel> addVehicle({
    required String brand,
    required String model,
    int? year,
    required String transmission,
    required String plateNumber,
    String? fuelType,
    String? color,
  }) async {
    final response = await _dio.post('/garage/vehicles', data: {
      'brand': brand,
      'model': model,
      if (year != null) 'year': year,
      'transmission': transmission,
      'plate_number': plateNumber,
      if (fuelType != null) 'fuel_type': fuelType,
      if (color != null) 'color': color,
    });
    return VehicleModel.fromJson(response.data);
  }

  @override
  Future<void> deleteVehicle(String id) async {
    await _dio.delete('/garage/vehicles/$id');
  }
}

class MockGarageRepository implements GarageRepository {
  final List<VehicleModel> _vehicles = [
    const VehicleModel(
      id: 'mock-car-1',
      brand: 'Honda',
      model: 'City ZX',
      year: 2022,
      transmission: 'AUTOMATIC',
      fuelType: 'PETROL',
      plateNumber: 'KA01AB1234',
      color: 'White',
      isDefault: true,
    ),
    const VehicleModel(
      id: 'mock-car-2',
      brand: 'Hyundai',
      model: 'Creta SX',
      year: 2023,
      transmission: 'MANUAL',
      fuelType: 'DIESEL',
      plateNumber: 'KA05CD5678',
      color: 'Black',
      isDefault: false,
    ),
  ];

  @override
  Future<List<VehicleModel>> getVehicles() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_vehicles);
  }

  @override
  Future<VehicleModel> addVehicle({
    required String brand,
    required String model,
    int? year,
    required String transmission,
    required String plateNumber,
    String? fuelType,
    String? color,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final v = VehicleModel(
      id: 'car-${DateTime.now().millisecondsSinceEpoch}',
      brand: brand,
      model: model,
      year: year,
      transmission: transmission,
      fuelType: fuelType ?? 'PETROL',
      plateNumber: plateNumber,
      color: color,
    );
    _vehicles.add(v);
    return v;
  }

  @override
  Future<void> deleteVehicle(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _vehicles.removeWhere((v) => v.id == id);
  }
}

final garageRepositoryProvider = Provider<GarageRepository>((ref) {
  return ApiConstants.useMockData ? MockGarageRepository() : GarageRepositoryImpl();
});
