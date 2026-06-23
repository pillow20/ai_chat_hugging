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

  // FIX: Список моделей Hugging Face (OpenAI-совместимый формат)
  final List<Map<String, String>> _models = [
    {'name': 'Meta Llama 3.3 70B', 'id': 'meta-llama/Llama-3.3-70B-Instruct'},
    {'name': 'Qwen 2.5 72B', 'id': 'Qwen/Qwen2.5-72B-Instruct'},
    {'name': 'Mistral Large 2', 'id': 'mistralai/Mistral-Large-Instruct-2411'},
    {'name': 'DeepSeek R1 Distill 70B', 'id': 'deepseek-ai/DeepSeek-R1-Distill-Llama-70B'},
    {'name': 'Gemma 2 27B', 'id': 'google/gemma-2-27b-it'},
    {'name': 'Phi-4', 'id': 'microsoft/Phi-4'},
  ];

  late String _selectedModel;
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _selectedModel = _models[0]['id']!;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final systemPrompt = _systemPromptController.text.trim();

    if (text.isEmpty) return;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFCF6679),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          // FIX: Текст подсказки под Hugging Face
          content: const Text('Введите Hugging Face Token', style: TextStyle(color: Colors.white)),
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

    try {
      final List<Map<String, dynamic>> apiMessages = [];
      if (systemPrompt.isNotEmpty) {
        apiMessages.add({'role': 'system', 'content': systemPrompt});
      }
      apiMessages.addAll(_messages.map((m) => {'role': m['role'], 'content': m['content']}).toList());

      // FIX: URL и заголовки для Hugging Face Inference API
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

  @override
  void dispose() {
    _apiKeyController.dispose();
    _messageController.dispose();
    _systemPromptController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
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
                color: const Color(0xFF9D4EDD).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFB56576), size: 20),
            ),
            const SizedBox(width: 12),
            const Text('AI HUB Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF161618),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF242427), height: 1),
        ),
      ),
      body: Column(
        children: [
          _buildSettingsPanel(),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'Начните диалог с нейросетью...',
                          style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 15),
                        ),
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9D4EDD)),
              minHeight: 2,
            ),
          _buildInputPanel(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF242427), width: 1),
        ),
        child: ExpansionTile(
          iconColor: const Color(0xFF9D4EDD),
          collapsedIconColor: Colors.grey,
          title: const Row(
            children: [
              Icon(Icons.tune, size: 18, color: Colors.grey),
              SizedBox(width: 10),
              Text('Параметры конфигурации', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70)),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  const Divider(color: Color(0xFF242427), height: 1, thickness: 1),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    // FIX: Label под Hugging Face
                    decoration: const InputDecoration(
                      labelText: 'Hugging Face Token',
                      prefixIcon: Icon(Icons.key_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _systemPromptController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Системный промпт (необязательно)',
                      hintText: 'Например: "Ты опытный разработчик..."',
                      prefixIcon: Icon(Icons.psychology_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedModel,
                          isExpanded: true,
                          alignment: Alignment.bottomCenter,
                          dropdownColor: const Color(0xFF1E1E22),
                          decoration: const InputDecoration(
                            labelText: 'Модель',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: _models
                              .map((m) => DropdownMenuItem<String>(
                                    value: m['id'],
                                    child: Text(m['name']!, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedModel = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Креативность', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('${_temperature.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, color: Color(0xFF9D4EDD), fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Slider(
                              value: _temperature,
                              min: 0.0,
                              max: 2.0,
                              divisions: 20,
                              activeColor: const Color(0xFF9D4EDD),
                              inactiveColor: const Color(0xFF2C2C35),
                              onChanged: (v) => setState(() => _temperature = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Длина ответа (макс. токенов)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('$_maxTokens', style: const TextStyle(fontSize: 12, color: Color(0xFF9D4EDD), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _maxTokens.toDouble(),
                        min: 500.0,
                        max: 8000.0,
                        divisions: 75,
                        activeColor: const Color(0xFF9D4EDD),
                        inactiveColor: const Color(0xFF2C2C35),
                        onChanged: (v) => setState(() => _maxTokens = v.toInt()),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Автофокус на поле ввода',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      Switch(
                        value: _autoFocus,
                        activeColor: const Color(0xFF9D4EDD),
                        onChanged: (value) => setState(() => _autoFocus = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                color: const Color(0xFF161618),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF242427)),
              ),
              child: const Icon(Icons.smart_toy_outlined, size: 16, color: Color(0xFF9D4EDD)),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF3A1C71) : const Color(0xFF161618),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
                border: isUser 
                    ? Border.all(color: const Color(0xFF502799).withOpacity(0.5))
                    : Border.all(color: const Color(0xFF242427)),
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
                            if (href != null) {
                              html.window.open(href, '_blank');
                            }
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
                              backgroundColor: Color(0xFF28282B), 
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Color(0xFFF43F5E),
                            ),
                            a: const TextStyle(color: Color(0xFF9D4EDD), decoration: TextDecoration.underline),
                            listBullet: const TextStyle(color: Color(0xFF9D4EDD)),
                            blockquoteDecoration: BoxDecoration(
                              color: const Color(0xFF3E2723),
                              border: const Border(left: BorderSide(color: Color(0xFF9D4EDD), width: 4)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            blockquote: const TextStyle(color: Colors.yellow, fontStyle: FontStyle.italic),
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
      color: const Color(0xFF0B0B0C),
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
                color: Color(0xFF9D4EDD),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
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
        color: Color(0xFF0B0B0C),
        border: Border(top: BorderSide(color: Color(0xFF161618), width: 1)),
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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Файл $filename успешно скачан'),
        ),
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
        backgroundColor: const Color(0xFF1E1E22),
        duration: const Duration(seconds: 2),
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
            SizedBox(width: 10),
            Text('Скопировано в буфер обмена', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
