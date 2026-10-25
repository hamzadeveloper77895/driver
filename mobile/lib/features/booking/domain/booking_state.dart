import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants/api_constants.dart';
import '../data/booking_repository.dart';
import 'booking_model.dart';
import 'fare_estimate_model.dart';

class BookingState {
  final FareEstimateModel? estimate;
  final BookingModel? activeBooking;
  final List<BookingModel> history;
  final bool isLoading;
  final String? errorMessage;
  final List<String> chatMessages;

  double? get driverLat => activeBooking?.driver?.currentLat;
  double? get driverLng => activeBooking?.driver?.currentLng;
  double get driverBearing => 45.0;

  const BookingState({
    this.estimate,
    this.activeBooking,
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
    this.chatMessages = const [],
  });

  BookingState copyWith({
    FareEstimateModel? estimate,
    BookingModel? activeBooking,
    List<BookingModel>? history,
    bool? isLoading,
    String? errorMessage,
    List<String>? chatMessages,
  }) {
    return BookingState(
      estimate: estimate ?? this.estimate,
      activeBooking: activeBooking ?? this.activeBooking,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingRepository _repo;
  WebSocketChannel? _wsChannel;

  BookingNotifier(this._repo) : super(const BookingState()) {
    checkActiveBooking();
    fetchBookingHistory();
  }

  Future<void> fetchActiveBooking() => checkActiveBooking();

  Future<void> checkActiveBooking() async {
    try {
      final active = await _repo.getActiveBooking();
      if (active != null) {
        state = state.copyWith(activeBooking: active);
        _connectWebSocket(active.id);
      }
    } catch (_) {}
  }

  Future<void> fetchBookingById(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final b = await _repo.getBookingById(id);
      state = state.copyWith(activeBooking: b, isLoading: false);
      _connectWebSocket(id);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchBookingHistory() async {
    try {
      final list = await _repo.getBookingHistory();
      state = state.copyWith(history: list);
    } catch (_) {}
  }

  Future<void> fetchEstimate({
    required String serviceType,
    required int durationHours,
    required double pickupLat,
    required double pickupLng,
    double? dropLat,
    double? dropLng,
    String? promoCode,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final estimate = await _repo.getFareEstimate(
        serviceType: serviceType,
        durationHours: durationHours.toDouble(),
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropLat: dropLat,
        dropLng: dropLng,
        promoCode: promoCode,
      );
      state = state.copyWith(estimate: estimate, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to compute fare quote');
    }
  }

  Future<BookingModel?> createBooking({
    required String serviceType,
    required String carId,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    String? dropoffAddress,
    double? dropoffLat,
    double? dropoffLng,
    int durationHours = 2,
    String paymentMethod = 'WALLET',
    String? promoCode,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final booking = await _repo.createBooking(
        vehicleId: carId,
        serviceType: serviceType,
        pickupAddress: pickupAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropAddress: dropoffAddress,
        dropLat: dropoffLat,
        dropLng: dropoffLng,
        durationHours: durationHours.toDouble(),
        paymentMode: paymentMethod,
        promoCode: promoCode,
      );
      state = state.copyWith(activeBooking: booking, isLoading: false);
      _connectWebSocket(booking.id);
      return booking;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  void connectTripWebSocket(String bookingId) => _connectWebSocket(bookingId);

  void _connectWebSocket(String bookingId) {
    _wsChannel?.sink.close();
    try {
      final url = '${ApiConstants.wsBaseUrl}/ws/trips/$bookingId';
      _wsChannel = WebSocketChannel.connect(Uri.parse(url));
      _wsChannel?.stream.listen(
        (data) {
          try {
            final parsed = jsonDecode(data as String) as Map<String, dynamic>;
            final event = parsed['event'] as String?;
            final payload = parsed['data'] as Map<String, dynamic>?;

            if (payload != null && state.activeBooking != null) {
              if (event == 'HYDRATION_SNAPSHOT' || event == 'DRIVER_ASSIGNED' || event == 'DRIVER_ARRIVED' || event == 'TRIP_STARTED' || event == 'TRIP_COMPLETED') {
                final newStatus = payload['status'] as String? ?? state.activeBooking!.status;
                final otp = payload['start_otp'] as String? ?? state.activeBooking!.startOtp;
                state = state.copyWith(
                  activeBooking: state.activeBooking!.copyWith(
                    status: newStatus,
                    startOtp: otp,
                  ),
                );
              } else if (event == 'DRIVER_LOCATION_UPDATE') {
                final lat = (payload['latitude'] as num?)?.toDouble();
                final lng = (payload['longitude'] as num?)?.toDouble();
                if (lat != null && lng != null && state.activeBooking?.driver != null) {
                  final updatedDriver = DriverSummaryModel(
                    id: state.activeBooking!.driver!.id,
                    fullName: state.activeBooking!.driver!.fullName,
                    phone: state.activeBooking!.driver!.phone,
                    ratingAverage: state.activeBooking!.driver!.ratingAverage,
                    totalTrips: state.activeBooking!.driver!.totalTrips,
                    currentLat: lat,
                    currentLng: lng,
                  );
                  state = state.copyWith(
                    activeBooking: state.activeBooking!.copyWith(driver: updatedDriver),
                  );
                }
              } else if (event == 'NEW_CHAT_MESSAGE') {
                final msg = payload['message'] as String? ?? '';
                state = state.copyWith(chatMessages: [...state.chatMessages, msg]);
              }
            }
          } catch (_) {}
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  void sendChatMessage(String message) {
    if (_wsChannel != null && message.trim().isNotEmpty) {
      _wsChannel?.sink.add(jsonEncode({
        'event': 'CHAT_MESSAGE',
        'data': {
          'sender_id': state.activeBooking?.customerId ?? 'cust',
          'message': message.trim(),
        }
      }));
    }
  }

  Future<void> cancelBooking(String bookingId, [String? reason]) async {
    try {
      final cancelled = await _repo.cancelBooking(bookingId, reason: reason ?? 'Customer requested cancellation');
      state = state.copyWith(activeBooking: cancelled);
      _wsChannel?.sink.close();
    } catch (_) {}
  }

  Future<void> triggerSos() async {
    if (state.activeBooking == null) return;
    try {
      await _repo.triggerSos(state.activeBooking!.id);
      state = state.copyWith(
        activeBooking: state.activeBooking!.copyWith(emergencySosTriggered: true),
      );
    } catch (_) {}
  }

  Future<void> rateBooking(String bookingId, int stars, {String? comment, double? tip}) async {
    try {
      await _repo.rateBooking(bookingId, stars, review: comment, tip: tip ?? 0.0);
      state = state.copyWith(activeBooking: null);
      _wsChannel?.sink.close();
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    super.dispose();
  }
}

final bookingNotifierProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  return BookingNotifier(repo);
});
