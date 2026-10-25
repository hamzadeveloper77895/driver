import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/garage_state.dart';
import '../domain/vehicle_model.dart';

class GarageScreen extends ConsumerStatefulWidget {
  const GarageScreen({super.key});

  @override
  ConsumerState<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends ConsumerState<GarageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(garageNotifierProvider.notifier).fetchVehicles();
    });
  }

  void _showAddVehicleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _AddVehicleSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final garageState = ref.watch(garageNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Garage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddVehicleSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: garageState.isLoading && garageState.vehicles.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : garageState.vehicles.isEmpty
                ? EmptyStateView(
                    icon: Icons.directions_car_filled_outlined,
                    title: 'Your Garage is Empty',
                    message:
                        'Add your vehicle to ensure we match chauffeurs trained for your car transmission (Automatic or Manual).',
                    actionLabel: 'Add Your First Car',
                    onAction: _showAddVehicleSheet,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: AppColors.primaryLight),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Transmission matching ensures your driver is certified to drive your specific gearbox.',
                                style: TextStyle(fontSize: 12, color: AppColors.primaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...garageState.vehicles.map((veh) {
                        final isSelected = garageState.selectedVehicle?.id == veh.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            color: isSelected ? AppColors.primary.withOpacity(0.12) : null,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.08),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            onTap: () => ref.read(garageNotifierProvider.notifier).selectVehicle(veh),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.directions_car_filled_rounded,
                                    color: isSelected ? AppColors.primaryLight : AppColors.secondary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            veh.displayName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: veh.transmission == 'AUTOMATIC'
                                                  ? AppColors.secondary.withOpacity(0.2)
                                                  : AppColors.warning.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              veh.transmission,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: veh.transmission == 'AUTOMATIC'
                                                    ? AppColors.secondary
                                                    : AppColors.warning,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Plate: ${veh.plateNumber}${veh.fuelType != null ? " • ${veh.fuelType}" : ""}',
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight)
                                else
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textSecondary),
                                    onPressed: () => ref.read(garageNotifierProvider.notifier).deleteVehicle(veh.id),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      AppButton(
                        text: '+ Add Another Vehicle',
                        variant: AppButtonVariant.outline,
                        onPressed: _showAddVehicleSheet,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _AddVehicleSheet extends ConsumerStatefulWidget {
  const _AddVehicleSheet();

  @override
  ConsumerState<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends ConsumerState<_AddVehicleSheet> {
  final _brandController = TextEditingController(text: 'Honda');
  final _modelController = TextEditingController(text: 'City ZX');
  final _plateController = TextEditingController(text: 'KA01MJ9088');
  String _transmission = 'AUTOMATIC';
  String _fuelType = 'PETROL';
  bool _isLoading = false;

  Future<void> _save() async {
    if (_brandController.text.isEmpty || _modelController.text.isEmpty || _plateController.text.isEmpty) {
      return;
    }
    setState(() => _isLoading = true);
    final ok = await ref.read(garageNotifierProvider.notifier).addVehicle(
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          transmission: _transmission,
          plateNumber: _plateController.text.trim().toUpperCase(),
          fuelType: _fuelType,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Vehicle to Garage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _brandController,
                  decoration: const InputDecoration(labelText: 'Car Brand', hintText: 'e.g. Honda, Hyundai'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: 'Car Model', hintText: 'e.g. City, Creta'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'License Plate', hintText: 'e.g. KA01MJ9088'),
          ),
          const SizedBox(height: 18),
          const Text('Transmission (Crucial for Driver Match)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('AUTOMATIC')),
                  selected: _transmission == 'AUTOMATIC',
                  onSelected: (_) => setState(() => _transmission = 'AUTOMATIC'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('MANUAL')),
                  selected: _transmission == 'MANUAL',
                  onSelected: (_) => setState(() => _transmission = 'MANUAL'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Fuel Type', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['PETROL', 'DIESEL', 'ELECTRIC', 'CNG'].map((fuel) {
              return ChoiceChip(
                label: Text(fuel),
                selected: _fuelType == fuel,
                onSelected: (_) => setState(() => _fuelType = fuel),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Save Vehicle',
            isLoading: _isLoading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
