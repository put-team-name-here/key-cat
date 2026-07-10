import AppKit
import SwiftUI

/// borderless 창은 기본적으로 key window가 못 되므로 서브클래스로 허용 (버튼 클릭용)
final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: OverlayPanel!
    private let counter = KeyCounter()
    private let state = AppState()

    private var charsItem: NSMenuItem!
    private var coinsItem: NSMenuItem!
    private var harvestItem: NSMenuItem!
    private var pauseItem: NSMenuItem!

    private let collapsedSize = NSSize(width: 230, height: 230)
    private let expandedSize = NSSize(width: 405, height: 838)

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
        counter.start()
    }

    // MARK: - 메뉴바 상주

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🐾"

        let menu = NSMenu()
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
        let content = OverlayView(counter: counter, state: state, onToggleSize: { [weak self] in
            self?.toggleSize()
        })

        panel = OverlayPanel(
            contentRect: NSRect(origin: .zero, size: collapsedSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: content)
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
        let newSize = state.expanded ? expandedSize : collapsedSize

        // 우측 상단 모서리를 고정한 채 크기 변경
        var frame = panel.frame
        let topRight = NSPoint(x: frame.maxX, y: frame.maxY)
        frame.size = newSize
        frame.origin = NSPoint(x: topRight.x - newSize.width, y: topRight.y - newSize.height)
        panel.setFrame(frame, display: true, animate: true)
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
    }
}
