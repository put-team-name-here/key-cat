import AppKit
import SwiftUI
import CoreText

/// borderless 창은 기본적으로 key window가 못 되므로 서브클래스로 허용 (버튼 클릭용)
final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: OverlayPanel!
    private let counter = KeyCounter()
    private let state = AppState()

    private var menu: NSMenu!
    private var charsItem: NSMenuItem!
    private var coinsItem: NSMenuItem!
    private var harvestItem: NSMenuItem!
    private var pauseItem: NSMenuItem!
    private var autoModeItem: NSMenuItem!

    private var hosting: NSHostingView<OverlayView>!
    /// 축소/확장 카드 콘텐츠 크기. setupPanel/toggleSize 에서 hosting fittingSize 로 확정.
    private var collapsedSize = NSSize(width: 357, height: 205)
    private var expandedSize = NSSize(width: 366, height: 851)

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerFonts()
        setupStatusItem()
        setupPanel()
        counter.onCoinEarned = { [weak self] amount in
            self?.state.earnCoins(amount)
        }
        counter.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        counter.flushPersistence()
    }

    /// Galmuri11 픽셀 폰트를 프로세스에 등록. 미등록 시 galmuriFont 가 시스템 폰트로 폴백된다.
    private func registerFonts() {
        guard let url = Bundle.module.url(forResource: "Galmuri11", withExtension: "ttf", subdirectory: "fonts") else {
            NSLog("[KeyCat] Galmuri11.ttf 리소스를 찾지 못함")
            return
        }
        var err: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &err) {
            NSLog("[KeyCat] Galmuri11 등록 실패: \(String(describing: err?.takeRetainedValue()))")
        }
    }

    // MARK: - 메뉴바 상주

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🐾"

        menu = NSMenu()
        menu.delegate = self

        let farmItem = NSMenuItem(title: "농장 표시/숨김", action: #selector(togglePanel), keyEquivalent: "f")
        farmItem.image = symbolImage("leaf", color: .systemGreen)
        menu.addItem(farmItem)

        menu.addItem(.separator())

        charsItem = infoItem(title: "기록한 글자", symbol: "heart", color: .systemPink)
        coinsItem = infoItem(title: "보유 코인", symbol: "centsign.circle", color: .systemYellow)
        harvestItem = infoItem(title: "수확 가능 여부", symbol: "carrot", color: .systemGreen)
        menu.addItem(charsItem)
        menu.addItem(coinsItem)
        menu.addItem(harvestItem)

        menu.addItem(.separator())
        menu.addItem(.sectionHeader(title: "설정"))

        pauseItem = NSMenuItem(title: "기록 일시 정지", action: #selector(togglePause), keyEquivalent: "p")
        pauseItem.image = symbolImage("pause", color: .white)
        menu.addItem(pauseItem)

        autoModeItem = NSMenuItem(title: "오토 모드", action: #selector(toggleAutoMode), keyEquivalent: "a")
        autoModeItem.image = symbolImage("gearshape.2", color: .systemGreen)
        menu.addItem(autoModeItem)

        let quitItem = NSMenuItem(title: "프로그램 종료", action: #selector(quit), keyEquivalent: "q")
        quitItem.attributedTitle = NSAttributedString(
            string: "프로그램 종료",
            attributes: [.foregroundColor: NSColor.systemRed, .font: NSFont.menuFont(ofSize: 0)]
        )
        quitItem.image = symbolImage("rectangle.portrait.and.arrow.right", color: .systemRed)
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    /// 값 표시용 비활성 항목 (action 없음 → autoenable 로 비활성, 값은 badge 로 표시)
    private func infoItem(title: String, symbol: String, color: NSColor) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.image = symbolImage(symbol, color: color)
        return item
    }

    private func symbolImage(_ name: String, color: NSColor) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(paletteColors: [color]))
    }

    // MARK: - 오버레이 창

    private func setupPanel() {
        let content = OverlayView(
            counter: counter,
            state: state,
            onToggleSize: { [weak self] in self?.toggleSize() },
            onOpenSettings: { [weak self] in self?.openSettings() }
        )

        hosting = NSHostingView(rootView: content)
        // 축소 카드의 자연 크기를 읽어 패널 크기를 확정(시안 352폭 + 하드 그림자 여백).
        let fitting = hosting.fittingSize
        if fitting.width > 0, fitting.height > 0 {
            collapsedSize = fitting
        }

        panel = OverlayPanel(
            contentRect: NSRect(origin: .zero, size: collapsedSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hasShadow = true

        // 우측 상단에 배치
        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = NSPoint(
                x: visible.maxX - collapsedSize.width - 20,
                y: visible.maxY - collapsedSize.height - 20
            )
            panel.setFrameOrigin(origin)
        }
        panel.orderFrontRegardless()
    }

    // MARK: - 액션

    @objc private func toggleSize() {
        state.expanded.toggle()

        // 전환된 화면의 실제 콘텐츠 크기를 다시 측정해 캐시를 갱신한다.
        hosting.layoutSubtreeIfNeeded()
        let measured = hosting.fittingSize
        if measured.width > 0, measured.height > 0 {
            if state.expanded { expandedSize = measured } else { collapsedSize = measured }
        }
        let newSize = state.expanded ? expandedSize : collapsedSize

        // 우측 상단 모서리를 고정한 채 크기 변경
        var frame = panel.frame
        let topRight = NSPoint(x: frame.maxX, y: frame.maxY)
        frame.size = newSize
        frame.origin = NSPoint(x: topRight.x - newSize.width, y: topRight.y - newSize.height)
        panel.setFrame(frame, display: true, animate: true)
    }

    /// "설정" 버튼: 메뉴바와 동일한 NSMenu 를 마우스 위치에 popUp
    @objc private func openSettings() {
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    @objc private func togglePause() {
        counter.togglePause()
    }

    @objc private func toggleAutoMode() {
        state.toggleAutoMode()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

// MARK: - 메뉴가 열릴 때마다 실시간 값 갱신

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        charsItem.badge = NSMenuItemBadge(string: "\(counter.count)자")
        coinsItem.badge = NSMenuItemBadge(string: "\(state.coins)")
        harvestItem.badge = NSMenuItemBadge(string: state.harvestAvailable ? "가능" : "대기 중")
        pauseItem.title = counter.isPaused ? "기록 재개" : "기록 일시 정지"
        pauseItem.image = symbolImage(counter.isPaused ? "play" : "pause", color: .white)
        autoModeItem.state = state.autoModeEnabled ? .on : .off
        autoModeItem.title = state.autoModeEnabled ? "오토 모드 끄기" : "오토 모드 켜기"
    }
}
