// ios/Runner/AppDelegate.swift
import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 기본 엔진에 플러그인 등록
    GeneratedPluginRegistrant.register(with: self)

      // ✅ controller 대신 self에서 registrar를 받아 등록
          if let registrar = self.registrar(forPlugin: "GodotPlatformView") {
            let parent = window?.rootViewController  // UIViewController?
            registrar.register(
              GodotPlatformViewFactory(parentViewController: parent),
              withId: "GodotView"
            )
            NSLog("GodotView registered ✅")
          } else {
            NSLog("GodotView registration failed: registrar nil on AppDelegate.")
          }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

