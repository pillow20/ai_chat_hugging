import 'package:flutter/material.dart';
import 'chat_screen.dart';

class OpenRouterChatApp extends StatelessWidget {
  const OpenRouterChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Hugging',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        cardColor: const Color(0xFF1B263B),
        dividerColor: const Color(0xFF2A3F5F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE9B824),
          secondary: Color(0xFFD4A017),
          surface: Color(0xFF1B263B),
          onSurface: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1B263B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A3F5F), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE9B824), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
