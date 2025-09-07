import UIKit
import SwiftUI
import SwiftGodot
import SwiftGodotKit

/// 앱 전체에서 단 하나의 GodotApp을 유지하고, 재사용 가능한 HostingVC를 관리
final class GodotManager {
    static let shared = GodotManager()

    private(set) var app: GodotApp!
    // ✅ AnyView로 타입 지워서 environment 수정자 사용 가능하게
    private var hostingVC: UIHostingController<AnyView>?
    private var isStarted = false
    private var isAttached = false

    private init() {
        // 엔진은 단 한 번만 생성
        app = GodotApp(packFile: "hilohilo_ios.pck")
        // (선택) 여기서 pck 존재 체크 1회
        // guard Bundle.main.url(forResource: "hilohilo_ios", withExtension: "pck") != nil else {
        //     assertionFailure("❌ hilohilo_ios.pck not found")
        //     return
        // }
    }

    private func startIfNeeded() {
        guard !isStarted else { return }
        // SwiftGodot/Kit 쪽에서 별도 스타트 필요 시 여기에
        isStarted = true
    }

    /// 재사용 가능한 Hosting VC 제공 (최초 1회 생성)
    private func getHostingVC() -> UIHostingController<AnyView> {
        if hostingVC == nil {
            // ✅ environment(\.godotApp, app) 적용 후 AnyView로 감싸기
            let root = AnyView(
                GodotSwiftUIView().environment(\.godotApp, app)
            )
            hostingVC = UIHostingController(rootView: root)
        }
        return hostingVC!
    }

    /// 부모 VC와 컨테이너 뷰에 Godot 호스팅 뷰를 붙임
    func attach(to parent: UIViewController, in containerView: UIView) {
        startIfNeeded()
        let vc = getHostingVC()

        if vc.parent !== parent {
            parent.addChild(vc)
            vc.view.frame = containerView.bounds
            vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            containerView.addSubview(vc.view)
            vc.didMove(toParent: parent)
        } else if vc.view.superview !== containerView {
            // 동일 부모인데 다른 컨테이너에 붙어 있으면 재부착
            vc.view.removeFromSuperview()
            vc.view.frame = containerView.bounds
            containerView.addSubview(vc.view)
        }

        isAttached = true
        // ❌ GodotApp에는 resume/focusIn 없음 → 호출 제거
    }

    /// 뷰만 안전하게 떼기(엔진은 유지)
    func detach() {
        guard isAttached, let vc = hostingVC else { return }

        // ❌ GodotApp에는 focusOut/pause 없음 → 호출 제거

        if let parent = vc.parent {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        } else {
            vc.view.removeFromSuperview()
        }
        isAttached = false
    }

    /// 앱 종료 시 1회만 호출(정말 필요할 때만)
    func shutdownOnce() {
        guard isStarted else { return }
        // app.shutdown() 제공 시 여기에
        isStarted = false
    }
}

