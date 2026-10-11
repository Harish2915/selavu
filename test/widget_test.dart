import 'package:flutter_test/flutter_test.dart';
import 'package:selavu/core/constants/app_constants.dart';
import 'package:selavu/services/settlement_engine.dart';

void main() {
  test('App constants definition smoke test', () {
    expect(AppConstants.appName, 'Selavu');
  });

  test('SettlementEngine equal split precision test', () {
    final shares = SettlementEngine.calculateEqualSplit(
      totalAmountPaise: 1000,
      participantMemberIds: ['user1', 'user2', 'user3'],
    );
    expect(shares['user1'], 334);
    expect(shares['user2'], 333);
    expect(shares['user3'], 333);
    final total = shares.values.fold(0, (a, b) => a + b);
    expect(total, 1000); // 100% exact paise conservation
  });
}
