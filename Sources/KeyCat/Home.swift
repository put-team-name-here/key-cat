import AppKit
import Foundation
import SwiftUI

/// 확장 화면에서 이동할 수 있는 맵 위치.
enum MapLocation: String, CaseIterable, Identifiable {
    case field
    case home

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .field: return L10n.text("농장", "Field")
        case .home: return L10n.text("집", "Home")
        }
    }

    var navigationIconResource: String {
        switch self {
        case .field: return "icon_field"
        case .home: return "icon_home"
        }
    }
}

/// 창고 내부에서 선택하는 보관품 카테고리.
enum StorageCategory: String, CaseIterable, Identifiable {
    case seeds
    case crops
    case furniture

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .seeds: return L10n.text("씨앗", "Seeds")
        case .crops: return L10n.text("작물", "Crops")
        case .furniture: return L10n.text("가구", "Furniture")
        }
    }
}

enum FurnitureGroup: String, Hashable {
    case antique
    case farm
}

/// 상점과 창고에서 공통으로 사용하는 가구 상품 메타데이터.
struct FurnitureItem: Identifiable, Hashable {
    let id: String
    let resourceName: String
    let displayNameKorean: String
    let displayNameEnglish: String
    let purchasePrice: Int
    let group: FurnitureGroup

    var displayName: String {
        L10n.text(displayNameKorean, displayNameEnglish)
    }

    /// 256px 원본을 방의 한 칸보다 조금 크게 보여 주어 픽셀 아트 실루엣을 유지한다.
    var renderSize: CGFloat {
        group == .antique ? 124 : 116
    }
}

/// 제공된 개별 가구 PNG 39개를 상품 목록으로 연결한다.
enum FurnitureCatalog {
    private static let antiquePrices = [
        120, 50, 50, 80, 180, 150, 200, 240, 300, 350,
        90, 280, 240, 60, 100, 300, 220, 70, 100
    ]

    private static let farmPrices = [
        35, 60, 90, 45, 35, 30, 120, 70, 100, 40,
        35, 90, 80, 110, 30, 35, 100, 55, 40, 45
    ]

    static let all: [FurnitureItem] = makeItems(
        prefix: "antique",
        group: .antique,
        prices: antiquePrices
    ) + makeItems(
        prefix: "farm",
        group: .farm,
        prices: farmPrices
    )

    static func item(withID id: String) -> FurnitureItem? {
        all.first { $0.id == id }
    }

    private static func makeItems(
        prefix: String,
        group: FurnitureGroup,
        prices: [Int]
    ) -> [FurnitureItem] {
        prices.enumerated().map { offset, price in
            let number = String(format: "%02d", offset + 1)
            let id = "\(prefix)_256_\(number)"
            let koreanGroup = group == .antique ? "앤틱 가구" : "농장 가구"
            let englishGroup = group == .antique ? "Antique Furniture" : "Farm Furniture"
            return FurnitureItem(
                id: id,
                resourceName: id,
                displayNameKorean: "\(koreanGroup) \(number)",
                displayNameEnglish: "\(englishGroup) \(number)",
                purchasePrice: price,
                group: group
            )
        }
    }
}

/// 가구 종류별 보유 수량. 키는 상품 ID라서 새 가구를 추가해도 기존 저장 데이터와 호환된다.
struct FurnitureInventory: Codable {
    private var quantities: [String: Int] = [:]

    func count(of furniture: FurnitureItem) -> Int {
        quantities[furniture.id, default: 0]
    }

    @discardableResult
    mutating func add(_ furniture: FurnitureItem, quantity: Int = 1) -> Bool {
        guard quantity > 0 else { return false }
        let currentQuantity = quantities[furniture.id, default: 0]
        let (updatedQuantity, overflow) = currentQuantity.addingReportingOverflow(quantity)
        guard !overflow else { return false }
        quantities[furniture.id] = updatedQuantity
        return true
    }

    mutating func consume(_ furniture: FurnitureItem, quantity: Int = 1) -> Bool {
        guard quantity > 0, count(of: furniture) >= quantity else { return false }
        quantities[furniture.id, default: 0] -= quantity
        return true
    }
}

/// 집 바닥의 한 칸에 놓인 가구.
struct PlacedFurniture: Identifiable, Codable, Equatable {
    let id: UUID
    let furnitureID: String
    let row: Int
    let column: Int

