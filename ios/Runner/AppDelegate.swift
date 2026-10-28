import AVFAudio
import CallKit
import Flutter
import GoogleMaps
import PushKit
import UIKit
import WebRTC
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CallkitIncomingAppDelegate {
  /// Kept for the app's lifetime: PushKit stops calling a released registry.
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Read from Info.plist (GMSApiKey), injected at build time from Secrets.xcconfig.
    if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !mapsApiKey.isEmpty {
      GMSServices.provideAPIKey(mapsApiKey)
    }
    GeneratedPluginRegistrant.register(with: self)

    // In-app calls: CallKit owns the audio session, so WebRTC starts its audio
    // only once CallKit activates it (didActivateAudioSession below) — else a
    // call answered on the lock screen has no sound.
    RTCAudioSession.sharedInstance().useManualAudio = true
    RTCAudioSession.sharedInstance().isAudioEnabled = false

    let registry = PKPushRegistry(queue: DispatchQueue.main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - PushKit (customer → driver calls)

  /// The hex token Dart sends to POST /api/calls/voip-token.
  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
    let token = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  /// iOS kills an app that doesn't report every VoIP push to CallKit right
  /// away, so the call is reported here, before Dart runs; Dart then checks
  /// GET /api/calls/:id and ends it if it no longer rings. Keep these
  /// settings in step with callKitParamsFor() in callkit_system_ui.dart.
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
    let push = payload.dictionaryPayload
    // A push without a usable id is still reported (Dart's check ends it).
    let callId = push["call_id"] as? String ?? UUID().uuidString
    let ringSec = (push["ring_timeout_sec"] as? Int)
      ?? Int(push["ring_timeout_sec"] as? String ?? "") ?? 30
    let callerName = (push["caller_name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "ลูกค้า"
    let avatar = push["caller_avatar"] as? String ?? ""
    let extra: [String: Any] = [
      "call_id": callId,
      "kind": push["kind"] as? String ?? "",
      "job_id": push["job_id"] as? String ?? "",
      "caller_name": push["caller_name"] as? String ?? "",
      "caller_avatar": avatar,
      "ring_timeout_sec": ringSec,
    ]
    let ios: [String: Any] = [
      "handleType": "generic",
      "supportsVideo": false,
      "maximumCallGroups": 1,
      "maximumCallsPerCallGroup": 1,
      "supportsDTMF": false,
      "supportsHolding": false,
      "supportsGrouping": false,
      "supportsUngrouping": false,
      "includesCallsInRecents": false,
      "audioSessionMode": "voiceChat",
      "ringtonePath": "system_ringtone_default",
    ]
    let missed: [String: Any] = ["showNotification": false]
    let args: [String: Any?] = [
      "id": callId,
      "nameCaller": callerName,
      "appName": "Mass Drive",
      "handle": "ลูกค้า",
      "avatar": avatar,
      "type": 0,
      "duration": (ringSec + 5) * 1000,
      "extra": extra,
      "missedCallNotification": missed,
      "ios": ios,
    ]
    let data = flutter_callkit_incoming.Data(args: args)
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true) {
      completion()
    }
  }

  // MARK: - CallkitIncomingAppDelegate
  // Accept / decline / end are sent to the backend from Dart (the plugin's
  // events); the CallKit actions just complete.

  func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
    action.fulfill()
  }

  func onDecline(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onEnd(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onTimeOut(_ call: Call) {}

  func didActivateAudioSession(_ audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = true
  }

  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
    RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
    RTCAudioSession.sharedInstance().isAudioEnabled = false
  }

  func providerDidReset() {}
}
