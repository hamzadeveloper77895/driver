import '../../garage/domain/vehicle_model.dart';

class DriverSummaryModel {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String phone;
  final double ratingAverage;
  final int totalTrips;
  final double? currentLat;
  final double? currentLng;

  double get rating => ratingAverage;

  const DriverSummaryModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.phone,
    required this.ratingAverage,
    required this.totalTrips,
    this.currentLat,
    this.currentLng,
  });

  factory DriverSummaryModel.fromJson(Map<String, dynamic> json) {
    return DriverSummaryModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Chauffeur',
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String? ?? '',
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 5.0,
      totalTrips: json['total_trips'] as int? ?? 0,
      currentLat: (json['current_lat'] as num?)?.toDouble(),
      currentLng: (json['current_lng'] as num?)?.toDouble(),
    );
  }
}

class BookingModel {
  final String id;
  final String bookingCode;
  final String customerId;
  final String? driverId;
  final String vehicleId;
  final String serviceType;
  final String bookingType;
  final String status;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String? dropAddress;
  final double? dropLat;
  final double? dropLng;
  final String? startOtp;
  final String? tripStartTime;
  final String? tripEndTime;
  final double estimatedFare;
  final double? finalFare;
  final String paymentMode;
  final String paymentStatus;
  final bool emergencySosTriggered;
  final DriverSummaryModel? driver;
  final VehicleModel? vehicle;

  String get dropoffAddress => dropAddress ?? 'Destination';
  double get totalFare => finalFare ?? estimatedFare;
  String get paymentMethod => paymentMode;
  int get durationHours => 2;

  const BookingModel({
    required this.id,
    required this.bookingCode,
    required this.customerId,
    this.driverId,
    required this.vehicleId,
    required this.serviceType,
    required this.bookingType,
    required this.status,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    this.dropAddress,
    this.dropLat,
    this.dropLng,
    this.startOtp,
    this.tripStartTime,
    this.tripEndTime,
    required this.estimatedFare,
    this.finalFare,
    this.paymentMode = 'WALLET',
    this.paymentStatus = 'PENDING',
    this.emergencySosTriggered = false,
    this.driver,
    this.vehicle,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String? ?? '',
      bookingCode: json['booking_code'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      driverId: json['driver_id'] as String?,
      vehicleId: json['vehicle_id'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? 'HOURLY_LOCAL',
      bookingType: json['booking_type'] as String? ?? 'NOW',
      status: json['status'] as String? ?? 'PENDING',
      pickupAddress: json['pickup_address'] as String? ?? '',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? 0.0,
      dropAddress: json['drop_address'] as String?,
      dropLat: (json['drop_lat'] as num?)?.toDouble(),
      dropLng: (json['drop_lng'] as num?)?.toDouble(),
      startOtp: json['start_otp'] as String?,
      tripStartTime: json['trip_start_time'] as String?,
      tripEndTime: json['trip_end_time'] as String?,
      estimatedFare: (json['estimated_fare'] as num?)?.toDouble() ?? 0.0,
      finalFare: (json['final_fare'] as num?)?.toDouble(),
      paymentMode: json['payment_mode'] as String? ?? 'WALLET',
      paymentStatus: json['payment_status'] as String? ?? 'PENDING',
      emergencySosTriggered: json['emergency_sos_triggered'] as bool? ?? false,
      driver: json['driver'] != null ? DriverSummaryModel.fromJson(json['driver'] as Map<String, dynamic>) : null,
      vehicle: json['vehicle'] != null ? VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>) : null,
    );
  }

  BookingModel copyWith({
    String? status,
    String? startOtp,
    DriverSummaryModel? driver,
    double? finalFare,
    String? paymentStatus,
    bool? emergencySosTriggered,
  }) {
    return BookingModel(
      id: id,
      bookingCode: bookingCode,
      customerId: customerId,
      driverId: driverId,
      vehicleId: vehicleId,
      serviceType: serviceType,
      bookingType: bookingType,
      status: status ?? this.status,
      pickupAddress: pickupAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropAddress: dropAddress,
      dropLat: dropLat,
      dropLng: dropLng,
      startOtp: startOtp ?? this.startOtp,
      tripStartTime: tripStartTime,
      tripEndTime: tripEndTime,
      estimatedFare: estimatedFare,
      finalFare: finalFare ?? this.finalFare,
      paymentMode: paymentMode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      emergencySosTriggered: emergencySosTriggered ?? this.emergencySosTriggered,
      driver: driver ?? this.driver,
      vehicle: vehicle,
    );
  }
}