    init(id: UUID = UUID(), furnitureID: String, row: Int, column: Int) {
        self.id = id
        self.furnitureID = furnitureID
        self.row = row
        self.column = column
    }
}

/// 집의 가구 배치 상태.
struct HomeData: Codable {
    static let cols = FarmFieldData.cols
    static let rows = FarmFieldData.rows

    var placedFurniture: [PlacedFurniture] = []

    func isValid(row: Int, column: Int) -> Bool {
        row >= 0 && row < Self.rows && column >= 0 && column < Self.cols
    }

    func isOccupied(row: Int, column: Int) -> Bool {
        placedFurniture.contains { $0.row == row && $0.column == column }
    }
}

/// 집 배치와 가구 보유량을 함께 저장하는 스냅샷.
///
/// 집과 가구 인벤토리를 같은 파일에 기록해 배치/반환 작업이 서로 다른
/// 저장소에 반쪽만 반영되는 상태를 피한다.
struct HomeStateSnapshot: Codable {
    var home: HomeData
    var furnitureInventory: FurnitureInventory
}

/// 집 배치 상태 JSON 저장소.
enum HomeStorage {
    private static var directoryURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("KeyCat", isDirectory: true)
    }

    private static var fileURL: URL {
        directoryURL.appendingPathComponent("home.json")
    }

    static func load(
        fallbackFurnitureInventory: FurnitureInventory = FurnitureInventory()
    ) -> HomeStateSnapshot {
        let fallback = HomeStateSnapshot(
            home: HomeData(),
            furnitureInventory: fallbackFurnitureInventory
        )
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: fileURL.path) else {
            _ = save(fallback)
            return fallback
        }

        // 읽기 실패는 기존 파일을 덮어쓰지 않고 현재 실행만 빈 상태로 연다.
        guard let data = try? Data(contentsOf: fileURL) else {
            return fallback
        }

        if let snapshot = try? JSONDecoder().decode(HomeStateSnapshot.self, from: data) {
            return snapshot
        }

        // 첫 구현에서 저장한 HomeData 형식은 가구 인벤토리와 함께 마이그레이션한다.
        if let legacyHome = try? JSONDecoder().decode(HomeData.self, from: data) {
            let migrated = HomeStateSnapshot(
                home: legacyHome,
                furnitureInventory: fallbackFurnitureInventory
            )
            _ = save(migrated)
            return migrated
        }

        // 손상된 파일은 백업 후에만 새 파일을 만들 수 있다. 백업에 실패하면
        // 다음 실행에서 복구를 시도할 수 있도록 원본을 그대로 보존한다.
        if quarantineCorruptFile() {
            _ = save(fallback)
        }
        return fallback
    }

    @discardableResult
    static func save(_ snapshot: HomeStateSnapshot) -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private static func quarantineCorruptFile() -> Bool {
        let backupURL = directoryURL.appendingPathComponent(
            "home.corrupt-\(UUID().uuidString).json"
        )
        do {
            try FileManager.default.moveItem(at: fileURL, to: backupURL)
            return true
        } catch {
            return false
        }
    }
}

enum FurnitureAssetCache {
    private static var cache: [String: NSImage] = [:]

    static func image(_ furniture: FurnitureItem) -> NSImage? {
        if let image = cache[furniture.resourceName] { return image }
        guard let url = AppResources.bundle.url(
            forResource: furniture.resourceName,
            withExtension: "png",
            subdirectory: "furniture"
        ),
        let image = NSImage(contentsOf: url)
        else { return nil }
        cache[furniture.resourceName] = image
        return image
    }
}

enum HomeAssetCache {
    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage? {
        if let image = cache[name] { return image }
        guard let url = AppResources.bundle.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "home"
        ),
        let image = NSImage(contentsOf: url)
        else { return nil }
        cache[name] = image
        return image
    }
}

enum NavigationDirection: Equatable {
    case left
    case right

    var normalResource: String {
        switch self {
        case .left: return "btn_left_normal"
        case .right: return "btn_right_normal"
        }
    }

    var pressedResource: String {
        switch self {
        case .left: return "btn_left_pressed"
        case .right: return "btn_right_pressed"
        }
    }
}

enum NavigationAssetCache {
    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage? {
        if let image = cache[name] { return image }
        guard let url = AppResources.bundle.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "navigation"
        ),
        let image = NSImage(contentsOf: url)
        else { return nil }
        cache[name] = image
        return image
    }
}

