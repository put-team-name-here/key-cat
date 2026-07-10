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

// MARK: - 테마 팔레트 (stt-spike RHODES 이식)
// 근거: stt-spike/web/src/App.jsx THEMES.A(RHODES ISLAND)

struct Theme {
    let bg, bg2, panel, panelAlt, border, borderStrong: Color
    let accent, accentText, accentSoft, accent2: Color
    let text, textDim, textFaint, good, bad: Color
    let field, fieldCell: Color   // 늘어진(desaturated) 초록 밭 필드
    let brand: String

    static let rhodes = Theme(
        bg: Color(hex: 0xc6d3d7),
        bg2: Color(hex: 0xd8e1e4),
        panel: Color(hex: 0xeef3f4),
        panelAlt: Color(hex: 0xe3eaec),
        border: Color(hex: 0xabbac0),
        borderStrong: Color(hex: 0x889aa1),
        accent: Color(hex: 0xb23a32),
        accentText: Color(hex: 0xf7f3f0),
        accentSoft: Color(hex: 0xb23a32, alpha: 0.10),
        accent2: Color(hex: 0x3c4a50),
        text: Color(hex: 0x2a383e),
        textDim: Color(hex: 0x65747a),
        textFaint: Color(hex: 0x93a3a9),
        good: Color(hex: 0x2f7d56),
        bad: Color(hex: 0xb23a32),
        field: Color(hex: 0x8a9c82),
        fieldCell: Color(hex: 0xdbe2df),
        brand: "RHODES ISLAND"
    )
}

/// 모노스페이스 라벨 폰트 (JetBrains Mono 근사)
func monoFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .system(size: size, weight: weight, design: .monospaced)
}

// MARK: - 레트로 픽셀 테마 (축소 화면 전용)
// 근거: claude.ai/design 시안 축소화면.dc.html 팔레트.
// 확장 화면은 여전히 Theme.rhodes 를 쓰고, 이 팔레트는 collapsedView 에만 격리 적용한다.

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

// MARK: - 모서리 잘린 도형 (stt-spike clipPath polygon 대체)

struct CutCorner: Shape {
    var tl: CGFloat = 0
    var tr: CGFloat = 0
    var br: CGFloat = 0
    var bl: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: tl, y: 0))
        p.addLine(to: CGPoint(x: w - tr, y: 0))
        if tr > 0 { p.addLine(to: CGPoint(x: w, y: tr)) }
        p.addLine(to: CGPoint(x: w, y: h - br))
        if br > 0 { p.addLine(to: CGPoint(x: w - br, y: h)) }
        p.addLine(to: CGPoint(x: bl, y: h))
        if bl > 0 { p.addLine(to: CGPoint(x: 0, y: h - bl)) }
        p.addLine(to: CGPoint(x: 0, y: tl))
        p.closeSubpath()
        return p
    }
}

// MARK: - 모서리 L자 브래킷 (stt-spike .corner-* 장식 대체)

struct LBracket: View {
    enum Corner {
        case tl, tr, bl, br
        var alignment: Alignment {
            switch self {
            case .tl: return .topLeading
            case .tr: return .topTrailing
            case .bl: return .bottomLeading
            case .br: return .bottomTrailing
            }
        }
    }

    let corner: Corner
    var size: CGFloat = 16
    var thickness: CGFloat = 2
    let color: Color

    var body: some View {
        ZStack(alignment: corner.alignment) {
            Rectangle().fill(color).frame(width: size, height: thickness)
            Rectangle().fill(color).frame(width: thickness, height: size)
        }
        .frame(width: size, height: size, alignment: corner.alignment)
    }
}

extension View {
    /// 지정한 모서리에 러스트 L자 브래킷을 얹는다
    func cornerBrackets(_ corners: [LBracket.Corner], color: Color, size: CGFloat = 16) -> some View {
        overlay(
            ZStack {
                ForEach(Array(corners.enumerated()), id: \.offset) { _, c in
                    LBracket(corner: c, size: size, color: color)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: c.alignment)
                }
            }
            .allowsHitTesting(false)
        )
    }
}
