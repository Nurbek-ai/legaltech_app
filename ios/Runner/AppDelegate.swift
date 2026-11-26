import Flutter
import UIKit
import PushKit
import UserNotifications
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, PKPushRegistryDelegate {
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Allow flutter_local_notifications / FCM banners while app is in foreground
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Register for Apple PushKit VoIP notifications (wakes iOS when locked/terminated)
    let mainQueue = DispatchQueue.main
    let registry = PKPushRegistry(queue: mainQueue)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    self.voipRegistry = registry

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - PKPushRegistryDelegate (VoIP Token)

  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate credentials: PKPushCredentials,
    for type: PKPushType
  ) {
    let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didInvalidatePushTokenFor type: PKPushType
  ) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  // MARK: - PKPushRegistryDelegate (Incoming VoIP Call Push)

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }

    let dict = payload.dictionaryPayload
    let rawCallId = (dict["call_id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    // iOS CallKit requires a valid UUID string for the call ID
    let callUuid = UUID(uuidString: rawCallId)?.uuidString ?? UUID().uuidString

    let callerNameRaw = (dict["caller_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let callerName = callerNameRaw.isEmpty ? "YAN360" : callerNameRaw

    let callTypeStr = (dict["call_type"] as? String)?.lowercased() ?? "audio"
    let isVideo = (callTypeStr == "video")
    let handleText = isVideo ? "Kiruvchi video qo‘ng‘iroq" : "Kiruvchi ovozli qo‘ng‘iroq"

    let callData = flutter_callkit_incoming.Data(
      id: callUuid,
      nameCaller: callerName,
      handle: handleText,
      type: isVideo ? 1 : 0
    )

    // Forward all YAN360 call payload fields to Flutter's CallKit listener
    var extra: [String: Any] = [:]
    for (key, value) in dict {
      if let strKey = key as? String {
        extra[strKey] = value
      }
    }
    extra["call_id"] = rawCallId.isEmpty ? callUuid : rawCallId
    callData.extra = extra as NSDictionary

    // Apple iOS 13+ strictly requires reporting the incoming call to CallKit immediately
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(
      callData,
      fromPushKit: true
    )

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      completion()
    }
  }
}