import 'package:flutter/material.dart';

class SettingsModal extends StatefulWidget {
  final TextEditingController apiKeyController;
  final TextEditingController systemPromptController;
  final List<Map<String, String>> models;
  final String selectedModel;
  final double temperature;
  final int maxTokens;
  final bool autoFocus;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<double> onTemperatureChanged;
  final ValueChanged<int> onMaxTokensChanged;
  final ValueChanged<bool> onAutoFocusChanged;

  const SettingsModal({
    super.key,
    required this.apiKeyController,
    required this.systemPromptController,
    required this.models,
    required this.selectedModel,
    required this.temperature,
    required this.maxTokens,
    required this.autoFocus,
    required this.onModelChanged,
    required this.onTemperatureChanged,
    required this.onMaxTokensChanged,
    required this.onAutoFocusChanged,
  });

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  bool _obscureToken = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9B824).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune, color: Color(0xFFE9B824), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('Настройки',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Hugging Face Token', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: widget.apiKeyController,
              obscureText: _obscureToken,
              decoration: InputDecoration(
                hintText: 'Введите токен...',
                prefixIcon: const Icon(Icons.key_rounded, size: 20, color: Color(0xFFE9B824)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureToken ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: Colors.white54,
                  ),
                  onPressed: () => setState(() => _obscureToken = !_obscureToken),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Системный промпт', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: widget.systemPromptController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Например: "Ты опытный разработчик..."',
                prefixIcon: Icon(Icons.psychology_rounded, size: 20, color: Color(0xFFE9B824)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Модель', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: widget.selectedModel,
              isExpanded: true,
              dropdownColor: const Color(0xFF1B263B),
              decoration: const InputDecoration(
                labelText: 'Выберите модель',
                prefixIcon: Icon(Icons.model_training, size: 20, color: Color(0xFFE9B824)),
              ),
              items: widget.models
                  .map((m) => DropdownMenuItem<String>(
                        value: m['id'],
                        child: Text(m['name']!, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) widget.onModelChanged(v);
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Креативность', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text(widget.temperature.toStringAsFixed(1),
                    style: const TextStyle(color: Color(0xFFE9B824), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFE9B824),
                inactiveTrackColor: const Color(0xFF2A3F5F),
                thumbColor: const Color(0xFFE9B824),
                overlayColor: const Color(0xFFE9B824).withOpacity(0.2),
              ),
              child: Slider(
                value: widget.temperature,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                onChanged: widget.onTemperatureChanged,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Длина ответа (макс. токенов)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('${widget.maxTokens}',
                    style: const TextStyle(color: Color(0xFFE9B824), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFE9B824),
                inactiveTrackColor: const Color(0xFF2A3F5F),
                thumbColor: const Color(0xFFE9B824),
                overlayColor: const Color(0xFFE9B824).withOpacity(0.2),
              ),
              child: Slider(
                value: widget.maxTokens.toDouble(),
                min: 500.0,
                max: 8000.0,
                divisions: 75,
                onChanged: (v) => widget.onMaxTokensChanged(v.toInt()),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Автофокус на поле ввода', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Switch(
                  value: widget.autoFocus,
                  activeColor: const Color(0xFFE9B824),
                  onChanged: widget.onAutoFocusChanged,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE9B824),
                  foregroundColor: const Color(0xFF0D1B2A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Сохранить', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
