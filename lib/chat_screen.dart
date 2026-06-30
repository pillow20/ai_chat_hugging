import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:html' as html;
import 'widgets/code_block_builder.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final FocusNode _messageFocusNode = FocusNode(
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          return KeyEventResult.ignored;
        }
        if (!_isLoading) _sendMessage();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  );

  double _temperature = 0.7;
  int _maxTokens = 4000;
  bool _isLoading = false;
  bool _autoFocus = true;

  final List<Map<String, String>> _models = [
    {'name': 'DeepSeek-4V-flash', 'id': 'deepseek-ai/DeepSeek-V4-Flash:deepinfra'},
    {'name': 'Llama 3.1 8B (Ультра-бюджет)', 'id': 'meta-llama/Llama-3.1-8B-Instruct:cheapest'},
    {'name': 'Gemma 4 26B (Google Логика)', 'id': 'google/gemma-4-26B-A4B-it:cheapest'},
    {'name': 'Qwen 3.5 27B (Для кода)', 'id': 'Qwen/Qwen3.5-27B:cheapest'},
    {'name': 'Qwen 3.6 35B MoE (Быстрая)', 'id': 'Qwen/Qwen3.6-35B-A3B:cheapest'},
    {'name': 'Phi-4 (Сверхдешевый интеллект от MS)', 'id': 'microsoft/phi-4:cheapest'},
    {'name': 'Llama 3.1 70B (Красивый Текст)', 'id': 'meta-llama/Llama-3.1-70B-Instruct:deepinfra'},
  ];

  late String _selectedModel;
  final List<Map<String, String>> _messages = [];
  String? _conversationSummary;

  @override
  void initState() {
    super.initState();
    _selectedModel = _models[0]['id']!;
  }

  Future<void> _summarizeHistory() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty || _messages.length < 6) return;

    try {
      final response = await http.post(
        Uri.parse('https://router.huggingface.co/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _selectedModel,
          'temperature': 0.5,
          'max_tokens': 300,
          'messages': [
            {
              'role': 'system',
              'content': 'Сделай краткое summary всего диалога (4-7 предложений). Сохрани важные факты и контекст.'
            },
            {'role': 'user', 'content': _messages.map((m) => "${m['role']}: ${m['content']}").join('\n')}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _conversationSummary = data['choices'][0]['message']['content'];

        if (_messages.length > 8) {
          _messages.removeRange(0, _messages.length - 8);
        }
      }
    } catch (e) {
      print("Ошибка summarization: $e");
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final systemPrompt = _systemPromptController.text.trim();

    if (text.isEmpty) return;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFCF6679),
          content: Text('Введите Hugging Face Token', style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _messageController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    if (_messages.length >= 10) {
      await _summarizeHistory();
    }

    try {
      final List<Map<String, dynamic>> apiMessages = [];

      if (systemPrompt.isNotEmpty) {
        apiMessages.add({'role': 'system', 'content': systemPrompt});
      }

      if (_conversationSummary != null) {
        apiMessages.add({
          'role': 'system',
          'content': 'Краткое summary предыдущего разговора: $_conversationSummary'
        });
      }

      apiMessages.addAll(_messages.map((m) => {'role': m['role'], 'content': m['content']!}).toList());

      final response = await http.post(
        Uri.parse('https://router.huggingface.co/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _selectedModel,
          'temperature': _temperature,
          'max_tokens': _maxTokens,
          'messages': apiMessages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['choices'][0]['message']['content'].toString();
        setState(() => _messages.add({'role': 'assistant', 'content': reply}));
      } else {
        final errorData = jsonDecode(response.body);
        setState(() => _messages.add({
              'role': 'assistant',
              'content': 'Ошибка: ${response.statusCode}\n${errorData['error']?['message'] ?? response.body}'
            }));
      }
    } catch (e) {
      setState(() => _messages.add({'role': 'assistant', 'content': 'Ошибка соединения: $e'}));
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
      if (_autoFocus) {
        _messageFocusNode.requestFocus();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearHistory() {
    setState(() {
      _messages.clear();
      _conversationSummary = null;
    });
  }

  void _openSettings() {
    // Твой оригинальный код _openSettings без изменений
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B263B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... (весь твой код настроек остаётся без изменений)
                // Я не стал его копировать полностью, чтобы не делать сообщение слишком длинным,
                // но он полностью идентичен твоему оригинальному.
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE9B824).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFE9B824), size: 20),
            ),
            const SizedBox(width: 12),
            const Text('AI Chat Hugging', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF0D1B2A),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE9B824)),
            tooltip: 'Очистить чат',
            onPressed: _clearHistory,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFE9B824), size: 24),
            tooltip: 'Настройки',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF2A3F5F), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text('Начните диалог с нейросетью...', style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _buildChatBubble(_messages[index]),
                  ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE9B824)),
              minHeight: 2,
            ),
          _buildInputPanel(),
          _buildFooter(),
        ],
      ),
    );
  }

  // Все остальные методы (_buildChatBubble, _buildInputPanel, _buildFooter, _downloadFile, _copyToClipboard) оставь точно такими же, как у тебя были.

  
  Widget _buildChatBubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 4, right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B263B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2A3F5F)),
              ),
              child: const Icon(Icons.smart_toy_outlined, size: 16, color: Color(0xFFE9B824)),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF1E3A5F), Color(0xFF2C5282)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : const Color(0xFF1B263B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2))
                ],
                border: isUser
                    ? Border.all(color: const Color(0xFF3B6BA5).withOpacity(0.5))
                    : Border.all(color: const Color(0xFF2A3F5F)),
              ),
              child: isUser
                  ? Text(msg['content']!, style: const TextStyle(color: Color(0xFFF5F5F7), fontSize: 15, height: 1.35))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: msg['content']!,
                          selectable: true,
                          onTapLink: (text, href, title) {
                            if (href != null) html.window.open(href, '_blank');
                          },
                          builders: {
                            'pre': CodeBlockBuilder(
                              onDownload: (text, ext) => _downloadFile(text, ext, context),
                              onCopy: (text) => _copyToClipboard(text, context),
                            ),
                          },
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 15, height: 1.45),
                            code: const TextStyle(
                              backgroundColor: Color(0xFF0D1B2A),
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Color(0xFFE9B824),
                            ),
                            a: const TextStyle(color: Color(0xFFE9B824), decoration: TextDecoration.underline),
                            listBullet: const TextStyle(color: Color(0xFFE9B824)),
                            blockquoteDecoration: BoxDecoration(
                              color: const Color(0xFF0D1B2A),
                              border: const Border(left: BorderSide(color: Color(0xFFE9B824), width: 4)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            blockquote: const TextStyle(color: Color(0xFFE9B824), fontStyle: FontStyle.italic),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => _copyToClipboard(msg['content']!, context),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.copy_rounded, size: 16, color: Colors.white54),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      color: const Color(0xFF0D1B2A),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                minLines: 1,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Задайте вопрос... (Enter отправляет, Shift+Enter переносит)',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE9B824),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF0D1B2A), size: 22),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        border: Border(top: BorderSide(color: Color(0xFF1B263B), width: 1)),
      ),
      child: const Center(
        child: Text(
          'Разработчик: Алексей Агафонов',
          style: TextStyle(color: Colors.white30, fontSize: 11, letterSpacing: 0.6, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  void _downloadFile(String text, String extension, BuildContext context) {
    try {
      String ext = extension.toLowerCase();
      if (ext == 'code' || ext == 'text') ext = 'txt';
      if (ext == 'python') ext = 'py';
      if (ext == 'javascript') ext = 'js';
      if (ext == 'typescript') ext = 'ts';
      if (ext == 'dart') ext = 'dart';
      if (ext == 'csharp') ext = 'cs';

      final filename = 'generated_code.$ext';
      final bytes = utf8.encode(text);
      final blob = html.Blob([bytes], 'text/plain;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();

      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text('Файл $filename успешно скачан')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка скачивания: $e')));
    }
  }

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: const Color(0xFF1B263B),
        duration: const Duration(seconds: 2),
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFFE9B824), size: 20),
            SizedBox(width: 10),
            Text('Скопировано в буфер обмена', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
