import 'package:flutter/material.dart';

class InputPanel extends StatelessWidget {
  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final bool isLoading;
  final VoidCallback onSend;

  const InputPanel({
    super.key,
    required this.messageController,
    required this.messageFocusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      color: const Color(0xFF0D1B2A),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                focusNode: messageFocusNode,
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
                onPressed: isLoading ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
