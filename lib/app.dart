import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

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
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1B263B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF2A3F5F), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFE9B824), width: 1.5),
          ),
          labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
