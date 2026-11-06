/// 返回正值分布项，并按占比对应的原始数值从大到小排列。
///
/// 同值时按稳定 ID 排序，确保图例与饼图扇区不会在重建时抖动。
List<MapEntry<String, int>> sortPositiveDistributionEntries(
  Map<String, int> values,
) {
  final entries = values.entries.where((entry) => entry.value > 0).toList();
  entries.sort((first, second) {
    final valueComparison = second.value.compareTo(first.value);
    if (valueComparison != 0) {
      return valueComparison;
    }
    return first.key.compareTo(second.key);
  });
  return entries;
}
