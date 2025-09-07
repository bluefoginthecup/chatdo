import Flutter
import UIKit

final class GodotPlatformView: NSObject, FlutterPlatformView {
private let container = UIView()
private let parentVC: UIViewController

init(frame: CGRect, parentVC: UIViewController) {
self.parentVC = parentVC
super.init()
container.frame = frame
container.backgroundColor = .black
GodotManager.shared.attach(to: parentVC, in: container)
}

func view() -> UIView { container }

deinit {
GodotManager.shared.detach()
}
}

final class GodotPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
private weak var parentViewController: UIViewController?

init(parentViewController: UIViewController) {
self.parentViewController = parentViewController
super.init()
}

func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
FlutterStandardMessageCodec.sharedInstance()
}

func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
guard let parent = parentViewController else {
return FallbackEmptyPlatformView(frame: frame)
}
return GodotPlatformView(frame: frame, parentVC: parent)
}
}

private final class FallbackEmptyPlatformView: NSObject, FlutterPlatformView {
private let v: UIView
init(frame: CGRect) { v = UIView(frame: frame); super.init() }
func view() -> UIView { v }
}
