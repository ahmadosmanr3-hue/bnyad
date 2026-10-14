import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'demo_guard.dart';

/// No production legal pages, app stores or external URLs in the demo.
class DemoUrlLauncher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;
  DemoUrlLauncher() {
    requireDemoDebugBuild();
  }
  @override
  Future<bool> canLaunch(String url) async => false;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async => false;
}
