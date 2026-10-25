import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/glass_card.dart';

class MapPinPickerScreen extends StatefulWidget {
  const MapPinPickerScreen({super.key});

  @override
  State<MapPinPickerScreen> createState() => _MapPinPickerScreenState();
}

class _MapPinPickerScreenState extends State<MapPinPickerScreen> {
  String _currentResolvedAddress = '100 Feet Rd, HAL 2nd Stage, Indiranagar, Bengaluru';
  bool _isGeocoding = false;

  void _onMapMoved() {
    setState(() => _isGeocoding = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
          _currentResolvedAddress = 'Selected Pin Location (Indiranagar Metro Station)';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose on Map'),
      ),
      body: Stack(
        children: [
          // Map Canvas Placeholder with Drag Gestures
          GestureDetector(
            onPanEnd: (_) => _onMapMoved(),
            child: Container(
              color: const Color(0xFF0F172A),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: _PickerMapPainter(),
                  ),
                  // Center Pin Icon
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                            ],
                          ),
                          child: const Text(
                            'Drag map to position pin',
                            style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Icon(Icons.location_pin, size: 48, color: AppColors.primaryLight),
                        Container(
                          width: 8,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 48), // offset for pin tip
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Recenter GPS Button
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton.small(
              backgroundColor: AppColors.surface,
              onPressed: () {
                setState(() {
                  _currentResolvedAddress = 'Current GPS: Indiranagar 100ft Rd, Bengaluru';
                });
              },
              child: const Icon(Icons.my_location_rounded, color: AppColors.primaryLight),
            ),
          ),

          // Bottom Confirmation Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fmd_good_rounded, color: AppColors.secondary, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Location Details',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      if (_isGeocoding)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentResolvedAddress,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: 'Confirm Location',
                    onPressed: () {
                      Navigator.of(context).pop(_currentResolvedAddress);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 6.0;

    // Draw stylized arterial roads
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.35, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.65), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
