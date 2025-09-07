import SwiftUI
import SwiftGodot
import SwiftGodotKit

struct GodotSwiftUIView: View {
    var body: some View {
        GodotAppView().ignoresSafeArea()
    }
}



final class GodotContainerViewController: UIViewController {
override func viewDidLoad() {
super.viewDidLoad()
view.backgroundColor = .black
// PCK 체크는 GodotManager.init() 쪽으로 옮기는 걸 권장
}

override func viewWillAppear(_ animated: Bool) {
super.viewWillAppear(animated)
GodotManager.shared.attach(to: self, in: view)
}

override func viewWillDisappear(_ animated: Bool) {
super.viewWillDisappear(animated)
GodotManager.shared.detach()
}

override func viewDidLayoutSubviews() {
super.viewDidLayoutSubviews()
children.first?.view.frame = view.bounds
}
}
