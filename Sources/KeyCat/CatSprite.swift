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
    let wateringSheet: String
    let wateringRows: Int
    let wateringFrameCount: Int
    let harvestSheet: String
}

enum CatCatalog {
    /// assets/cats/ 6종을 Resources/cats/ 로 정규화해 이식한 목록.
    static let all: [CatCharacter] = [
        .init(id: "cheese", name: "치즈", front: "cheese_front", leftSheet: "cheese_side", rightSheet: nil,
              wateringSheet: "cheese_watering", wateringRows: 2, wateringFrameCount: 6, harvestSheet: "cheese_harvest"),
        .init(id: "gray", name: "그레이", front: "gray_front", leftSheet: "gray_side", rightSheet: nil,
              wateringSheet: "gray_watering", wateringRows: 2, wateringFrameCount: 6, harvestSheet: "gray_harvest"),
        .init(id: "siamese", name: "샴", front: "siamese_front", leftSheet: "siamese_side", rightSheet: nil,
              wateringSheet: "siamese_watering", wateringRows: 2, wateringFrameCount: 6, harvestSheet: "siamese_harvest"),
        .init(id: "sphynx", name: "스핑크스", front: "sphynx_front", leftSheet: "sphynx_side", rightSheet: nil,
              wateringSheet: "sphynx_watering", wateringRows: 3, wateringFrameCount: 8, harvestSheet: "sphynx_harvest"),
        .init(id: "tuxedo", name: "턱시도", front: "tuxedo_front", leftSheet: "tuxedo_side", rightSheet: nil,
              wateringSheet: "tuxedo_watering", wateringRows: 3, wateringFrameCount: 8, harvestSheet: "tuxedo_harvest"),
        .init(id: "oddeye", name: "오드아이", front: "oddeye_front", leftSheet: "oddeye_left", rightSheet: "oddeye_right",
              wateringSheet: "oddeye_watering", wateringRows: 3, wateringFrameCount: 8, harvestSheet: "oddeye_harvest"),
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

    static func sheet(_ resource: String,
                      columns: Int = 3,
                      rows: Int = 3,
                      frameCount: Int = 8) -> SpriteSheet? {
        let key = "\(resource)-\(columns)x\(rows)-\(frameCount)"
        if let s = cache[key] { return s }
        guard let s = SpriteSheet(resource: resource,
                                  columns: columns,
                                  rows: rows,
                                  frameCount: frameCount) else { return nil }
        cache[key] = s
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

/// grounds/ 잔디 타일 PNG 한 칸을 그린다. 로드 실패 시 초록색으로 대체.
@ViewBuilder func groundTile(_ name: String) -> some View {
    if let img = GroundCache.image(name) {
        Image(nsImage: img)
            .resizable()
            .interpolation(.none)   // 픽셀 아트라 보간 없이 또렷하게
    } else {
        RetroTheme.shared.harvestReady
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
                            groundTile((r + c) % 2 == 0 ? "grass_tile_2" : "grass_flower_tile_1")
                                .frame(width: tileSize, height: tileSize)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .clipped()
    }
}

/// 밭(확장 화면) 잔디 배경. 체커보드 대신 FarmFieldData 에 저장된 랜덤 배치를 그대로 그린다.
struct FarmFieldGrassView: View {
    let field: FarmFieldData
    var tileSize: CGFloat = 45
    var onDryGroundTap: (_ row: Int, _ column: Int) -> Void = { _, _ in }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<FarmFieldData.rows, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<FarmFieldData.cols, id: \.self) { c in
                        if FarmFieldData.isDryGround(row: r, column: c) {
                            let tileState = field.tiles[field.index(row: r, column: c)].state
                            Button(action: {
                                if tileState == .empty {
                                    onDryGroundTap(r, c)
                                }
                            }) {
                                ZStack {
                                    groundTile(tileState.isWatered ? "wet_ground" : "dry_ground")
                                    if let imageName = tileState.growthImageName {
                                        groundTile(imageName)
                                    }
                                }
                                .frame(width: tileSize, height: tileSize)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("밭 \(r + 1)행 \(c + 1)열")
                        } else {
                            groundTile(field.tiles[r * FarmFieldData.cols + c].grass.imageName)
                                .frame(width: tileSize, height: tileSize)
                        }
                    }
                }
            }
        }
        .clipped()
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
    @Published private(set) var activity: FarmWorkKind?

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
    private var workElapsed: CGFloat = 0
    private var workCompletion: (() -> Void)?

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

