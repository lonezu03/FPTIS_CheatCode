import 'package:flutter/material.dart';

const trainingGroupKeys = [
  'groupKey',
  'groupType',
  'groupRounds',
  'betweenExerciseRestSeconds',
  'betweenRoundRestSeconds',
];
Map<String, dynamic> trainingGroup(Map value) => {
  for (final k in trainingGroupKeys) k: value[k],
};

class WorkoutGroupEditor extends StatelessWidget {
  const WorkoutGroupEditor({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final Map<String, dynamic> value;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<String>(
        key: ValueKey('group-${value['groupType']}'),
        initialValue: value['groupType']?.toString() ?? '',
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Nhóm bài'),
        items: const [
          DropdownMenuItem(value: '', child: Text('Tập riêng')),
          DropdownMenuItem(value: 'SUPERSET', child: Text('Superset')),
          DropdownMenuItem(value: 'CIRCUIT', child: Text('Circuit')),
        ],
        onChanged: (v) {
          if (v == null || v.isEmpty) {
            for (final k in trainingGroupKeys) {
              value[k] = null;
            }
          } else {
            value.addAll({
              'groupType': v,
              'groupKey': value['groupKey'] ?? 'A',
              'groupRounds': value['groupRounds'] ?? 3,
              'betweenExerciseRestSeconds':
                  value['betweenExerciseRestSeconds'] ?? 15,
              'betweenRoundRestSeconds': value['betweenRoundRestSeconds'] ?? 90,
            });
          }
          onChanged();
        },
      ),
      if (value['groupKey'] != null) ...[
        TextFormField(
          initialValue: value['groupKey']?.toString(),
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: 'Mã nhóm (cùng mã để ghép)',
          ),
          onChanged: (v) => value['groupKey'] = v,
        ),
        for (final entry in const {
          'groupRounds': 'Số vòng (1–20)',
          'betweenExerciseRestSeconds': 'Nghỉ giữa bài (giây)',
          'betweenRoundRestSeconds': 'Nghỉ giữa vòng (giây)',
        }.entries)
          TextFormField(
            key: ValueKey('${entry.key}-${value['groupKey']}'),
            initialValue: value[entry.key]?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: entry.value),
            onChanged: (v) => value[entry.key] = int.tryParse(v),
          ),
        const Text(
          'Các bài cùng mã cần cùng loại/vòng/nghỉ. Đánh dấu từng hiệp thực tế; không tự ghi hoàn thành.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    ],
  );
}
