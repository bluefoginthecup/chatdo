// ios/Runner/GodotManager.swift
import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(SwiftGodotKit)
import SwiftGodotKit
#endif

final class GodotManager {
  static let shared = GodotManager()

  private weak var parentVC: UIViewController?
  private var hostingController: UIViewController?
  private weak var mountedView: UIView?

  #if canImport(SwiftGodotKit)
  private var godotApp: GodotApp?
  #endif

  func attach(to parent: UIViewController?, in container: UIView) {
    if !Thread.isMainThread {
      DispatchQueue.main.async { self.attach(to: parent, in: container) }
      return
    }
    if mountedView != nil { return }  // 중복 방지
    self.parentVC = parent

    #if canImport(SwiftGodotKit)
    #if canImport(SwiftUI)
    // 1️⃣ GodotApp 생성 (packFile: String → 파일명만 전달)
    let app: GodotApp
    if let existing = self.godotApp {
      app = existing
    } else {
      // 번들 안의 hilohilo_ios.pck 존재 여부 확인
      guard let _ = Bundle.main.path(forResource: "hilohilo_ios", ofType: "pck") else {
        NSLog("⚠️ hilohilo_ios.pck not found in bundle. Please add it to Copy Bundle Resources.")
        let placeholder = UIView(frame: container.bounds)
        placeholder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        placeholder.backgroundColor = .systemBlue
        container.addSubview(placeholder)
        self.mountedView = placeholder
        return
      }

      // ✅ packFile 인자로 파일 이름만 전달 (경로 X)
      app = GodotApp(packFile: "hilohilo_ios.pck")
      self.godotApp = app
    }

    // 2️⃣ SwiftUI 호스팅 (Environment에 app 주입)
    let rootView = GodotAppView()
      .environment(\.godotApp, app)

    let host = UIHostingController(rootView: rootView)
    let hostedView = host.view!
    hostedView.translatesAutoresizingMaskIntoConstraints = false

    if let parent = parent {
      parent.addChild(host)
    }
    container.addSubview(hostedView)
    NSLayoutConstraint.activate([
      hostedView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      hostedView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      hostedView.topAnchor.constraint(equalTo: container.topAnchor),
      hostedView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
    host.didMove(toParent: parent)

    self.hostingController = host
    self.mountedView = hostedView
    #else
    // SwiftUI 미지원 시
    let placeholder = UIView(frame: container.bounds)
    placeholder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    placeholder.backgroundColor = .systemBlue
    container.addSubview(placeholder)
    self.mountedView = placeholder
    #endif
    #else
    // SwiftGodotKit 미존재 시
    let placeholder = UIView(frame: container.bounds)
    placeholder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    placeholder.backgroundColor = .systemBlue
    container.addSubview(placeholder)
    self.mountedView = placeholder
    #endif
  }

  func detach() {
    if !Thread.isMainThread {
      DispatchQueue.main.async { self.detach() }
      return
    }
    if let host = hostingController {
      host.willMove(toParent: nil)
      host.view.removeFromSuperview()
      host.removeFromParent()
    } else {
      mountedView?.removeFromSuperview()
    }
    hostingController = nil
    mountedView = nil
    parentVC = nil

    #if canImport(SwiftGodotKit)
    godotApp = nil
    #endif
  }
}

