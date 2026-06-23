// Кастомный билдер для отображения блоков кода в Markdown
// Добавляет заголовок с языком, кнопки копирования и скачивания файла
// Зависимости:
// - flutter/material.dart (базовые виджеты и иконки)
// - flutter_markdown (базовый класс MarkdownElementBuilder)
// - markdown (парсинг AST элементов Markdown)

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class CodeBlockBuilder extends MarkdownElementBuilder {
  final void Function(String text, String extension) onDownload;
  final void Function(String text) onCopy;

  CodeBlockBuilder({required this.onDownload, required this.onCopy});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent.trimRight();
    String lang = 'code';
    
    // Извлечение названия языка программирования из class="language-..."
    final cls = element.attributes['class'];
    if (cls != null && cls.startsWith('language-')) {
      lang = cls.substring(9);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111113),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF242427), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка блока кода с названием языка и кнопками действий
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1E),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(9), topRight: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.toUpperCase(),
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                      hoverColor: Colors.white10,
                      tooltip: 'Копировать код',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () => onCopy(code),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined, size: 17, color: Colors.grey),
                      hoverColor: Colors.white10,
                      tooltip: 'Скачать файл',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () => onDownload(code, lang),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Горизонтальный скролл для длинных строк кода
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                code,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFFE4E4E7), height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}