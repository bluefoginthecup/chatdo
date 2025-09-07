import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 1) 플러그인 자동 등록
    GeneratedPluginRegistrant.register(with: self)

    // 2) Godot PlatformView 등록 (부모 VC 주입)
    if let controller = window?.rootViewController as? FlutterViewController {
      if let registrar = controller.registrar(forPlugin: "GodotPlatformView") {
        registrar.register(
          GodotPlatformViewFactory(parentViewController: controller),
          withId: "GodotView"
        )
      } else {
        NSLog("⚠️ Failed to get registrar for GodotPlatformView")
      }
    } else {
      NSLog("⚠️ Root VC is not FlutterViewController; skipping GodotView registration.")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

