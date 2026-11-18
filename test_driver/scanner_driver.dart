import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final dir = Directory('build/scanner-result-evidence');
      await dir.create(recursive: true);
      await File(
        '${dir.path}/${Platform.environment['BNYAD_QA_RUN'] ?? 'native'}_$name.png',
      ).writeAsBytes(bytes);
      return true;
    },
  );
}
