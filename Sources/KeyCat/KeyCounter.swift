import AppKit
import CoreGraphics

/// 전역 keyDown 이벤트를 세는 카운터.
/// PoC 핵심 리스크 구간: 다른 앱에서 친 키까지 잡히는지 + 어떤 권한이 필요한지 검증한다.
final class KeyCounter: ObservableObject {
    /// 오늘 기록한 타자 수.
    @Published private(set) var count: Int
    /// 로컬 날짜(yyyy-MM-dd)별 누적 타자 수.
    @Published private(set) var dailyCounts: [String: Int]
    @Published var permissionGranted = false
    @Published var isPaused = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var currentDayKey: String
    private var rolloverTimer: Timer?
    private var pendingSave: DispatchWorkItem?
    private let dailyCountsKey = "dailyKeyCounts"

    init() {
        let today = Self.dayKey(for: Date())
        let savedCounts = UserDefaults.standard.data(forKey: dailyCountsKey)
            .flatMap { try? JSONDecoder().decode([String: Int].self, from: $0) }
            ?? [:]
        currentDayKey = today
        dailyCounts = savedCounts
        count = savedCounts[today, default: 0]
        scheduleMidnightRollover()
    }

    /// 기록 일시 정지/재개. tap 을 비활성화해 시스템 이벤트 콜백 자체를 멈춘다.
    func togglePause() {
        isPaused.toggle()
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: !isPaused)
        }
    }

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
                    DispatchQueue.main.async { counter.recordKeyPress() }
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

    private func recordKeyPress(at date: Date = Date()) {
        rollOverDayIfNeeded(at: date)
        count += 1
        dailyCounts[currentDayKey] = count
        scheduleSave()
    }

    /// 날짜가 바뀌면 새 날짜의 저장값(없으면 0)으로 화면 카운트를 전환한다.
    private func rollOverDayIfNeeded(at date: Date = Date()) {
        let dayKey = Self.dayKey(for: date)
        guard dayKey != currentDayKey else { return }
        saveDailyCounts()
        currentDayKey = dayKey
        count = dailyCounts[dayKey, default: 0]
        scheduleMidnightRollover()
    }

    private static func dayKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d",
                      components.year ?? 0,
                      components.month ?? 0,
                      components.day ?? 0)
    }

    /// 자정 직후 타이핑이 없어도 표시 숫자가 0으로 전환되도록 한 번짜리 타이머를 다시 잡는다.
    private func scheduleMidnightRollover() {
        rolloverTimer?.invalidate()
        let calendar = Calendar.current
        guard let nextMidnight = calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else { return }
        let timer = Timer(fire: nextMidnight.addingTimeInterval(0.1), interval: 0, repeats: false) { [weak self] _ in
            self?.rollOverDayIfNeeded()
        }
        RunLoop.main.add(timer, forMode: .common)
        rolloverTimer = timer
    }

    /// 키 입력마다 디스크를 쓰지 않도록 짧게 묶어서 저장한다.
    private func scheduleSave() {
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveDailyCounts() }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    private func saveDailyCounts() {
        pendingSave?.cancel()
        pendingSave = nil
        guard let data = try? JSONEncoder().encode(dailyCounts) else { return }
        UserDefaults.standard.set(data, forKey: dailyCountsKey)
    }

    /// 앱 종료 직전 아직 디바운스 중인 마지막 입력까지 저장한다.
    func flushPersistence() {
        dailyCounts[currentDayKey] = count
        saveDailyCounts()
    }

    deinit {
        rolloverTimer?.invalidate()
        pendingSave?.cancel()
    }
}
