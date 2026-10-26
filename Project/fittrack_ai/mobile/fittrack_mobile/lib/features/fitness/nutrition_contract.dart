/// Keep these unit rules aligned with NutritionService.resolveAmount.
bool isVolumeFood(Map<String, dynamic> food) => RegExp(
  r'ml|lít|liter|litre',
  caseSensitive: false,
).hasMatch(food['unit']?.toString() ?? '');

List<String> nutritionUnits(Map<String, dynamic> food) => [
  'SERVING',
  if ((food['servingSizeGrams'] as num? ?? 0) > 0)
    isVolumeFood(food) ? 'ML' : 'GRAM',
];

Map<String, dynamic> photoServing(Map<String, dynamic> food, double? grams) {
  final canUseGrams =
      nutritionUnits(food).contains('GRAM') &&
      grams != null &&
      grams.isFinite &&
      grams > 0;
  return {
    'unit': canUseGrams ? 'GRAM' : 'SERVING',
    'amount': canUseGrams ? grams : 1.0,
  };
}

Map<String, dynamic> nutritionItemPayload(
  String id,
  Map<String, dynamic> food,
  double amount,
  String unit,
) {
  if (!amount.isFinite || amount <= 0) {
    throw const FormatException('Số lượng phải lớn hơn 0 và hữu hạn.');
  }
  if (!nutritionUnits(food).contains(unit)) {
    throw const FormatException(
      'Đơn vị không phù hợp khẩu phần của thực phẩm.',
    );
  }
  final size = (food['servingSizeGrams'] as num?)?.toDouble();
  return {
    'foodId': id,
    'quantity': unit == 'SERVING' ? amount : amount / size!,
    'servingAmount': amount,
    'servingUnit': unit,
  };
}
