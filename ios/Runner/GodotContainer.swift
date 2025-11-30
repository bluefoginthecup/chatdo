import UIKit

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(SwiftGodotKit)
import SwiftGodotKit
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, *)
struct GodotSwiftUIView: View {
  var body: some View {
    #if canImport(SwiftGodotKit)
    // SwiftUI 경로가 필요할 때만 사용
    GodotAppView().ignoresSafeArea()
    #else
    Color.blue.ignoresSafeArea()
    #endif
  }
}
#endif

final class GodotContainerViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    GodotManager.shared.attach(to: self, in: view)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    GodotManager.shared.detach()
  }

  // 레이아웃은 autoresizingMask로 처리하므로 별도 코드 불필요
}

