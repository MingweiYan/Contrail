import 'package:contrail/features/statistics/presentation/utils/distribution_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('分布项过滤零值并按占比从大到小稳定排序', () {
    final result = sortPositiveDistributionEntries({
      'medium': 20,
      'zero': 0,
      'small': 5,
      'large': 80,
      'another-medium': 20,
    });

    expect(result.map((entry) => entry.key), [
      'large',
      'another-medium',
      'medium',
      'small',
    ]);
    expect(result.map((entry) => entry.value), [80, 20, 20, 5]);
  });
}
