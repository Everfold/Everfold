import 'package:everfold/domain/common/app_failure.dart';
import 'package:everfold/domain/common/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Success 返回成功值', () {
    expect(const Success(42).getOrThrow(), 42);
  });

  test('Failure 将同一个安全失败交给异步状态管理', () {
    const error = AppFailure(FailureKind.storage);
    const result = Failure<int>(error);
    expect(result.getOrThrow, throwsA(same(error)));
  });
}
