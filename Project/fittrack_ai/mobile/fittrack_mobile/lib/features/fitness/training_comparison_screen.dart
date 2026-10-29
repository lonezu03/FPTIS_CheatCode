import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';
import 'training_data.dart';

/// Comparison uses actual completed working sets; plan filters only include
/// sessions explicitly linked to an appointment.
class TrainingComparisonScreen extends StatefulWidget {
  const TrainingComparisonScreen({super.key});

  @override
  State<TrainingComparisonScreen> createState() =>
      _TrainingComparisonScreenState();
}

class _TrainingComparisonScreenState extends State<TrainingComparisonScreen> {
  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  final dates = <DateTime>[
    _today().subtract(const Duration(days: 55)),
    _today().subtract(const Duration(days: 28)),
    _today().subtract(const Duration(days: 27)),
    _today(),
  ];
  final selectedPlans = <String?>[null, null];
  List<Map<String, dynamic>> plans = [];
  Map<String, dynamic>? result;
  bool busy = false;
  String? error;
  String? plansError;
  final formatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlans());
  }

  Future<void> _loadPlans() async {
    try {
      final raw = await context.read<ApiClient>().get('/workout-plans');
      if (mounted)
        setState(() {
          plans = trainingList(raw);
          plansError = null;
        });
    } catch (e) {
      if (mounted) setState(() => plansError = displayError(e));
    }
  }

  Future<void> _pick(int index) async {
    final date = await showDatePicker(
      context: context,
      initialDate: dates[index],
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted)
      setState(() {
        dates[index] = date;
        result = null;
      });
  }

  Future<void> _compare() async {
    final lengths = [
      dates[1].difference(dates[0]).inDays,
      dates[3].difference(dates[2]).inDays,
    ];
    if (lengths.any((v) => v < 0 || v >= 366) || lengths[0] != lengths[1]) {
      setState(
        () =>
            error = 'Chọn hai khoảng hợp lệ, cùng số ngày và tối đa 366 ngày.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
      result = null;
    });
    try {
      final raw = await context.read<ApiClient>().get(
        '/workouts/comparison',
        queryParameters: {
          'firstFrom': formatter.format(dates[0]),
          'firstTo': formatter.format(dates[1]),
          'secondFrom': formatter.format(dates[2]),
          'secondTo': formatter.format(dates[3]),
          if (selectedPlans[0] != null) 'firstPlan': selectedPlans[0],
          if (selectedPlans[1] != null) 'secondPlan': selectedPlans[1],
        },
      );
      if (mounted)
        setState(() => result = Map<String, dynamic>.from(raw as Map));
    } catch (e) {
      if (mounted) setState(() => error = displayError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('So sánh tập luyện')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Chọn hai khoảng cùng số ngày. Lọc giáo án chỉ tính buổi có liên kết lịch tập; không suy đoán lịch sử cũ.',
        ),
        if (plansError != null)
          TextButton(
            onPressed: _loadPlans,
            child: Text('Không tải được giáo án: $plansError. Thử lại'),
          ),
        for (var i = 0; i < 2; i++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Giai đoạn ${i + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: busy ? null : () => _pick(i * 2),
                    child: Text('Từ ngày: ${formatter.format(dates[i * 2])}'),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => _pick(i * 2 + 1),
                    child: Text(
                      'Đến ngày: ${formatter.format(dates[i * 2 + 1])}',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPlans[i],
                    decoration: const InputDecoration(labelText: 'Giáo án'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Tất cả buổi thực tế'),
                      ),
                      ...plans.map(
                        (p) => DropdownMenuItem(
                          value: p['id'].toString(),
                          child: Text(
                            '${p['name']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: busy
                        ? null
                        : (value) => setState(() {
                            selectedPlans[i] = value == null || value.isEmpty
                                ? null
                                : value;
                            result = null;
                          }),
                  ),
                ],
              ),
            ),
          ),
        FilledButton(
          onPressed: busy ? null : _compare,
          child: Text(busy ? 'Đang so sánh...' : 'So sánh'),
        ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (result != null) ...[
          const SizedBox(height: 12),
          Text('${result!['disclaimer'] ?? ''}'),
          for (final entry in [
            result!['first'],
            result!['second'],
          ].asMap().entries)
            if (entry.value is Map)
              _period(Map<String, dynamic>.from(entry.value as Map), entry.key),
        ],
      ],
    ),
  );

  Widget _period(Map<String, dynamic> data, int index) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giai đoạn ${index + 1}: ${data['from']} → ${data['to']}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (data['completedSessions'] == 0)
            const Text(
              'Chưa có buổi đủ dữ liệu. Không kết luận hiệu quả bằng 0.',
            )
          else
            Text(
              '${data['completedSessions']} buổi · ${data['trainingDays']} ngày · ${data['workingSets']} hiệp chính · Tổng tải ${data['volume']} kg',
            ),
          if (data['plannedSessions'] != null)
            Text(
              'Liên kết thực tế: ${data['completedSessions']}/${data['plannedSessions']} lịch · Độ đều đặn: ${data['adherence'] ?? 'Chưa đủ dữ liệu'}',
            ),
          for (final exercise in trainingList(data['exercises']))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${exercise['name']}'),
              subtitle: Text(
                '${exercise['sets']} hiệp · Tổng tải ${exercise['volume']} kg · Tạ cao nhất ${exercise['bestWeight'] ?? 'Chưa biết'} · e1RM ${exercise['estimated1rm'] ?? 'Chưa có ước tính'}',
              ),
            ),
        ],
      ),
    ),
  );
}
