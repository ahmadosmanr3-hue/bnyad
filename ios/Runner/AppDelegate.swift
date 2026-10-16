import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  private var stepBridge: BnyadStepBridge?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if !BNYAD_DEVELOPMENT
    // Firebase's default configure() raises a native exception without this
    // private release file. Missing optional push must not crash on startup.
    if FirebaseApp.app() == nil,
       Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      FirebaseApp.configure()
    }
    #endif

    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "BnyadStepBridge") {
      stepBridge = BnyadStepBridge(messenger: registrar.messenger())
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    #if !BNYAD_DEVELOPMENT
    if FirebaseApp.app() != nil {
      Messaging.messaging().delegate = self
      application.registerForRemoteNotifications()
    }
    #endif

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    if FirebaseApp.app() != nil {
      Messaging.messaging().apnsToken = deviceToken
    }
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    // Do not write device registration tokens to logs.
  }
}

/// Read-only native aggregates. No samples, device identifiers, health logging,
/// write permissions, observers, background delivery, or network transmission.
private final class BnyadStepBridge {
  private let store = HKHealthStore()
  private let channel: FlutterMethodChannel
  private var timeObserver: NSObjectProtocol?
  private var requesting = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "com.bnyad.app/steps", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
    timeObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main
    ) { [weak self] _ in self?.channel.invokeMethod("timeChanged", arguments: nil) }
  }
  deinit {
    if let observer = timeObserver { NotificationCenter.default.removeObserver(observer) }
  }
  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "access":
      // HealthKit intentionally NEVER reveals READ authorization status.
      result(["availability": HKHealthStore.isHealthDataAvailable() ? "available" : "unavailable",
              "permission": "unknown"])
    case "requestAccess":
      guard HKHealthStore.isHealthDataAvailable(), !requesting else { result(false); return }
      requesting = true
      let types: Set<HKObjectType> = [HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!]
      store.requestAuthorization(toShare: [], read: types) { [weak self] completed, error in
        DispatchQueue.main.async {
          self?.requesting = false
          // Completion is NOT proof that the user granted read access.
          if error != nil { result(FlutterError(code: "health_unavailable", message: "Health access could not be requested.", details: nil)) }
          else { result(completed) }
        }
      }
    case "readDays":
      guard HKHealthStore.isHealthDataAvailable(),
        let args = call.arguments as? [String: Any],
        let windows = args["windows"] as? [[String: Any]], windows.count <= 15,
        !windows.isEmpty else {
        result(FlutterError(code: "invalid_windows", message: "Invalid local-day windows.", details: nil)); return
      }
      let group = DispatchGroup()
      // All mutable result state is confined to the main queue.
      var output = Array(repeating: [String: Any](), count: windows.count)
      var failed = false
      var starts = [Date]()
      var ends = [Date]()
      for (index, window) in windows.enumerated() {
        guard let date = window["date"] as? String,
          let startMs = window["start"] as? NSNumber,
          let endMs = window["end"] as? NSNumber else { failed = true; continue }
        let start = Date(timeIntervalSince1970: startMs.doubleValue / 1000)
        let end = Date(timeIntervalSince1970: endMs.doubleValue / 1000)
        guard end >= start, end.timeIntervalSince(start) <= 26 * 3600,
          start >= Date().addingTimeInterval(-16 * 86400),
          end <= Date().addingTimeInterval(60),
          start == Calendar.current.startOfDay(for: start) else { failed = true; continue }
        output[index] = ["date": date, "steps": NSNull(), "distanceMeters": NSNull()]
        starts.append(start)
        ends.append(end)
      }
      guard !failed, let first = starts.min(), let last = ends.max() else {
        result(FlutterError(code: "invalid_windows", message: "Local-day boundaries changed or are invalid.", details: nil)); return
      }
      // Two one-shot collection queries, not 30 per-day queries. Calendar-day
      // buckets handle DST and samples straddling midnight in HealthKit itself.
      for (identifier, field, unit) in [
          (HKQuantityTypeIdentifier.stepCount, "steps", HKUnit.count()),
          (HKQuantityTypeIdentifier.distanceWalkingRunning, "distanceMeters", HKUnit.meter())
        ] {
          group.enter()
          // Do not sum raw phone/watch samples or separate source totals.
          let predicate = HKQuery.predicateForSamples(withStart: first, end: last, options: [])
          let query = HKStatisticsCollectionQuery(quantityType: HKQuantityType.quantityType(forIdentifier: identifier)!,
            quantitySamplePredicate: predicate, options: .cumulativeSum,
            anchorDate: first, intervalComponents: DateComponents(day: 1))
          query.initialResultsHandler = { _, statistics, error in
            DispatchQueue.main.async {
              // Missing/denied reads stay null. Optional distance failures must
              // not suppress an otherwise valid step total.
              if field == "steps", error != nil {
                let healthError = error as? HKError
                if healthError?.code != .errorNoData { failed = true }
              }
              for (index, start) in starts.enumerated() {
                if let quantity = statistics?.statistics(for: start)?.sumQuantity(), error == nil {
                  let value = quantity.doubleValue(for: unit)
                  if field == "steps" {
                    // Bucket boundaries can yield fractional estimates. Keep
                    // the channel's whole-step contract and round down safely.
                    if value.isFinite, value >= 0, value <= 100000 {
                      output[index][field] = Int(value.rounded(.down))
                    } else { failed = true }
                  } else if value.isFinite, value >= 0 {
                    output[index][field] = value
                  }
                }
              }
              group.leave()
            }
          }
          store.execute(query)
      }
      group.notify(queue: .main) {
        if failed { result(FlutterError(code: "health_read_failed", message: "Health data is temporarily unreadable.", details: nil)) }
        else { result(output) }
      }
    case "openSettings":
      // There is no supported API to revoke HealthKit READ permissions.
      guard let url = URL(string: UIApplication.openSettingsURLString) else { result(nil); return }
      UIApplication.shared.open(url) { _ in result(nil) }
    default: result(FlutterMethodNotImplemented)
    }
  }
}
