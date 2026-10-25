import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../booking/domain/booking_model.dart';

abstract class DriverRepository {
  Future<void> setDutyStatus(String status);
  Future<void> sendTelemetry(double lat, double lng, {double bearing = 0.0, double speed = 0.0});
  Future<Map<String, dynamic>?> getPendingOffer();
  Future<BookingModel> respondOffer(String bookingId, bool accept);
  Future<BookingModel> arriveAtPickup(String bookingId);
  Future<BookingModel> startTrip(String bookingId, String otp);
  Future<BookingModel> completeTrip(String bookingId);
  Future<Map<String, dynamic>> getEarnings();
}

class DriverRepositoryImpl implements DriverRepository {
  final Dio _dio = ApiClient().dio;

  @override
  Future<void> setDutyStatus(String status) async {
    await _dio.put('/driver/duty-status', data: {'duty_status': status});
  }

  @override
  Future<void> sendTelemetry(double lat, double lng, {double bearing = 0.0, double speed = 0.0}) async {
    await _dio.post('/driver/telemetry', data: {
      'latitude': lat,
      'longitude': lng,
      'bearing': bearing,
      'speed': speed,
    });
  }

  @override
  Future<Map<String, dynamic>?> getPendingOffer() async {
    final response = await _dio.get('/driver/offers');
    return response.data['offer'] as Map<String, dynamic>?;
  }

  @override
  Future<BookingModel> respondOffer(String bookingId, bool accept) async {
    final response = await _dio.post('/driver/offers/$bookingId/respond?accept=$accept');
    return BookingModel.fromJson(response.data);
  }

  @override
  Future<BookingModel> arriveAtPickup(String bookingId) async {
    final response = await _dio.post('/driver/trips/$bookingId/arrive');
    return BookingModel.fromJson(response.data);
  }

  @override
  Future<BookingModel> startTrip(String bookingId, String otp) async {
    final response = await _dio.post('/driver/trips/$bookingId/start', data: {'otp': otp});
    return BookingModel.fromJson(response.data);
  }

  @override
  Future<BookingModel> completeTrip(String bookingId) async {
    final response = await _dio.post('/driver/trips/$bookingId/complete');
    return BookingModel.fromJson(response.data);
  }

  @override
  Future<Map<String, dynamic>> getEarnings() async {
    final response = await _dio.get('/driver/earnings');
    return response.data as Map<String, dynamic>;
  }
}

class MockDriverRepository implements DriverRepository {
  @override
  Future<void> setDutyStatus(String status) async {}

  @override
  Future<void> sendTelemetry(double lat, double lng, {double bearing = 0.0, double speed = 0.0}) async {}

  @override
  Future<Map<String, dynamic>?> getPendingOffer() async => null;

  @override
  Future<BookingModel> respondOffer(String bookingId, bool accept) async {
    throw UnimplementedError();
  }

  @override
  Future<BookingModel> arriveAtPickup(String bookingId) async {
    throw UnimplementedError();
  }

  @override
  Future<BookingModel> startTrip(String bookingId, String otp) async {
    throw UnimplementedError();
  }

  @override
  Future<BookingModel> completeTrip(String bookingId) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getEarnings() async => {'trips_completed': 4, 'total_earnings': 125.0, 'currency': 'USD'};
}

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return ApiConstants.useMockData ? MockDriverRepository() : DriverRepositoryImpl();
});
