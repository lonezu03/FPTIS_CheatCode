import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class HabitHeatmap extends StatefulWidget {
  const HabitHeatmap({
    super.key,
    required this.id,
    required this.from,
    required this.to,
    required this.revision,
  });
  final String id, from, to, revision;
  @override
  State<HabitHeatmap> createState() => _HabitHeatmapState();
}

class _HabitHeatmapState extends State<HabitHeatmap> {
  late Future<dynamic> request;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    request = context.read<ApiClient>().get(
      '/todos/habits/${widget.id}/calendar',
      queryParameters: {'from': widget.from, 'to': widget.to},
    );
  }

  @override
  void didUpdateWidget(HabitHeatmap old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id ||
        old.from != widget.from ||
        old.to != widget.to ||
        old.revision != widget.revision)
      _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: request,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const LinearProgressIndicator();
      if (snapshot.hasError)
        return Column(
          children: [
            Text(displayError(snapshot.error!)),
            TextButton(
              onPressed: () => setState(_load),
              child: const Text('Thử lại'),
            ),
          ],
        );
      final c = Map<String, dynamic>.from(snapshot.data as Map);
      const names = {
        'DONE': 'Đã làm',
        'SKIPPED': 'Bỏ qua',
        'MISSED': 'Chưa làm',
        'PENDING': 'Chưa xong hôm nay',
        'REST': 'Ngày nghỉ',
        'UNKNOWN': 'Chưa xác minh',
        'BEFORE_START': 'Chưa bắt đầu',
        'FUTURE': 'Tương lai',
      };
      const colors = {
        'DONE': Colors.green,
        'SKIPPED': Colors.amber,
        'MISSED': Colors.redAccent,
        'PENDING': Colors.lightBlue,
        'REST': Colors.black12,
        'UNKNOWN': Colors.blueGrey,
        'BEFORE_START': Colors.white,
        'FUTURE': Colors.white,
      };
      final cells = (c['cells'] as List).cast<Map>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bản đồ thói quen',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Đã làm ${c['done']}/${c['eligibleDays']} · Tỷ lệ ${c['completionRate'] == null ? 'chưa đủ dữ liệu' : '${(c['completionRate'] as num).toStringAsFixed(0)}%'} · Chuỗi ${c['currentStreak']} · Dài nhất ${c['longestStreak']}',
          ),
          if (c['historyVerified'] != true)
            const Text('Một phần lịch cũ chưa xác minh, không đưa vào tỷ lệ.'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: cells.map((cell) {
              final label =
                  '${cell['day']}: ${names[cell['status']] ?? 'Không rõ'}';
              return Tooltip(
                message: label,
                child: Semantics(
                  label: label,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors[cell['status']] ?? Colors.grey,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children:
                ['DONE', 'SKIPPED', 'MISSED', 'PENDING', 'REST', 'UNKNOWN']
                    .map(
                      (s) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.square, color: colors[s], size: 14),
                          Text(' ${names[s]}'),
                        ],
                      ),
                    )
                    .toList(),
          ),
          const Text(
            'Ngày nghỉ không ngắt chuỗi. Hôm nay chưa xong chưa tính thất bại.',
          ),
        ],
      );
    },
  );
}
