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
