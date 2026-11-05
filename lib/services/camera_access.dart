import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutrify/l10n/scan_strings.dart';
import 'package:permission_handler/permission_handler.dart';

/// Denial recorded by iOS is permanentlyDenied; a restriction is never requested.
Future<PermissionStatus> resolveCameraAccess({
  required Future<PermissionStatus> Function() read,
  required Future<PermissionStatus> Function() request,
}) async {
  final status = await read();
  return status == PermissionStatus.denied ? request() : status;
}

Future<bool> ensureCameraAccess(BuildContext context, String lang) async {
  if (kIsWeb) {
    return true; // The browser requests camera access on initialization.
  }
  PermissionStatus status;
  try {
    status = await resolveCameraAccess(
      read: () => Permission.camera.status,
      request: () => Permission.camera.request(),
    );
  } catch (_) {
    status = PermissionStatus.denied;
  }
  if (status.isGranted) return true;
  if (!context.mounted) return false;
  final t = ScanStrings(lang);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(status.isRestricted ? t.cameraRestricted : t.cameraDenied),
      action: status.isRestricted
          ? null
          : SnackBarAction(
              label: t.settings,
              onPressed: () {
                openAppSettings();
              },
            ),
    ),
  );
  return false;
}
