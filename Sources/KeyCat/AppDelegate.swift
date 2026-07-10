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
        menu.addItem(NSMenuItem(title: "오버레이 표시/숨김", action: #selector(togglePanel), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: "축소/확장", action: #selector(toggleSize), keyEquivalent: "e"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "종료", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
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

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
