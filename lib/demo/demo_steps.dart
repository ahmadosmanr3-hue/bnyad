import '../activity/step_health_provider.dart';
import '../activity/step_models.dart';
import '../activity/step_tracker.dart';
import 'demo_guard.dart';

class DemoStepSettingsStore extends LocalStepSettingsStore {
  @override
  Future<String?> read(String key) async {
    requireDemoRuntime();
    return await super.read(key) ??
        '{"connected":true,"goal":8000,"automatic":true,"confirmed":[]}';
  }
}

/// Imported only by main_demo.dart. No native health access, network or uploads.
class DemoStepHealthProvider extends StepHealthProvider {
  DemoStepHealthProvider() {
    requireDemoRuntime();
  }
  @override
  bool get simulated => true;
  @override
  Future<HealthAccess> access() async {
    requireDemoRuntime();
    return const HealthAccess(
      HealthAvailability.available,
      HealthPermission.granted,
    );
  }

  @override
  Future<bool> requestAccess() async {
    requireDemoRuntime();
    return true;
  }

  @override
  Future<List<StepDay>> readDays(List<StepWindow> windows) async {
    requireDemoRuntime();
    return [
      for (var i = 0; i < windows.length; i++)
        StepDay(
          windows[i].date,
          i == 0 ? 6420 : 4300 + (i % 5) * 180,
          distanceMeters: i == 0 ? 4200 : null,
        ),
    ];
  }

  @override
  Future<void> openSettings() async {
    requireDemoRuntime();
  }
}
