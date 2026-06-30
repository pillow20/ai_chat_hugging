import 'package:flutter/material.dart';
///import 'package:flutter/services.dart';
import '../services/chat_api_service.dart';
import '../widgets/input_panel.dart';
import '../widgets/footer.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/settings_modal.dart';

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

  final ChatApiService _apiService = ChatApiService();

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

  String _chatSummary = '';
  int _lastSummaryFailureIndex = -1;

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

    if (_messages.length > 15) {
      final shouldTrySummary = _lastSummaryFailureIndex == -1 ||
          (_messages.length - _lastSummaryFailureIndex) >= 10;

      if (shouldTrySummary) {
        final removeCount = _messages.length - 15;
        final oldMessages = _messages.sublist(0, removeCount);

        final newSummary = await _apiService.summarizeChat(
          apiKey: apiKey,
          model: _selectedModel,
          oldMessages: oldMessages,
          currentSummary: _chatSummary,
        );

        if (newSummary != null) {
          setState(() {
            _chatSummary = newSummary;
            _messages.removeRange(0, removeCount);
            _lastSummaryFailureIndex = -1;
          });
        } else {
          _lastSummaryFailureIndex = _messages.length;
        }
      }
    }

    final List<Map<String, dynamic>> apiMessages = [];

    if (systemPrompt.isNotEmpty) {
      apiMessages.add({'role': 'system', 'content': systemPrompt});
    }

    if (_chatSummary.isNotEmpty) {
      apiMessages.add({
        'role': 'system',
        'content': 'Контекст предыдущих сообщений (суммаризация): $_chatSummary'
      });
    }

    apiMessages.addAll(_messages.map((m) => {'role': m['role'], 'content': m['content']}).toList());

    final result = await _apiService.sendMessage(
      apiKey: apiKey,
      model: _selectedModel,
      messages: apiMessages,
      temperature: _temperature,
      maxTokens: _maxTokens,
    );

    if (result['success'] == true) {
      setState(() => _messages.add({'role': 'assistant', 'content': result['content']}));
    } else {
      setState(() => _messages.add({'role': 'assistant', 'content': result['error']}));
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
    if (_autoFocus) {
      _messageFocusNode.requestFocus();
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

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B263B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SettingsModal(
        apiKeyController: _apiKeyController,
        systemPromptController: _systemPromptController,
        models: _models,
        selectedModel: _selectedModel,
        temperature: _temperature,
        maxTokens: _maxTokens,
        autoFocus: _autoFocus,
        onModelChanged: (v) => setState(() => _selectedModel = v),
        onTemperatureChanged: (v) => setState(() => _temperature = v),
        onMaxTokensChanged: (v) => setState(() => _maxTokens = v),
        onAutoFocusChanged: (v) => setState(() => _autoFocus = v),
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
            const Text('AI Chat Hugging',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF0D1B2A),
        actions: [
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
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 48, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text('Начните диалог с нейросетью...',
                            style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 15)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => ChatBubble(message: _messages[index]),
                  ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE9B824)),
              minHeight: 2,
            ),
          InputPanel(
            messageController: _messageController,
            messageFocusNode: _messageFocusNode,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
          const ChatFooter(),
        ],
      ),
    );
  }
}
