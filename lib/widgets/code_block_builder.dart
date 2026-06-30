import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class CodeBlockBuilder extends MarkdownElementBuilder {
  final void Function(String text, String extension) onDownload;
  final void Function(String text) onCopy;

  CodeBlockBuilder({required this.onDownload, required this.onCopy});

  String _detectLanguage(String code) {
    final c = code.toLowerCase();
    
    if (c.contains('void main(') || c.contains('widget build(') || 
        c.contains('buildcontext') || c.contains('setstate(')) return 'dart';
    if (c.contains('def ') || c.contains('import ') || c.contains('print(') || 
        c.contains('self.') || c.contains('if __name__')) return 'python';
    if (c.contains('const ') || c.contains('let ') || c.contains('=>') || 
        c.contains('console.log') || c.contains('document.')) return 'javascript';
    if (c.contains('<!doctype') || c.contains('<html') || c.contains('<div') || 
        c.contains('<body')) return 'html';
    if (c.contains('@media') || RegExp(r'\.[\w-]+\s*\{').hasMatch(code)) return 'css';
    if (c.contains('public class') || c.contains('public static void main') || 
        c.contains('system.out.println')) return 'java';
    if (c.contains('#include') && (c.contains('cout') || c.contains('std::'))) return 'cpp';
    if (c.contains('#include') && c.contains('printf')) return 'c';
    if (c.contains('using system') || c.contains('namespace ') || 
        c.contains('console.writeline')) return 'csharp';
    if (c.contains('package ') && c.contains('func main')) return 'go';
    if (RegExp(r'\b(select|insert|update|delete|create table)\b').hasMatch(c)) return 'sql';
    if (c.startsWith('#!/bin') || c.contains('\$1') || c.contains('echo ')) return 'bash';
    if (c.contains('<?php')) return 'php';
    if (c.contains('fn main') && c.contains('println!')) return 'rust';
    if (code.trim().startsWith('{') || code.trim().startsWith('[')) return 'json';
    
    return 'text';
  }

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent.trimRight();
    String lang = 'code';
    
    final cls = element.attributes['class'];
    if (cls != null && cls.startsWith('language-')) {
      lang = cls.substring(9);
    } else {
      lang = _detectLanguage(code);
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
