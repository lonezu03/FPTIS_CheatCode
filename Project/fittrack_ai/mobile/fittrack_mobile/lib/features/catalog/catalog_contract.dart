const catalogExerciseColumns = [
  'id',
  'name',
  'muscleGroup',
  'equipment',
  'description',
  'imageUrl',
];
const catalogFoodColumns = [
  'id',
  'name',
  'unit',
  'basis',
  'servingSizeGrams',
  'calories',
  'protein',
  'carbs',
  'fat',
  'fiber',
  'sugar',
  'sodium',
  'potassium',
  'calcium',
  'iron',
  'vitaminC',
  'water',
  'barcode',
  'dataSourceType',
  'dataSourceName',
  'imageUrl',
];
const catalogLabels = <String, String>{
  'id': 'ID cập nhật',
  'name': 'Tên',
  'muscleGroup': 'Nhóm cơ chính',
  'equipment': 'Dụng cụ',
  'description': 'Hướng dẫn (tối đa 2.000 ký tự)',
  'imageUrl': 'URL ảnh HTTPS',
  'unit': 'Đơn vị khẩu phần',
  'basis': 'Cơ sở dinh dưỡng',
  'servingSizeGrams': 'Kích thước khẩu phần (g hoặc ml theo đơn vị)',
  'calories': 'Năng lượng (kcal)',
  'protein': 'Đạm (g)',
  'carbs': 'Tinh bột (g)',
  'fat': 'Chất béo (g)',
  'fiber': 'Chất xơ (g)',
  'sugar': 'Đường (g)',
  'sodium': 'Natri (mg)',
  'potassium': 'Kali (mg)',
  'calcium': 'Canxi (mg)',
  'iron': 'Sắt (mg)',
  'vitaminC': 'Vitamin C (mg)',
  'water': 'Nước (ml)',
  'barcode': 'Mã vạch',
  'dataSourceType': 'Loại nguồn',
  'dataSourceName': 'Tên nguồn',
};
const catalogNutrients = [
  'calories',
  'protein',
  'carbs',
  'fat',
  'fiber',
  'sugar',
  'sodium',
  'potassium',
  'calcium',
  'iron',
  'vitaminC',
  'water',
];
const catalogMicros = [
  'fiber',
  'sugar',
  'sodium',
  'potassium',
  'calcium',
  'iron',
  'vitaminC',
  'water',
];
List<Map<String, dynamic>> catalogMaps(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : [];
Map<String, dynamic> catalogMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<String> catalogStrings(dynamic value) =>
    value is List ? value.map((e) => e.toString()).toList() : [];
Map<String, dynamic> catalogDefaultSelection(Map<String, dynamic> row) => {
  'number': row['number'],
  'action': catalogStrings(row['errors']).isNotEmpty
      ? 'SKIP'
      : (row['suggestedAction'] ?? 'SKIP'),
  'clearFields': <String>[],
};
bool catalogSelectableExercise(Map<String, dynamic> item) =>
    item['active'] == true && item['approvalStatus'] == 'APPROVED';
String catalogCoverage(Map<String, dynamic> item) =>
    '${catalogMicros.where((key) => item[key] != null).length}/${catalogMicros.length} nhóm vi chất có dữ liệu';
