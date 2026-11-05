import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Actual installed platform metadata, including release build overrides.
class AppBuildInfo extends StatefulWidget {
  final String lang;
  const AppBuildInfo({super.key, required this.lang});
  @override
  State<AppBuildInfo> createState() => _AppBuildInfoState();
}

class _AppBuildInfoState extends State<AppBuildInfo> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();
  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: _info,
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();
      final p = snapshot.data!;
      final label = widget.lang == 'ar'
          ? 'الإصدار'
          : (widget.lang == 'ku' || widget.lang == 'ckb')
          ? 'وەشان'
          : 'Version';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text('$label · BNYAD'),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                '${p.version} (${p.buildNumber})\n${p.packageName}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    },
  );
}
