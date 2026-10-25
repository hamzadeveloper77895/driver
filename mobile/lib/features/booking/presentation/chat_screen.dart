import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;

  ChatMessage({required this.text, required this.isMe, required this.time});
}

class ChatScreen extends StatefulWidget {
  final String bookingId;
  const ChatScreen({super.key, required this.bookingId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I am on my way to your pickup location.',
      isMe: false,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  final List<String> _quickReplies = [
    'I am waiting at the main gate',
    'Please wait 3 minutes',
    'Take the service road entrance',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.insert(
        0,
        ChatMessage(text: text.trim(), isMe: true, time: DateTime.now()),
      );
      _textController.clear();
    });

    // Simulate driver reply after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(text: 'Understood, see you shortly!', isMe: false, time: DateTime.now()),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.secondary,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Assigned Chauffeur', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Online • ChauffeurX Partner', style: TextStyle(fontSize: 11, color: AppColors.success)),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick reply chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _quickReplies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: AppColors.surface,
                      label: Text(reply, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                      onPressed: () => _sendMessage(reply),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: msg.isMe ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: msg.isMe ? Radius.zero : null,
                          bottomLeft: !msg.isMe ? Radius.zero : null,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.jm().format(msg.time),
                            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Text Field
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message to your driver...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _sendMessage(_textController.text),
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
