import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatApiService {
  final String baseUrl = 'https://router.huggingface.co/v1/chat/completions';

  Future<Map<String, dynamic>> sendMessage({
    required String apiKey,
    required String model,
    required List<Map<String, dynamic>> messages,
    required double temperature,
    required int maxTokens,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'messages': messages,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'content': data['choices'][0]['message']['content'].toString(),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': 'Ошибка: ${response.statusCode}\n${errorData['error']?['message'] ?? response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка соединения: $e',
      };
    }
  }

  Future<String?> summarizeChat({
    required String apiKey,
    required String model,
    required List<Map<String, String>> oldMessages,
    String currentSummary = '',
  }) async {
    final oldChatText = oldMessages.map((m) => '${m['role']}: ${m['content']}').join('\n');

    final summaryPrompt = 'Ты — помощник, который делает краткие выжимки диалогов. '
        'Кратко перескажи суть этого диалога в 2-4 предложениях, сохранив ключевые факты, имена и темы. '
        'Отвечай ТОЛЬКО выжимкой, без вступлений.\n\n'
        'Текущая выжимка предыдущей истории: ${currentSummary.isEmpty ? "Пусто" : currentSummary}\n\n'
        'Новые сообщения для учета:\n$oldChatText';

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'temperature': 0.3,
          'max_tokens': 300,
          'messages': [
            {'role': 'user', 'content': summaryPrompt}
          ],
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final newSummary = data['choices'][0]['message']['content'].toString().trim();
        if (newSummary.isNotEmpty && newSummary.length > 10) {
          return newSummary;
        }
      }
    } catch (e) {
      print('Ошибка суммаризации: $e');
    }

    return null;
  }
}
