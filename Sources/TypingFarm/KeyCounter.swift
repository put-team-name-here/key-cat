import AppKit
import CoreGraphics

/// 전역 keyDown 이벤트를 세는 카운터.
/// PoC 핵심 리스크 구간: 다른 앱에서 친 키까지 잡히는지 + 어떤 권한이 필요한지 검증한다.
final class KeyCounter: ObservableObject {
    @Published var count = 0
    @Published var permissionGranted = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        // 입력 모니터링 권한 사전 확인 및 요청 (macOS 10.15+)
        permissionGranted = CGPreflightListenEventAccess()
        if !permissionGranted {
            CGRequestListenEventAccess()
        }
        setupTap()
    }

    private func setupTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, _, event, refcon in
                if let refcon {
                    let counter = Unmanaged<KeyCounter>.fromOpaque(refcon).takeUnretainedValue()
                    DispatchQueue.main.async { counter.count += 1 }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("⚠️  eventTap 생성 실패 - 입력 모니터링/손쉬운 사용 권한이 필요합니다.")
            permissionGranted = false
            scheduleRetry()
            return
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        permissionGranted = true
        print("✅ eventTap 활성화 - 전역 keyDown 카운트 시작")
    }

    /// 권한이 아직 없을 때: 사용자가 시스템 설정에서 허용하는 동안 폴링해서 재시도
    private func scheduleRetry() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self, self.eventTap == nil else { return }
            if CGPreflightListenEventAccess() {
                self.setupTap()
            } else {
                self.scheduleRetry()
            }
        }
    }
}
