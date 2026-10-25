import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/garage_repository.dart';
import 'vehicle_model.dart';

class GarageState {
  final List<VehicleModel> vehicles;
  final VehicleModel? selectedVehicle;
  final bool isLoading;
  final String? errorMessage;

  const GarageState({
    this.vehicles = const [],
    this.selectedVehicle,
    this.isLoading = false,
    this.errorMessage,
  });

  GarageState copyWith({
    List<VehicleModel>? vehicles,
    VehicleModel? selectedVehicle,
    bool? isLoading,
    String? errorMessage,
  }) {
    return GarageState(
      vehicles: vehicles ?? this.vehicles,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class GarageNotifier extends StateNotifier<GarageState> {
  final GarageRepository _repo;

  GarageNotifier(this._repo) : super(const GarageState()) {
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getVehicles();
      VehicleModel? defaultVeh;
      if (list.isNotEmpty) {
        defaultVeh = list.firstWhere((v) => v.isDefault, orElse: () => list.first);
      }
      state = state.copyWith(
        vehicles: list,
        selectedVehicle: defaultVeh,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectVehicle(VehicleModel vehicle) {
    state = state.copyWith(selectedVehicle: vehicle);
  }

  Future<bool> addVehicle({
    required String brand,
    required String model,
    int? year,
    required String transmission,
    required String plateNumber,
    String? fuelType,
    String? color,
  }) async {
    try {
      state = state.copyWith(isLoading: true);
      final newVeh = await _repo.addVehicle(
        brand: brand,
        model: model,
        year: year,
        transmission: transmission,
        plateNumber: plateNumber,
        fuelType: fuelType,
        color: color,
      );
      final updatedList = [newVeh, ...state.vehicles];
      state = state.copyWith(
        vehicles: updatedList,
        selectedVehicle: state.selectedVehicle ?? newVeh,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      await _repo.deleteVehicle(id);
      final updated = state.vehicles.where((v) => v.id != id).toList();
      state = state.copyWith(
        vehicles: updated,
        selectedVehicle: state.selectedVehicle?.id == id
            ? (updated.isNotEmpty ? updated.first : null)
            : state.selectedVehicle,
      );
    } catch (_) {}
  }
}

final garageNotifierProvider = StateNotifierProvider<GarageNotifier, GarageState>((ref) {
  final repo = ref.watch(garageRepositoryProvider);
  return GarageNotifier(repo);
});
