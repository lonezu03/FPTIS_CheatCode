import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import 'quote_screen.dart';

class DailyQuoteCard extends StatefulWidget {
  const DailyQuoteCard({super.key});

  @override
  State<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends State<DailyQuoteCard> {
  Map<String, dynamic>? quote;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final response = Map<String, dynamic>.from(
        await context.read<ApiClient>().get('/quotes/today') as Map,
      );
      if (!mounted) return;
      setState(() {
        quote = response['quote'] is Map
            ? Map<String, dynamic>.from(response['quote'] as Map)
            : null;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openLibrary() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Kho câu nói')),
          body: const QuoteScreen(),
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Card(
        child: SizedBox(
          height: 150,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final item = quote;
    if (item == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.format_quote)),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bạn chưa có câu nói nào',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text('Lưu một câu để FitTrack gợi lại mỗi ngày.'),
                  ],
                ),
              ),
              TextButton(onPressed: _openLibrary, child: const Text('Thêm')),
            ],
          ),
        ),
      );
    }
    return Card(
      color: const Color(0xFF0C2821),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CÂU NÓI HÔM NAY',
              style: TextStyle(
                color: Color(0xFF9CE5C5),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '“${item['content']}”',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            if ((item['author']?.toString().trim() ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '— ${item['author']}',
                style: const TextStyle(
                  color: Color(0xFFD8F7E9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: item['content'].toString()),
                    );
                    if (context.mounted) {
                      showMessage(context, 'Đã sao chép câu nói.');
                    }
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Sao chép'),
                ),
                FilledButton(
                  onPressed: _openLibrary,
                  child: const Text('Xem kho'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
