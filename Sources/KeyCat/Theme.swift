import SwiftUI

// MARK: - 색 유틸

extension Color {
    /// 0xRRGGBB 정수로 sRGB 색 생성
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

// MARK: - 레트로 픽셀 테마 (축소 화면 전용)
// 근거: claude.ai/design 시안 축소화면.dc.html 팔레트.

struct RetroTheme {
    let cardBg = Color(hex: 0xb4ccc2)      // 카드 배경
    let ink = Color(hex: 0x3b2b22)          // 테두리·짙은 선
    let panel = Color(hex: 0xefe7d0)        // 정보 타일 배경
    let yellow = Color(hex: 0xe8bf52)       // "변경" 버튼·코인
    let text = Color(hex: 0x2c2c2c)
    let textDim = Color(hex: 0x6b6357)
    let harvestReady = Color(hex: 0x7fbf5c) // 수확 가능 초록
    let harvestWait = Color(hex: 0xc2beb2)  // 아직 자라는 중 회색
    let pink = Color(hex: 0xf2b8c6)         // 키보드 아이콘 바탕
    let pinkKey = Color(hex: 0xe5738f)      // 키보드 아이콘 키

    static let shared = RetroTheme()
}

/// Galmuri11 픽셀 폰트. AppDelegate 가 런타임에 등록한 뒤 PostScript 이름으로 참조한다.
/// 등록 실패 시 SwiftUI 가 시스템 폰트로 대체하므로 레이아웃은 유지된다.
func galmuriFont(_ size: CGFloat) -> Font {
    .custom("Galmuri11-Regular", size: size)
}

// MARK: - 픽셀 농장 테마 (확장 화면 전용)
// 근거: claude.ai/design 시안 농장앱화면.dc.html 'garden-soft' 팔레트.

struct FarmPixelTheme {
    let border = Color(hex: 0x33321f)      // 카드 테두리·글자
    let panel = Color(hex: 0xe9dfc8)       // 카드 배경
    let cell = Color(hex: 0xf4ecd7)        // 타일/버튼 배경
    let inkDim = Color(hex: 0x8a8168)      // 보조 텍스트
    let bar = Color(hex: 0x2f4a44)         // 자원 바 배경
    let barText = Color(hex: 0xf4ecd7)     // 자원 바 텍스트
    let barDim = Color(hex: 0x6f8a82)      // 자원 바 구분선
    let primary = Color(hex: 0xd9583f)     // 활성 탭
    let primaryText = Color(hex: 0xfff8ef) // 활성 탭 텍스트
    let carrot = Color(hex: 0xc9a24a)      // 당근 새싹
    let cabbage = Color(hex: 0x8aad55)     // 양배추 새싹
    let tomato = Color(hex: 0xd9583f)
    let peach = Color(hex: 0xf09a82)
    let durian = Color(hex: 0xa69b45)

    static let shared = FarmPixelTheme()
}
