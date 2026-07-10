import SwiftUI
import AppKit

// MARK: - 고양이 캐릭터 카탈로그

/// 축소 화면에서 순환 선택하는 고양이 한 종의 스프라이트 메타데이터.
/// 대부분의 고양이는 옆모습 시트 한 장을 좌우 반전해 양방향을 표현하지만,
/// 오드아이처럼 좌우 눈 색이 다른 고양이는 반전하면 눈 색이 뒤바뀌므로
/// 왼쪽/오른쪽 시트를 따로 둔다(`rightSheet` 지정 시 반전하지 않음).
struct CatCharacter: Identifiable {
    let id: String        // UserDefaults 저장용 안정 키
    let name: String      // 접근성 라벨용 표시 이름
    let front: String     // 정면(아래로 걷기) 시트 리소스명
    let leftSheet: String // 왼쪽 걷기 시트
    let rightSheet: String? // 오른쪽 전용 시트, nil이면 leftSheet를 좌우 반전
}

enum CatCatalog {
    /// assets/cats/ 6종을 Resources/cats/ 로 정규화해 이식한 목록.
    static let all: [CatCharacter] = [
        .init(id: "cheese",  name: "치즈",    front: "cheese_front",  leftSheet: "cheese_side",  rightSheet: nil),
        .init(id: "gray",    name: "그레이",  front: "gray_front",    leftSheet: "gray_side",    rightSheet: nil),
        .init(id: "siamese", name: "샴",      front: "siamese_front", leftSheet: "siamese_side", rightSheet: nil),
        .init(id: "sphynx",  name: "스핑크스", front: "sphynx_front",  leftSheet: "sphynx_side",  rightSheet: nil),
        .init(id: "tuxedo",  name: "턱시도",  front: "tuxedo_front",  leftSheet: "tuxedo_side",  rightSheet: nil),
        .init(id: "oddeye",  name: "오드아이", front: "oddeye_front",  leftSheet: "oddeye_left",  rightSheet: "oddeye_right"),
    ]
}

// MARK: - 스프라이트 시트 (384x384, 3x3 격자, 8프레임)

/// 시트 PNG 하나를 128x128 프레임 배열로 잘라 들고 있는 값 객체.
struct SpriteSheet {
    let frames: [Image]

    init?(resource: String, columns: Int = 3, rows: Int = 3, frameCount: Int = 8) {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "png", subdirectory: "cats"),
              let nsImg = NSImage(contentsOf: url),
              let cg = nsImg.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }

        let fw = cg.width / columns
        let fh = cg.height / rows
        var out: [Image] = []
        for i in 0..<frameCount {
            let c = i % columns
            let r = i / columns
            let rect = CGRect(x: c * fw, y: r * fh, width: fw, height: fh)
            guard let sub = cg.cropping(to: rect) else { continue }
            let ns = NSImage(cgImage: sub, size: NSSize(width: fw, height: fh))
            out.append(Image(nsImage: ns))
        }
        guard !out.isEmpty else { return nil }
        self.frames = out
    }
}

/// 리소스명 기준 시트 캐시. 캐릭터를 바꿔도 이미 자른 시트는 재사용한다.
enum SpriteCache {
    private static var cache: [String: SpriteSheet] = [:]

    static func sheet(_ resource: String) -> SpriteSheet? {
        if let s = cache[resource] { return s }
        guard let s = SpriteSheet(resource: resource) else { return nil }
        cache[resource] = s
        return s
    }
}

// MARK: - 잔디 타일 배경

/// grounds/ 잔디 타일 PNG 캐시. 리소스명 기준 1회 로드 후 재사용.
enum GroundCache {
    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage? {
        if let i = cache[name] { return i }
        guard let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "grounds"),
              let img = NSImage(contentsOf: url) else { return nil }
        cache[name] = img
        return img
    }
}

/// 고양이 박스 잔디밭 배경. 짙은 잔디(grass_tile_2)와 꽃 잔디(grass_flower_tile_1)를
/// 체커보드로 번갈아 깔아 "꽃이 드문드문 핀 잔디밭"을 만든다(시안 대각 줄무늬 대체).
struct GrassBackground: View {
    var tileSize: CGFloat = 64   // 원본 타일 픽셀 크기

    var body: some View {
        GeometryReader { geo in
            let cols = max(1, Int(ceil(geo.size.width / tileSize)))
            let rows = max(1, Int(ceil(geo.size.height / tileSize)))
            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<cols, id: \.self) { c in
                            tile((r + c) % 2 == 0 ? "grass_tile_2" : "grass_flower_tile_1")
                                .frame(width: tileSize, height: tileSize)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .clipped()
    }

    @ViewBuilder private func tile(_ name: String) -> some View {
        if let img = GroundCache.image(name) {
            Image(nsImage: img)
                .resizable()
                .interpolation(.none)   // 픽셀 아트라 보간 없이 또렷하게
        } else {
            RetroTheme.shared.harvestReady   // 로드 실패 시 초록 대체
        }
    }
}

// MARK: - 배회 모션 모델 (위치 적분 + 걷기 프레임 순환)

/// 뷰와 분리한 고양이 이동 두뇌. 60fps 타이머로 위치를 적분하고
/// 목표 지점 도달 시 잠깐 멈췄다가 새 목표를 고른다. 타이핑과는 무관.
final class CatMotion: ObservableObject {
    enum Facing { case left, right, down }

