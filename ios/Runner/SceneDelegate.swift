import Flutter
import GoogleSignIn
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if URLContexts.contains(where: { GIDSignIn.sharedInstance.handle($0.url) }) {
      return
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
