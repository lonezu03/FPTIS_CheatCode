import 'dart:io';

import 'package:health/health.dart';

import '../network/api_client.dart';

class HealthConnectService {
  HealthConnectService(this.api);

  final ApiClient api;
  final Health health = Health();

  static const types = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.WEIGHT,
    HealthDataType.HEART_RATE,
    HealthDataType.WORKOUT,
  ];

  Future<Map<String, dynamic>> syncLastSevenDays() async {
    if (!Platform.isAndroid) {
      throw StateError('Health Connect hiện chỉ được bật cho Android.');
    }
    await health.configure();
    final status = await health.getHealthConnectSdkStatus();
    if (status != HealthConnectSdkStatus.sdkAvailable) {
      throw StateError('Thiết bị chưa có hoặc chưa cập nhật Health Connect.');
    }
    final granted = await health.requestAuthorization(types);
    if (!granted) throw StateError('Bạn chưa cấp quyền đọc dữ liệu sức khỏe.');
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));
    final points = health.removeDuplicates(
      await health.getHealthDataFromTypes(
        types: types,
        startTime: start,
        endTime: end,
      ),
    );
    final records = points.map((point) {
      final numeric = point.value is NumericHealthValue
          ? (point.value as NumericHealthValue).numericValue.toDouble()
          : null;
      return <String, dynamic>{
        'externalId': point.uuid,
        'recordType': switch (point.type) {
          HealthDataType.STEPS => 'STEPS',
          HealthDataType.WEIGHT => 'WEIGHT',
          HealthDataType.HEART_RATE => 'HEART_RATE',
          _ => 'EXERCISE_SESSION',
        },
        'sourceName': point.sourceName,
        'startAt': point.dateFrom.toLocal().toIso8601String(),
        'endAt': point.dateTo.toLocal().toIso8601String(),
        'value': numeric,
        'unit': point.unitString,
      };
    }).toList();
    if (records.isEmpty) return {'imported': 0, 'duplicates': 0, 'rejected': 0};
    return Map<String, dynamic>.from(
      await api.post('/health-connect/sync', data: {'records': records}) as Map,
    );
  }
}
