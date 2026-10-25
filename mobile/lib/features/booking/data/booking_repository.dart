import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/booking_model.dart';
import '../domain/fare_estimate_model.dart';

abstract class BookingRepository {
  Future<FareEstimateModel> getFareEstimate({
    required String serviceType,
    required double durationHours,
    required double pickupLat,
    required double pickupLng,
    double? dropLat,
    double? dropLng,
    String? promoCode,
  });

  Future<BookingModel> createBooking({
    required String vehicleId,
    required String serviceType,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    String? dropAddress,
    double? dropLat,
    double? dropLng,
    double durationHours = 2.0,
    String paymentMode = 'WALLET',
    String? promoCode,
  });

  Future<BookingModel?> getActiveBooking();
  Future<BookingModel> getBooking(String bookingId);
  Future<BookingModel> getBookingById(String bookingId) => getBooking(bookingId);
  Future<BookingModel> cancelBooking(String bookingId, {String? reason});
  Future<void> rateBooking(String bookingId, int stars, {List<String>? tags, String? review, double tip = 0.0});
  Future<void> triggerSos(String bookingId);
  Future<List<BookingModel>> getHistory();
  Future<List<BookingModel>> getBookingHistory() => getHistory();
}

class BookingRepositoryImpl implements BookingRepository {
  final Dio _dio = ApiClient().dio;

  @override
  Future<FareEstimateModel> getFareEstimate({
    required String serviceType,
    required double durationHours,
    required double pickupLat,
    required double pickupLng,
    double? dropLat,
    double? dropLng,
    String? promoCode,
  }) async {
    final response = await _dio.post('/pricing/estimate', data: {
      'service_type': serviceType,
      'duration_hours': durationHours,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      if (dropLat != null) 'drop_lat': dropLat,
      if (dropLng != null) 'drop_lng': dropLng,
      if (promoCode != null) 'promo_code': promoCode,
    });
    return FareEstimateModel.fromJson(response.data);
  }

  @override
  Future<BookingModel> createBooking({
    required String vehicleId,
    required String serviceType,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    String? dropAddress,
    double? dropLat,
    double? dropLng,
    double durationHours = 2.0,
    String paymentMode = 'WALLET',
    String? promoCode,
  }) async {
    final response = await _dio.post('/bookings', data: {
      'vehicle_id': vehicleId,
      'service_type': serviceType,
      'pickup_address': pickupAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      if (dropAddress != null) 'drop_address': dropAddress,
      if (dropLat != null) 'drop_lat': dropLat,
      if (dropLng != null) 'drop_lng': dropLng,
      'duration_hours': durationHours,
      'payment_mode': paymentMode,
      if (promoCode != null) 'promo_code': promoCode,
    });
    return BookingModel.fromJson(response.data);
  }

  @override
  Future<BookingModel?> getActiveBooking() async {
    try {
      final response = await _dio.get('/bookings/active');
      if (response.data == null) return null;
      return BookingModel.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BookingModel> getBooking(String bookingId) async {
    final response = await _dio.get('/bookings/$bookingId');
    return BookingModel.fromJson(response.data);
  }

  @override
  Future<BookingModel> cancelBooking(String bookingId, {String? reason}) async {
    final response = await _dio.post('/bookings/$bookingId/cancel', data: {'reason': reason ?? 'Cancelled by user'});
    return BookingModel.fromJson(response.data);
  }

  @override
  Future<void> rateBooking(String bookingId, int stars, {List<String>? tags, String? review, double tip = 0.0}) async {
    await _dio.post('/bookings/$bookingId/rate', data: {
      'stars': stars,
      'tags': tags ?? [],
      'review_text': review,
      'tip_amount': tip,
    });
  }

  @override
  Future<void> triggerSos(String bookingId) async {
    await _dio.post('/bookings/$bookingId/sos');
  }

  @override
  Future<BookingModel> getBookingById(String bookingId) => getBooking(bookingId);

  @override
  Future<List<BookingModel>> getHistory() async {
    final response = await _dio.get('/bookings/history');
    final list = response.data as List<dynamic>;
    return list.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<BookingModel>> getBookingHistory() => getHistory();
}

class MockBookingRepository implements BookingRepository {
  BookingModel? _activeBooking;

  @override
  Future<FareEstimateModel> getFareEstimate({
    required String serviceType,
    required double durationHours,
    required double pickupLat,
    required double pickupLng,
    double? dropLat,
    double? dropLng,
    String? promoCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const FareEstimateModel(
      baseFare: 25.0,
      extraMinuteRate: 0.20,
      estimatedDurationMinutes: 120,
      estimatedDistanceKm: 25.0,
      nightCharges: 0.0,
      taxes: 4.50,
      discount: 0.0,
      totalFare: 29.50,
    );
  }

  @override
  Future<BookingModel> createBooking({
    required String vehicleId,
    required String serviceType,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    String? dropAddress,
    double? dropLat,
    double? dropLng,
    double durationHours = 2.0,
    String paymentMode = 'WALLET',
    String? promoCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _activeBooking = BookingModel(
      id: 'mock-booking-${DateTime.now().millisecondsSinceEpoch}',
      bookingCode: 'BK-849201',
      customerId: 'mock-cust-1',
      vehicleId: vehicleId,
      serviceType: serviceType,
      bookingType: 'NOW',
      status: 'PENDING',
      pickupAddress: pickupAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropAddress: dropAddress,
      dropLat: dropLat,
      dropLng: dropLng,
      estimatedFare: 29.50,
      paymentMode: paymentMode,
      startOtp: '5824',
    );
    return _activeBooking!;
  }

  @override
  Future<BookingModel?> getActiveBooking() async {
    return _activeBooking;
  }

  @override
  Future<BookingModel> getBooking(String bookingId) async {
    return _activeBooking ??
        BookingModel(
          id: bookingId,
          bookingCode: 'BK-849201',
          customerId: 'mock-cust-1',
          vehicleId: 'car-1',
          serviceType: 'HOURLY_LOCAL',
          bookingType: 'NOW',
          status: 'IN_PROGRESS',
          pickupAddress: 'MG Road',
          pickupLat: 12.9716,
          pickupLng: 77.5946,
          estimatedFare: 29.50,
          startOtp: '5824',
          driver: const DriverSummaryModel(
            id: 'drv-1',
            fullName: 'Vikram Singh',
            phone: '+919876543201',
            ratingAverage: 4.95,
            totalTrips: 450,
            currentLat: 12.9720,
            currentLng: 77.5950,
          ),
        );
  }

  @override
  Future<BookingModel> cancelBooking(String bookingId, {String? reason}) async {
    _activeBooking = _activeBooking?.copyWith(status: 'CANCELLED');
    return _activeBooking!;
  }

  @override
  Future<void> rateBooking(String bookingId, int stars, {List<String>? tags, String? review, double tip = 0.0}) async {}

  @override
  Future<void> triggerSos(String bookingId) async {}

  @override
  Future<BookingModel> getBookingById(String bookingId) => getBooking(bookingId);

  @override
  Future<List<BookingModel>> getHistory() async {
    return [];
  }

  @override
  Future<List<BookingModel>> getBookingHistory() => getHistory();
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return ApiConstants.useMockData ? MockBookingRepository() : BookingRepositoryImpl();
});