struct NavigationAssetButtonStyle: ButtonStyle {
    let direction: NavigationDirection
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let resource = configuration.isPressed
            ? direction.pressedResource
            : direction.normalResource

        return VStack(spacing: 0) {
            if let image = NavigationAssetCache.image(resource) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            } else {
                Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 30, height: 30)
            }
            configuration.label
        }
        .frame(width: 38, height: 62, alignment: .top)
        .contentShape(Rectangle())
        .opacity(isEnabled ? 1 : 0.55)
    }
}

struct FurnitureAssetImage: View {
    let furniture: FurnitureItem
    let size: CGFloat
    var isSilhouette = false

    var body: some View {
        if let image = FurnitureAssetCache.image(furniture) {
            if isSilhouette {
                Image(nsImage: image)
                    .resizable()
                    .renderingMode(.template)
                    .interpolation(.none)
                    .scaledToFit()
                    .foregroundStyle(Color.white.opacity(0.82))
                    .frame(width: size, height: size)
            } else {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: size, height: size)
            }
        } else {
            ZStack {
                Rectangle().fill(isSilhouette ? Color.white.opacity(0.82) : Color.black.opacity(0.12))
                Image(systemName: "chair.lounge")
                    .font(.system(size: size * 0.32))
                    .foregroundColor(isSilhouette ? .white : .secondary)
            }
            .frame(width: size, height: size)
        }
    }
}

/// 집 배치면의 마우스 이동과 클릭을 SwiftUI 좌표(좌상단 원점)로 전달한다.
/// 투명한 SwiftUI 제스처 대신 AppKit 이벤트를 직접 받아 픽셀 가구 위에서도
/// 포인터 추적과 배치 클릭이 일관되게 동작하도록 한다.
struct HomePointerTrackingView: NSViewRepresentable {
    let onPointerMove: (CGPoint) -> Void
    let onPointerExit: () -> Void
    let onTap: (CGPoint) -> Void

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        configure(view)
        return view
    }

    func updateNSView(_ nsView: TrackingView, context: Context) {
        configure(nsView)
    }

    private func configure(_ view: TrackingView) {
        view.onPointerMove = onPointerMove
        view.onPointerExit = onPointerExit
        view.onTap = onTap
    }

    final class TrackingView: NSView {
        var onPointerMove: (CGPoint) -> Void = { _ in }
        var onPointerExit: () -> Void = {}
        var onTap: (CGPoint) -> Void = { _ in }
        private var trackingArea: NSTrackingArea?

        override var isOpaque: Bool { false }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let trackingArea {
                removeTrackingArea(trackingArea)
            }

            let trackingArea = NSTrackingArea(
                rect: .zero,
                options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .mouseMoved],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(trackingArea)
            self.trackingArea = trackingArea
        }

        override func mouseMoved(with event: NSEvent) {
            onPointerMove(swiftUIPoint(for: event))
        }

        override func mouseEntered(with event: NSEvent) {
            onPointerMove(swiftUIPoint(for: event))
        }

        override func mouseExited(with event: NSEvent) {
            onPointerExit()
        }

        override func mouseDown(with event: NSEvent) {
            onPointerMove(swiftUIPoint(for: event))
        }

        override func mouseUp(with event: NSEvent) {
            onTap(swiftUIPoint(for: event))
        }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            true
        }

        private func swiftUIPoint(for event: NSEvent) -> CGPoint {
            let point = convert(event.locationInWindow, from: nil)
            return CGPoint(x: point.x, y: bounds.height - point.y)
        }
    }
}

struct HomeRoomView: View {
    static let tileSize: CGFloat = 45

    let home: HomeData
    let selectedFurniture: FurnitureItem?
    let selectedPlacedFurniture: PlacedFurniture?
    let hoveredTile: FarmTileCoordinate?
    let pointerLocation: CGPoint?

    private let tileSize: CGFloat = Self.tileSize
    private let roomWidth: CGFloat = CGFloat(HomeData.cols) * 45
    private let roomHeight: CGFloat = CGFloat(HomeData.rows) * 45

