import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../booking/domain/booking_model.dart';
import '../data/driver_repository.dart';

class DriverState {
  final String dutyStatus; // 'ONLINE', 'OFFLINE', 'ON_TRIP'
  final Map<String, dynamic>? pendingOffer;
  final BookingModel? activeTrip;
  final Map<String, dynamic>? earnings;
  final bool isLoading;
  final String? errorMessage;

  const DriverState({
    this.dutyStatus = 'OFFLINE',
    this.pendingOffer,
    this.activeTrip,
    this.earnings,
    this.isLoading = false,
    this.errorMessage,
  });

  DriverState copyWith({
    String? dutyStatus,
    Map<String, dynamic>? pendingOffer,
    BookingModel? activeTrip,
    Map<String, dynamic>? earnings,
    bool? isLoading,
    String? errorMessage,
    bool clearPendingOffer = false,
    bool clearActiveTrip = false,
  }) {
    return DriverState(
      dutyStatus: dutyStatus ?? this.dutyStatus,
      pendingOffer: clearPendingOffer ? null : (pendingOffer ?? this.pendingOffer),
      activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      earnings: earnings ?? this.earnings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DriverNotifier extends StateNotifier<DriverState> {
  final DriverRepository _repo;
  Timer? _telemetryTimer;

  DriverNotifier(this._repo) : super(const DriverState()) {
    fetchEarnings();
  }

  Future<void> toggleDuty(bool goOnline) async {
    final newStatus = goOnline ? 'ONLINE' : 'OFFLINE';
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.setDutyStatus(newStatus);
      state = state.copyWith(dutyStatus: newStatus, isLoading: false);
      if (goOnline) {
        _startTelemetrySimulation();
      } else {
        _stopTelemetrySimulation();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _startTelemetrySimulation() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Default location around city center
      _repo.sendTelemetry(12.9716, 77.5946, bearing: 45.0, speed: 20.0);
    });
  }

  void _stopTelemetrySimulation() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
  }

  Future<void> checkOffers() async {
    try {
      final offer = await _repo.getPendingOffer();
      state = state.copyWith(pendingOffer: offer);
    } catch (_) {}
  }

  Future<BookingModel?> respondOffer(String bookingId, bool accept) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final booking = await _repo.respondOffer(bookingId, accept);
      state = state.copyWith(
        isLoading: false,
        clearPendingOffer: true,
        activeTrip: accept ? booking : null,
        dutyStatus: accept ? 'ON_TRIP' : 'ONLINE',
      );
      return booking;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> arriveAtPickup(String bookingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final booking = await _repo.arriveAtPickup(bookingId);
      state = state.copyWith(isLoading: false, activeTrip: booking);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> startTrip(String bookingId, String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final booking = await _repo.startTrip(bookingId, otp);
      state = state.copyWith(isLoading: false, activeTrip: booking);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Invalid OTP. Please check with customer.');
      return false;
    }
  }

  Future<bool> completeTrip(String bookingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final booking = await _repo.completeTrip(bookingId);
      state = state.copyWith(
        isLoading: false,
        activeTrip: booking,
        dutyStatus: 'ONLINE',
      );
      fetchEarnings();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> fetchEarnings() async {
    try {
      final earnings = await _repo.getEarnings();
      state = state.copyWith(earnings: earnings);
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopTelemetrySimulation();
    super.dispose();
  }
}

final driverNotifierProvider = StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  final repo = ref.watch(driverRepositoryProvider);
  return DriverNotifier(repo);
});
