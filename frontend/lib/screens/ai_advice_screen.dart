import 'package:flutter/material.dart';
import 'package:roundup_app/services/api.dart';
import 'package:roundup_app/utils/notifier.dart';

class AiAdviceScreen extends StatefulWidget {
  const AiAdviceScreen({super.key});

  @override
  State<AiAdviceScreen> createState() => _AiAdviceScreenState();
}

class _AiAdviceScreenState extends State<AiAdviceScreen> {
  final _topicCtl = TextEditingController(text: 'roundup investing basics');
  bool _loading = false;
  String? _content;

  Future<void> _ask() async {
    setState(() { _loading = true; _content = null; });
    try {
      final r = await ApiClient.aiAdvice(_topicCtl.text.trim());
      setState(() {
        // Match backend response format
        final msg = r['message'] as Map<String, dynamic>?;
        _content = msg != null ? (msg['content'] as String?) : r.toString();
      });
      Notifier.success('Advice generated');
    } catch (e) {
      setState(() { _content = e.toString(); });
      Notifier.error(e.toString(), error: e);
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Advice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _topicCtl,
              decoration: const InputDecoration(labelText: 'Topic', hintText: 'e.g., roundup investing basics'),
              onSubmitted: (_) => _ask(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _ask,
              icon: const Icon(Icons.psychology_outlined),
              label: const Text('Get Advice'),
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(_content ?? 'Enter a topic and tap Get Advice.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
