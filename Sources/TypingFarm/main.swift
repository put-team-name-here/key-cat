import AppKit

// 커맨드라인 실행형 GUI 앱: Dock 아이콘 없이 메뉴바 상주(.accessory)
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
