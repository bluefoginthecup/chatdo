import Flutter
import UIKit

final class GodotPlatformView: NSObject, FlutterPlatformView {
  private let container = UIView()
  private weak var parentVC: UIViewController?

  init(frame: CGRect, parentVC: UIViewController?) {
    self.parentVC = parentVC
    super.init()
    container.frame = frame
    container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    container.backgroundColor = .black
    // GodotManager는 parentVC가 nil이어도 안전하도록 처리되어 있어야 합니다.
    GodotManager.shared.attach(to: parentVC, in: container)
  }

  func view() -> UIView { container }

  deinit {
    GodotManager.shared.detach()
  }
}

final class GodotPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  private weak var parentViewController: UIViewController?

  // ✅ UIViewController? 로 변경 (nil 허용)
  init(parentViewController: UIViewController?) {
    self.parentViewController = parentViewController
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    // parent가 nil이어도 생성 (attach 내부에서 nil-safe)
    return GodotPlatformView(frame: frame, parentVC: parentViewController)
  }
}
