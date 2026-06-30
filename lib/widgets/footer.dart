import 'package:flutter/material.dart';

class ChatFooter extends StatelessWidget {
  const ChatFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        border: Border(top: BorderSide(color: Color(0xFF1B263B), width: 1)),
      ),
      child: const Center(
        child: Text(
          '2025 год Агафонов Алексей',
          style: TextStyle(color: Colors.white30, fontSize: 11, letterSpacing: 0.6, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
