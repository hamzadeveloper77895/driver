import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  EmergencyContact({required this.id, required this.name, required this.phone, required this.relationship});
}

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool _shareAutomatically = true;

  final List<EmergencyContact> _contacts = [
    EmergencyContact(id: '1', name: 'Sarah Connor', phone: '+91 98765 00001', relationship: 'Spouse'),
    EmergencyContact(id: '2', name: 'David Miller', phone: '+91 98765 00002', relationship: 'Brother'),
  ];

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController(text: 'Family');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Contact Name')),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
            const SizedBox(height: 12),
            TextField(controller: relCtrl, decoration: const InputDecoration(labelText: 'Relationship')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                setState(() {
                  _contacts.add(EmergencyContact(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    relationship: relCtrl.text.trim(),
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Contact', style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  void _triggerSos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('SOS Alert Dispatched'),
          ],
        ),
        content: const Text(
          'Emergency SOS broadcasted! Our 24/7 Safety Response Team and your emergency contacts have received your live location and trip details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss', style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety Center & SOS'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Rapid SOS Emergency Trigger Card
            GlassCard(
              color: AppColors.error.withOpacity(0.12),
              border: Border.all(color: AppColors.error.withOpacity(0.4)),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.shield_rounded, size: 52, color: AppColors.error),
                  const SizedBox(height: 12),
                  const Text(
                    'Emergency SOS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Hold for 3 seconds to alert local emergency response & contacts',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTapDown: (_) {
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (mounted) _triggerSos();
                      });
                    },
                    child: Container(
                      width: 140,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(color: AppColors.error.withOpacity(0.4), blurRadius: 16),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'PRESS SOS',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency helpline quick dial
            GlassCard(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling National Emergency 112...')),
                );
              },
              child: Row(
                children: const [
                  Icon(Icons.phone_in_talk_rounded, color: AppColors.success),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Call Emergency Helpline (112)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Direct connect to police & ambulance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.call_made_rounded, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Automatic Trip Sharing Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-share live ride tracking', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Automatically notifies your emergency contacts when a trip begins', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              value: _shareAutomatically,
              activeColor: AppColors.primaryLight,
              onChanged: (val) => setState(() => _shareAutomatically = val),
            ),
            const Divider(color: AppColors.divider, height: 32),

            // Emergency Contacts Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: _showAddContactDialog,
                  icon: const Icon(Icons.add, size: 16, color: AppColors.primaryLight),
                  label: const Text('Add Contact', style: TextStyle(fontSize: 12, color: AppColors.primaryLight)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._contacts.map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.surfaceLight,
                        child: Text(c.name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('${c.relationship} • ${c.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                        onPressed: () => setState(() => _contacts.removeWhere((item) => item.id == c.id)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
