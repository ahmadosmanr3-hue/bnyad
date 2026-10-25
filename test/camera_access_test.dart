import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nutrify/services/camera_access.dart';

void main() {
  test('first-use camera state requests native access exactly once', () async {
    var requests = 0;
    expect(
      await resolveCameraAccess(
        read: () async => PermissionStatus.denied,
        request: () async {
          requests++;
          return PermissionStatus.granted;
        },
      ),
      PermissionStatus.granted,
    );
    expect(requests, 1);
  });
  for (final status in [
    PermissionStatus.granted,
    PermissionStatus.permanentlyDenied,
    PermissionStatus.restricted,
  ]) {
    test('camera $status never requests native access again', () async {
      expect(
        await resolveCameraAccess(
          read: () async => status,
          request: () async => throw StateError('Unexpected request'),
        ),
        status,
      );
    });
  }
}
