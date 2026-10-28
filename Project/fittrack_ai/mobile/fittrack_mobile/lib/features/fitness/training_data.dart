import 'dart:convert';

List<Map<String, dynamic>> trainingList(dynamic value) {
  final raw = value is Map ? value['content'] : value;
  return raw is List
      ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];
}

Map<String, dynamic> trainingCopy(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

bool isWorkingCompleted(Map set) =>
    set['completed'] == true && set['setType'] != 'WARMUP';

double trainingVolume(Iterable<Map<String, dynamic>> sessions) => sessions
    .expand((e) => trainingList(e['sets']))
    .where(isWorkingCompleted)
    .fold(
      0,
      (sum, e) =>
          sum + ((e['weight'] as num?) ?? 0) * ((e['reps'] as num?) ?? 0),
    );

/// Keeps the server version and always derives order from the visible list.
Map<String, dynamic> trainingPlanPayload(Map<String, dynamic> plan) => {
  'name': plan['name'],
  'description': plan['description'],
  if (plan['version'] != null) 'version': plan['version'],
  'days': trainingList(plan['days'])
      .asMap()
      .entries
      .map(
        (day) => {
          'name': day.value['name'],
          'dayOrder': day.key + 1,
          'exercises': trainingList(day.value['exercises'])
              .asMap()
              .entries
              .map(
                (entry) => {
                  for (final key in [
                    'exerciseId',
                    'targetSets',
                    'targetReps',
                    'targetWeight',
                    'targetRir',
                    'restSeconds',
                    'minReps',
                    'maxReps',
                    'coachingNote',
                    'groupKey',
                    'groupType',
                    'groupRounds',
                    'betweenExerciseRestSeconds',
                    'betweenRoundRestSeconds',
                  ])
                    key: entry.value[key],
                  'exerciseOrder': entry.key + 1,
                },
              )
              .toList(),
        },
      )
      .toList(),
};