    /// 자유 배회를 멈추고 지정한 밭 타일로 이동해 급수 또는 수확 작업을 시작한다.
    func perform(_ work: FarmWorkKind, at point: CGPoint, onComplete: @escaping () -> Void) {
        target = point
        pendingWork = work
        workCompletion = onComplete
        activity = nil
        workElapsed = 0
        pause = 0

        let dx = point.x - position.x
        let dy = point.y - position.y
        if dy > abs(dx) {
            facing = .down
        } else {
            facing = dx >= 0 ? .right : .left
        }
    }

    private func step() {
        guard configured else { return }
        let now = CFAbsoluteTimeGetCurrent()
        let dt = min(CGFloat(now - lastTick), 0.05)
        lastTick = now

        if activity != nil {
            workElapsed += dt
            frameAccum += dt
            if frameAccum >= frameInterval {
                frameAccum -= frameInterval
                frame = (frame + 1) % 8
            }
            if workElapsed >= 1.4 {
                let completion = workCompletion
                workCompletion = nil
                activity = nil
                pendingWork = nil
                workElapsed = 0
                frame = 0
                pickTarget()
                completion?()
            }
            return
        }

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
            if workCompletion != nil {
                // perform에서 지정한 작업 종류는 이동이 끝난 순간 활성화한다.
                activity = pendingWork
                workElapsed = 0
                frameAccum = 0
                frame = 0
                return
            }
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

    private var pendingWork: FarmWorkKind?

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
    let farmTask: FarmWorkTask?
    let farmTileSize: CGFloat
    let onFarmTaskComplete: (FarmWorkTask) -> Void
    @StateObject private var motion: CatMotion

    /// - Parameters:
    ///   - fps: 걷기 프레임 교체 속도(초당 프레임). 낮을수록 뚝뚝 끊긴다.
    init(character: CatCharacter,
         spriteSize: CGFloat = 46,
         fps: CGFloat = 9,
         speed: CGFloat = 26,
         farmTask: FarmWorkTask? = nil,
         farmTileSize: CGFloat = 45,
         onFarmTaskComplete: @escaping (FarmWorkTask) -> Void = { _ in }) {
        self.character = character
        self.spriteSize = spriteSize
        self.farmTask = farmTask
        self.farmTileSize = farmTileSize
        self.onFarmTaskComplete = onFarmTaskComplete
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
                    updateFarmTask()
                }
                .onDisappear { motion.stop() }
                .onChange(of: geo.size) { newSize in
                    motion.configure(bounds: newSize, sprite: spriteSize)
                }
                .onChange(of: farmTask) { _, _ in
                    updateFarmTask()
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
        if let activity = motion.activity {
            workSprite(activity)
        } else {
            walkingSprite
        }
    }

    @ViewBuilder private func workSprite(_ activity: FarmWorkKind) -> some View {
        let sheet: SpriteSheet? = {
            switch activity {
            case .watering:
                return SpriteCache.sheet(character.wateringSheet,
                                         rows: character.wateringRows,
                                         frameCount: character.wateringFrameCount)
            case .harvesting:
                return SpriteCache.sheet(character.harvestSheet, rows: 3, frameCount: 8)
            }
        }()
        if let frames = sheet?.frames, !frames.isEmpty {
            frames[motion.frame % frames.count]
                .resizable()
                .interpolation(.none)
                .scaledToFit()
        } else {
            Rectangle().fill(Color.black.opacity(0.25))
        }
    }

    @ViewBuilder private var walkingSprite: some View {
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

    private func updateFarmTask() {
        guard let task = farmTask else { return }
        let verticalOffset = task.kind == .watering
            ? spriteSize * 0.22
            : spriteSize * 0.12 + 10
        let point = CGPoint(x: (CGFloat(task.tile.column) + 0.5) * farmTileSize,
                            y: (CGFloat(task.tile.row) + 0.5) * farmTileSize - verticalOffset)
        motion.perform(task.kind, at: point) {
            onFarmTaskComplete(task)
        }
    }
}
