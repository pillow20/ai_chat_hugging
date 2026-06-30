import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:html' as html;
import 'code_block_builder.dart';

class ChatBubble extends StatelessWidget {
  final Map<String, String> message;

  const ChatBubble({super.key, required this.message});

  void _downloadFile(String text, String extension, BuildContext context) {
    try {
      String ext = extension.toLowerCase().trim();
      
      final Map<String, String> extensionMap = {
        'code': 'txt', 'text': 'txt', 'txt': 'txt',
        'python': 'py', 'py': 'py',
        'javascript': 'js', 'js': 'js',
        'typescript': 'ts', 'ts': 'ts',
        'dart': 'dart',
        'csharp': 'cs', 'cs': 'cs', 'c#': 'cs',
        'java': 'java',
        'cpp': 'cpp', 'c++': 'cpp', 'cxx': 'cpp',
        'c': 'c',
        'go': 'go', 'golang': 'go',
        'html': 'html', 'htm': 'html',
        'css': 'css',
        'sql': 'sql',
        'bash': 'sh', 'shell': 'sh', 'sh': 'sh',
        'php': 'php',
        'rust': 'rs', 'rs': 'rs',
        'ruby': 'rb', 'rb': 'rb',
        'swift': 'swift',
        'kotlin': 'kt', 'kt': 'kt',
        'r': 'r',
        'json': 'json',
        'yaml': 'yml', 'yml': 'yml',
        'xml': 'xml',
      };
      
      ext = extensionMap[ext] ?? ext;

      final filename = 'generated_code.$ext';
      final bytes = utf8.encode(text);
      final blob = html.Blob([bytes], 'text/plain;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text('Файл $filename скачан')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
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
                  ? Text(message['content']!,
                      style: const TextStyle(color: Color(0xFFF5F5F7), fontSize: 15, height: 1.35))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: message['content']!,
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
                        InkWell(
                          onTap: () => _copyToClipboard(message['content']!, context),
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
            ),
          ),
        ],
      ),
    );
  }
}
