import 'package:flutter_test/flutter_test.dart';
import 'package:tafeito_flutter/src/features/services/data/models/service_dto.dart';

void main() {
  test('ServiceDto parses providerId from userId/user_id', () {
    final a = ServiceDto.fromJson({'id': 's1', 'userId': 'u1'});
    final b = ServiceDto.fromJson({'id': 's2', 'user_id': 'u2'});
    final c = ServiceDto.fromJson({'id': 's3'});

    expect(a.providerId, 'u1');
    expect(b.providerId, 'u2');
    expect(c.providerId, '');
  });
}
