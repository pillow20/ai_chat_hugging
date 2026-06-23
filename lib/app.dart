// Главный виджет приложения и настройка темной темы
// Зависимости:
// - flutter/material.dart (базовые виджеты Flutter)
// - chat_screen.dart (основной экран приложения)

import 'package:flutter/material.dart';
import 'chat_screen.dart';

class OpenRouterChatApp extends StatelessWidget {
  const OpenRouterChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat',
      debugShowCheckedModeBanner: false,
      // Настройка темной темы интерфейса с фиолетовыми акцентами
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF7C4DFF),
        scaffoldBackgroundColor: const Color(0xFF0B0B0C),
        cardColor: const Color(0xFF161618),
        dividerColor: const Color(0xFF242427),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9D4EDD),
          secondary: Color(0xFF7C4DFF),
          surface: Color(0xFF161618),
        ),
        // Глобальная настройка оформления текстовых полей
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2C2C35), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}