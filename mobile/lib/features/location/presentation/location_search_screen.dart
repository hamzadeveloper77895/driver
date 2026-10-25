import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class LocationSearchScreen extends StatefulWidget {
  final String? prefill;
  const LocationSearchScreen({super.key, this.prefill});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final _pickupController = TextEditingController(text: 'Current Location (Indiranagar 100ft Rd)');
  late final TextEditingController _dropoffController;

  final List<Map<String, String>> _suggestedPlaces = [
    {
      'title': 'Kempegowda International Airport (BLR)',
      'subtitle': 'Devanahalli, Bengaluru, Karnataka 560300',
      'distance': '36.4 km',
      'lat': '13.1986',
      'lng': '77.7066',
    },
    {
      'title': 'Koramangala 4th Block',
      'subtitle': '80ft Road, Sony World Signal, Bengaluru',
      'distance': '5.8 km',
      'lat': '12.9345',
      'lng': '77.6265',
    },
    {
      'title': 'Whitefield ITPL Tech Park',
      'subtitle': 'Pattandur Agrahara, Whitefield, Bengaluru',
      'distance': '14.2 km',
      'lat': '12.9856',
      'lng': '77.7314',
    },
    {
      'title': 'UB City Mall',
      'subtitle': 'Vittal Mallya Rd, KG Halli, Bengaluru',
      'distance': '7.1 km',
      'lat': '12.9719',
      'lng': '77.5958',
    },
    {
      'title': 'Electronic City Phase 1',
      'subtitle': 'Hosur Rd, Electronic City, Bengaluru',
      'distance': '21.0 km',
      'lat': '12.8452',
      'lng': '77.6602',
    },
  ];

  @override
  void initState() {
    super.initState();
    _dropoffController = TextEditingController(
      text: widget.prefill == 'Home'
          ? 'Home (Indiranagar Defense Colony)'
          : (widget.prefill == 'Office' ? 'Office (Embassy GolfLinks)' : ''),
    );
  }

  void _proceedToReview(String dropoffTitle, double dropLat, double dropLng) {
    context.push(
      '/booking/review'
      '?pickup=${Uri.encodeComponent(_pickupController.text)}'
      '&dropoff=${Uri.encodeComponent(dropoffTitle)}'
      '&dropLat=$dropLat&dropLng=$dropLng',
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set Route'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                children: [
                  Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 36,
                            color: AppColors.surfaceLight,
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.rectangle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller: _pickupController,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                hintText: 'Pickup address',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _dropoffController,
                              autofocus: widget.prefill == null,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                hintText: 'Where to? (Drop-off or City Loop)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_vert_rounded, color: AppColors.textSecondary),
                        onPressed: () {
                          final temp = _pickupController.text;
                          setState(() {
                            _pickupController.text = _dropoffController.text;
                            _dropoffController.text = temp;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Set on map button
                  InkWell(
                    onTap: () async {
                      final result = await context.push<String>('/location/map-picker');
                      if (result != null && mounted) {
                        setState(() => _dropoffController.text = result);
                        _proceedToReview(result, 12.9716, 77.5946);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.map_outlined, size: 16, color: AppColors.primaryLight),
                          SizedBox(width: 8),
                          Text(
                            'Choose location on map',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Autocomplete suggestions list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _suggestedPlaces.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (context, index) {
                  final place = _suggestedPlaces[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.place_outlined, color: AppColors.secondary, size: 20),
                    ),
                    title: Text(
                      place['title']!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      place['subtitle']!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      place['distance']!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    onTap: () {
                      _proceedToReview(
                        place['title']!,
                        double.parse(place['lat']!),
                        double.parse(place['lng']!),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