    var body: some View {
        ZStack(alignment: .topLeading) {
            woodFloor

            if let hoveredTile, previewFurniture != nil {
                hoveredTileHighlight(for: hoveredTile)
                    .zIndex(3)
            }

            ForEach(home.placedFurniture) { placed in
                if placed.id != selectedPlacedFurniture?.id,
                   let furniture = FurnitureCatalog.item(withID: placed.furnitureID) {
                    FurnitureAssetImage(
                        furniture: furniture,
                        size: furniture.renderSize
                    )
                    .allowsHitTesting(false)
                    .position(position(for: placed))
                    .zIndex(2 + Double(placed.row) / 100 + Double(placed.column) / 10_000)
                    .accessibilityHidden(true)
                }
            }

            if let furniture = previewFurniture,
               let pointerLocation {
                FurnitureAssetImage(
                    furniture: furniture,
                    size: furniture.renderSize,
                    isSilhouette: true
                )
                .position(pointerLocation)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .zIndex(4)
            }
        }
        .frame(width: roomWidth, height: roomHeight)
        .clipped()
    }

    @ViewBuilder
    private var woodFloor: some View {
        if let image = HomeAssetCache.image("middle_wood_floor_256") {
            ZStack(alignment: .topLeading) {
                ForEach(0..<3, id: \.self) { row in
                    ForEach(0..<2, id: \.self) { column in
                        Image(nsImage: image)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 256, height: 256)
                            .position(
                                x: CGFloat(column) * 256 + 128,
                                y: CGFloat(row) * 256 + 128
                            )
                    }
                }
            }
            .frame(width: roomWidth, height: roomHeight, alignment: .topLeading)
        } else {
            Color(hex: 0x9b704f)
        }
    }

    private var previewFurniture: FurnitureItem? {
        if let selectedFurniture {
            return selectedFurniture
        }
        guard let selectedPlacedFurniture else { return nil }
        return FurnitureCatalog.item(withID: selectedPlacedFurniture.furnitureID)
    }

    private func hoveredTileHighlight(for tile: FarmTileCoordinate) -> some View {
        let isSelectedFurnitureTile = selectedPlacedFurniture?.row == tile.row
            && selectedPlacedFurniture?.column == tile.column
        let isOccupied = home.isOccupied(row: tile.row, column: tile.column)
            && !isSelectedFurnitureTile

        return Rectangle()
            .fill(isOccupied ? Color.red.opacity(0.22) : Color.white.opacity(0.22))
            .overlay(
                Rectangle().strokeBorder(
                    isOccupied ? Color.red.opacity(0.85) : Color.white.opacity(0.9),
                    lineWidth: 2
                )
            )
            .frame(width: tileSize, height: tileSize)
            .position(Self.center(for: tile))
            .allowsHitTesting(false)
    }

    private func position(for placed: PlacedFurniture) -> CGPoint {
        Self.center(for: FarmTileCoordinate(row: placed.row, column: placed.column))
    }

    static func center(for tile: FarmTileCoordinate) -> CGPoint {
        CGPoint(
            x: (CGFloat(tile.column) + 0.5) * tileSize,
            y: (CGFloat(tile.row) + 0.5) * tileSize
        )
    }

    /// 화면 안의 포인터 좌표를 집 바닥의 배치 칸으로 바꾼다.
    static func tile(at point: CGPoint) -> FarmTileCoordinate? {
        let roomWidth = CGFloat(HomeData.cols) * tileSize
        let roomHeight = CGFloat(HomeData.rows) * tileSize
        guard point.x >= 0, point.x < roomWidth,
              point.y >= 0, point.y < roomHeight
        else { return nil }

        return FarmTileCoordinate(
            row: Int(point.y / tileSize),
            column: Int(point.x / tileSize)
        )
    }

    /// 실제 가구 이미지 전체를 기준으로 가장 앞에 보이는 가구를 찾는다.
    /// 한 타일보다 큰 가구의 가장자리를 눌러도 편집할 수 있어야 한다.
    static func placedFurniture(in home: HomeData, at point: CGPoint) -> PlacedFurniture? {
        home.placedFurniture
            .filter { placed in
                guard let furniture = FurnitureCatalog.item(withID: placed.furnitureID) else {
                    return false
                }
                let center = CGPoint(
                    x: (CGFloat(placed.column) + 0.5) * tileSize,
                    y: (CGFloat(placed.row) + 0.5) * tileSize
                )
                let halfSize = furniture.renderSize / 2
                return abs(point.x - center.x) <= halfSize
                    && abs(point.y - center.y) <= halfSize
            }
            .max { lhs, rhs in
                lhs.row == rhs.row ? lhs.column < rhs.column : lhs.row < rhs.row
            }
    }
}