    @Published private(set) var position = CGPoint(x: 40, y: 40)
    @Published private(set) var facing: Facing = .down
    @Published private(set) var frame = 0      // 0..<8
    @Published private(set) var moving = false

    private let speed: CGFloat                 // pt/sec
    private let frameInterval: CGFloat         // 걷기 프레임 교체 간격(초). 작을수록 높은 fps
    private var bounds = CGSize.zero
    private var margin: CGFloat = 30
    private var target = CGPoint.zero
    private var frameAccum: CGFloat = 0
    private var pause: CGFloat = 0
    private var configured = false
    private var lastTick: CFAbsoluteTime = 0
    private var timer: Timer?

    init(frameInterval: CGFloat, speed: CGFloat = 26) {
        self.frameInterval = frameInterval
        self.speed = speed
    }

    /// 배회 영역과 스프라이트 크기를 알려준다. 최초 1회만 위치를 초기화.
    func configure(bounds: CGSize, sprite: CGFloat) {
        self.bounds = bounds
        self.margin = sprite / 2 + 2
        if !configured, bounds.width > 0, bounds.height > 0 {
            configured = true
            position = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.55)
            pickTarget()
        }
    }

    func start() {
        stop()
        lastTick = CFAbsoluteTimeGetCurrent()
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in self?.step() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func step() {
        guard configured else { return }
        let now = CFAbsoluteTimeGetCurrent()
        let dt = min(CGFloat(now - lastTick), 0.05)
        lastTick = now

        if pause > 0 {
            pause -= dt
            if moving { moving = false }
            return
        }

        let dx = target.x - position.x
        let dy = target.y - position.y
        let dist = hypot(dx, dy)
        if dist < 2 {
            moving = false
            pause = CGFloat.random(in: 0.4...1.8)
            pickTarget()
            return
        }

        moving = true
        let stepLen = speed * dt
        position = CGPoint(x: position.x + dx / dist * stepLen,
                           y: position.y + dy / dist * stepLen)

        frameAccum += dt
        if frameAccum >= frameInterval {
            frameAccum -= frameInterval
            frame = (frame + 1) % 8
        }
    }

    /// 새 목표 지점을 고르고, 이동 방향에서 바라보는 방향(옆/아래)을 정한다.
    private func pickTarget() {
        let hi = max(margin, bounds.width - margin)
        let vi = max(margin, bounds.height - margin)
        let tx = CGFloat.random(in: margin...hi)
        let ty = CGFloat.random(in: margin...vi)
        target = CGPoint(x: tx, y: ty)

        let dx = tx - position.x
        let dy = ty - position.y
        // 아래로 향하는 세로 이동이 지배적이면 정면(아래) 시트, 그 외에는 측면 시트.
        if dy > abs(dx) {
            facing = .down
        } else {
            facing = dx >= 0 ? .right : .left
        }
    }
}

// MARK: - 배회하는 고양이 뷰

/// 지정한 영역을 자유롭게 돌아다니는 애니메이션 고양이.
/// 캐릭터 카탈로그에서 정면/좌/우 시트를 골라 방향에 맞춰 렌더링한다.
struct WalkingCat: View {
    let character: CatCharacter
    let spriteSize: CGFloat
    @StateObject private var motion: CatMotion

    /// - Parameters:
    ///   - fps: 걷기 프레임 교체 속도(초당 프레임). 낮을수록 뚝뚝 끊긴다.
    init(character: CatCharacter, spriteSize: CGFloat = 46, fps: CGFloat = 9, speed: CGFloat = 26) {
        self.character = character
        self.spriteSize = spriteSize
        _motion = StateObject(wrappedValue: CatMotion(frameInterval: 1.0 / fps, speed: speed))
    }

    var body: some View {
        GeometryReader { geo in
            sprite
                .frame(width: spriteSize, height: spriteSize)
                .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                .position(motion.position)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                .onAppear {
                    motion.configure(bounds: geo.size, sprite: spriteSize)
                    motion.start()
                }
                .onDisappear { motion.stop() }
                .onChange(of: geo.size) { newSize in
                    motion.configure(bounds: newSize, sprite: spriteSize)
                }
        }
        .accessibilityLabel("\(character.name) 고양이")
    }

    /// 오른쪽 전용 시트가 없을 때만 오른쪽 이동에서 좌우 반전한다.
    private var mirrored: Bool {
        motion.facing == .right && character.rightSheet == nil
    }

    /// 현재 방향/프레임에 맞는 한 장.
    @ViewBuilder private var sprite: some View {
        let resource: String = {
            switch motion.facing {
            case .down:  return character.front
            case .left:  return character.leftSheet
            case .right: return character.rightSheet ?? character.leftSheet
            }
        }()
        let idx = motion.moving ? motion.frame : 0
        if let frames = SpriteCache.sheet(resource)?.frames, idx < frames.count {
            frames[idx]
                .resizable()
                .interpolation(.none)   // 픽셀 아트라 보간 없이 또렷하게
                .scaledToFit()
        } else {
            // 시트 로드 실패 시 자리표시 사각형
            Rectangle().fill(Color.black.opacity(0.25))
        }
    }
}