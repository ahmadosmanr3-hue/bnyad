import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/services/push_policy.dart';

void main() {
  test('OS-visible background alerts are not displayed a second time', () {
    expect(shouldDisplayBackgroundPush(hasSystemNotification: true), isFalse);
    expect(shouldDisplayBackgroundPush(hasSystemNotification: false), isTrue);
  });
  test('APNs registration waits until a real token is available', () async {
    var reads = 0, pauses = 0;
    expect(
      await waitForApnsToken(
        () async => ++reads == 3 ? 'fixture-token' : null,
        delay: (_) async {
          pauses++;
        },
      ),
      isTrue,
    );
    expect(reads, 3);
    expect(pauses, 2);
  });
  test('APNs wait is bounded when registration is unavailable', () async {
    var reads = 0;
    expect(
      await waitForApnsToken(
        () async {
          reads++;
          return null;
        },
        attempts: 3,
        delay: (_) async {},
      ),
      isFalse,
    );
    expect(reads, 3);
  });
}
