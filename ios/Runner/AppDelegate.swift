import Flutter
import GoogleSignIn
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var googleAuthChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "com.b46.orderapp/google_auth",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "provider_error", message: "Google sign-in is unavailable.", details: nil))
        return
      }
      switch call.method {
      case "authenticate":
        self.authenticateWithGoogle(call: call, result: result)
      case "signOut":
        GIDSignIn.sharedInstance.signOut()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    googleAuthChannel = channel
  }

  private func authenticateWithGoogle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let clientId = arguments["clientId"] as? String, !clientId.isEmpty,
          let serverClientId = arguments["serverClientId"] as? String, !serverClientId.isEmpty,
          let nonce = arguments["nonce"] as? String, !nonce.isEmpty else {
      result(FlutterError(code: "not_configured", message: "Google sign-in configuration is missing.", details: nil))
      return
    }
    guard let presenter = currentPresenter() else {
      result(FlutterError(code: "provider_error", message: "Google sign-in cannot open.", details: nil))
      return
    }

    GIDSignIn.sharedInstance.configuration = GIDConfiguration(
      clientID: clientId,
      serverClientID: serverClientId
    )
    GIDSignIn.sharedInstance.signIn(
      withPresenting: presenter,
      hint: nil,
      additionalScopes: [],
      nonce: nonce
    ) { signInResult, error in
      if let error {
        let code = (error as NSError).code == GIDSignInErrorCode.canceled.rawValue
          ? "cancelled" : "provider_error"
        result(FlutterError(code: code, message: "Google sign-in did not complete.", details: nil))
        return
      }
      guard let token = signInResult?.user.idToken?.tokenString, !token.isEmpty else {
        result(FlutterError(code: "provider_error", message: "Google did not return an identity token.", details: nil))
        return
      }
      result(token)
    }
  }

  private func currentPresenter() -> UIViewController? {
    let keyWindow = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var controller = keyWindow?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}
