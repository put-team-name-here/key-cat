import Foundation

/// 사용자가 선택한 밭 타일의 행·열 좌표.
struct FarmTileCoordinate: Equatable, Hashable, Codable {
    let row: Int
    let column: Int
}

enum FarmWorkKind: Equatable {
    case watering
    case harvesting
    case fetchingSeeds
}

enum FarmBoundaryEdge {
    case top
    case bottom
    case left
    case right
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

struct FarmWorkTask: Equatable {
    let kind: FarmWorkKind
    let tile: FarmTileCoordinate
    let area: FarmArea

    init(kind: FarmWorkKind, tile: FarmTileCoordinate, area: FarmArea = .main) {
        self.kind = kind
        self.tile = tile
        self.area = area
    }
}

enum FarmArea: String, CaseIterable, Codable {
    case main
    case expansion
}

/// 밭 한 칸의 잔디 종류. grounds/ 리소스 이미지 선택에 쓰인다.
enum GrassKind: String, Codable {
    case normal
    case flower

    var imageName: String {
        switch self {
        case .normal: return "grass_tile_2"
        case .flower: return "grass_flower_tile_1"
        }
    }
}

/// 밭 한 칸의 파종 상태. rawValue로 저장되어 기존 empty 데이터와 호환된다.
enum FieldTileState: String, Codable {
    case empty
    case carrotSeed
    case cabbageSeed
    case tomatoSeed
    case peachSeed
    case durianSeed
    case wateredCarrotSeed
    case wateredCabbageSeed
    case wateredTomatoSeed
    case wateredPeachSeed
    case wateredDurianSeed
    case growingCarrot
    case growingCabbage
    case growingTomato
    case growingPeach
    case growingDurian
    case matureCarrot
    case matureCabbage
    case matureTomato
    case maturePeach
    case matureDurian

    var growthImageName: String? {
        switch self {
        case .empty: return nil
        case .carrotSeed: return "carrot_growth_01"
        case .wateredCarrotSeed: return "carrot_growth_01"
        case .growingCarrot: return "carrot_growth_02"
        case .matureCarrot: return "carrot_growth_03"
        case .cabbageSeed: return "cabbage_growth_01"
        case .wateredCabbageSeed: return "cabbage_growth_01"
        case .growingCabbage: return "cabbage_growth_02"
        case .matureCabbage: return "cabbage_growth_03"
        case .tomatoSeed: return "tomato_growth_01"
        case .wateredTomatoSeed: return "tomato_growth_01"
        case .growingTomato: return "tomato_growth_02"
        case .matureTomato: return "tomato_growth_03"
        case .peachSeed: return "peach_growth_01"
        case .wateredPeachSeed: return "peach_growth_01"
        case .growingPeach: return "peach_growth_02"
        case .maturePeach: return "peach_growth_03"
        case .durianSeed: return "durian_growth_01"
        case .wateredDurianSeed: return "durian_growth_01"
        case .growingDurian: return "durian_growth_02"
        case .matureDurian: return "durian_growth_03"
        }
    }

    var needsWater: Bool {
        switch self {
        case .carrotSeed, .cabbageSeed, .tomatoSeed, .peachSeed, .durianSeed: return true
        default: return false
        }
    }

    var isWatered: Bool {
        switch self {
        case .wateredCarrotSeed, .wateredCabbageSeed, .wateredTomatoSeed,
             .wateredPeachSeed, .wateredDurianSeed, .growingCarrot, .growingCabbage,
             .growingTomato, .growingPeach, .growingDurian, .matureCarrot,
             .matureCabbage, .matureTomato, .maturePeach, .matureDurian:
            return true
        default:
            return false
        }
    }

    var watered: FieldTileState {
        switch self {
        case .carrotSeed: return .wateredCarrotSeed
        case .cabbageSeed: return .wateredCabbageSeed
        case .tomatoSeed: return .wateredTomatoSeed
        case .peachSeed: return .wateredPeachSeed
        case .durianSeed: return .wateredDurianSeed
        default: return self
        }
    }

    var growingSeedKind: SeedKind? {
        switch self {
        case .wateredCarrotSeed, .growingCarrot: return .carrot
        case .wateredCabbageSeed, .growingCabbage: return .cabbage
        case .wateredTomatoSeed, .growingTomato: return .tomato
        case .wateredPeachSeed, .growingPeach: return .peach
        case .wateredDurianSeed, .growingDurian: return .durian
        default: return nil
        }
    }

    var nextGrowthStage: FieldTileState? {
        switch self {
        case .wateredCarrotSeed: return .growingCarrot
        case .wateredCabbageSeed: return .growingCabbage
        case .wateredTomatoSeed: return .growingTomato
        case .wateredPeachSeed: return .growingPeach
        case .wateredDurianSeed: return .growingDurian
        default: return nil
        }
    }

    var matureStage: FieldTileState? {
        switch self {
        case .wateredCarrotSeed, .growingCarrot: return .matureCarrot
        case .wateredCabbageSeed, .growingCabbage: return .matureCabbage
        case .wateredTomatoSeed, .growingTomato: return .matureTomato
        case .wateredPeachSeed, .growingPeach: return .maturePeach
        case .wateredDurianSeed, .growingDurian: return .matureDurian
        default: return nil
        }
    }

    var isMature: Bool {
        switch self {
        case .matureCarrot, .matureCabbage, .matureTomato, .maturePeach, .matureDurian: return true
        default: return false
        }
    }
}

struct FieldTile: Codable {
    var grass: GrassKind
    var state: FieldTileState
    /// 급수를 마친 시각. 시간 기반 성장 단계 계산에 사용한다.
    var wateredAt: Date? = nil
}

/// 밭 전체 레이아웃 + 칸별 상태. Application Support/KeyCat/farm.json 에 영속화된다.
struct FarmFieldData: Codable {
    static let cols = 8
    static let rows = 12
    static let dryGroundSize = 4
    static let dryGroundBottomMargin = 1
    /// 고양이집이 놓인 그리드 좌표 (x: 6, y: 3).
    static let catHouseCoordinate = FarmTileCoordinate(row: 3, column: 6)

    static var dryGroundCoordinates: [FarmTileCoordinate] {
        (0..<rows).flatMap { row in
            (0..<cols).compactMap { column in
                isDryGround(row: row, column: column)
                    ? FarmTileCoordinate(row: row, column: column)
                    : nil
            }
        }
    }

    var tiles: [FieldTile] // row-major, count == cols * rows

    func isValid(row: Int, column: Int) -> Bool {
        row >= 0 && row < Self.rows && column >= 0 && column < Self.cols
            && tiles.indices.contains(index(row: row, column: column))
    }

    func index(row: Int, column: Int) -> Int {
        row * Self.cols + column
    }

    /// 화면 중앙 하단에 배치한 4×4 밭 영역. 하단에는 잔디 한 줄을 남긴다.
    static func isDryGround(row: Int, column: Int) -> Bool {
        let startColumn = (cols - dryGroundSize) / 2
        let startRow = rows - dryGroundBottomMargin - dryGroundSize
        return column >= startColumn && column < startColumn + dryGroundSize
            && row >= startRow && row < startRow + dryGroundSize
    }

    /// 4×4 밭 바깥에서 상·하·좌·우로 바로 맞닿는 경계 타일 방향.
    static func dryGroundBoundaryEdge(row: Int, column: Int) -> FarmBoundaryEdge? {
        let startColumn = (cols - dryGroundSize) / 2
        let startRow = rows - dryGroundBottomMargin - dryGroundSize
        let endColumn = startColumn + dryGroundSize - 1
        let endRow = startRow + dryGroundSize - 1

        if row == startRow - 1, column == startColumn - 1 { return .topLeft }
        if row == startRow - 1, column == endColumn + 1 { return .topRight }
        if row == endRow + 1, column == startColumn - 1 { return .bottomLeft }
        if row == endRow + 1, column == endColumn + 1 { return .bottomRight }
        if row == startRow - 1, column >= startColumn, column <= endColumn { return .top }
        if row == endRow + 1, column >= startColumn, column <= endColumn { return .bottom }
        if column == startColumn - 1, row >= startRow, row <= endRow { return .left }
        if column == endColumn + 1, row >= startRow, row <= endRow { return .right }
        return nil
    }

    /// 경계 타일 바로 안쪽에서 맞닿는 밭 타일 좌표를 반환한다.
    static func adjacentDryGroundTile(for edge: FarmBoundaryEdge,
                                      boundaryRow row: Int,
                                      boundaryColumn column: Int) -> FarmTileCoordinate {
        let startColumn = (cols - dryGroundSize) / 2
        let startRow = rows - dryGroundBottomMargin - dryGroundSize
        let endColumn = startColumn + dryGroundSize - 1
        let endRow = startRow + dryGroundSize - 1

        switch edge {
        case .top: return FarmTileCoordinate(row: startRow, column: column)
        case .bottom: return FarmTileCoordinate(row: endRow, column: column)
        case .left: return FarmTileCoordinate(row: row, column: startColumn)
        case .right: return FarmTileCoordinate(row: row, column: endColumn)
        case .topLeft: return FarmTileCoordinate(row: startRow, column: startColumn)
        case .topRight: return FarmTileCoordinate(row: startRow, column: endColumn)
        case .bottomLeft: return FarmTileCoordinate(row: endRow, column: startColumn)
        case .bottomRight: return FarmTileCoordinate(row: endRow, column: endColumn)
        }
    }

    static func randomLayout() -> FarmFieldData {
        let tiles = (0..<(cols * rows)).map { _ in
            FieldTile(grass: Bool.random() ? .flower : .normal, state: .empty)
        }
        return FarmFieldData(tiles: tiles)
    }
}

enum ExpansionPlotPricing {
    static let prices = Array(repeating: 500_000, count: 16)

    static func price(for plotNumber: Int) -> Int? {
        guard prices.indices.contains(plotNumber - 1) else { return nil }
        return prices[plotNumber - 1]
    }
}

enum SeedPlantingPriority {
    static func nextSeed(preferred: SeedKind, available: [SeedKind]) -> SeedKind? {
        if available.contains(preferred) { return preferred }
        return SeedKind.allCases.first { available.contains($0) }
    }
}

struct ExpansionFarmData: Codable {
    var field: FarmFieldData
    private(set) var purchasedPlotCount: Int

    init(field: FarmFieldData = .randomLayout(), purchasedPlotCount: Int = 0) {
        self.field = field
        self.purchasedPlotCount = min(max(purchasedPlotCount, 0), ExpansionPlotPricing.prices.count)
    }

    var nextPlotNumber: Int? {
        let next = purchasedPlotCount + 1
        return ExpansionPlotPricing.prices.indices.contains(next - 1) ? next : nil
    }

    func plotNumber(row: Int, column: Int) -> Int? {
        FarmFieldData.dryGroundCoordinates.firstIndex {
            $0.row == row && $0.column == column
        }.map { $0 + 1 }
    }

    func isPurchased(row: Int, column: Int) -> Bool {
        guard let plotNumber = plotNumber(row: row, column: column) else { return false }
        return plotNumber <= purchasedPlotCount
    }

    mutating func purchaseNext(plotNumber: Int) -> Bool {
        guard plotNumber == nextPlotNumber else { return false }
        purchasedPlotCount += 1
        return true
    }
}

/// 밭 JSON 파일 읽기/쓰기. 파일이 없으면 랜덤 배치로 새로 만들어 저장한다.
enum FarmFieldStorage {
    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("KeyCat", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("farm.json")
    }

    static func load() -> FarmFieldData {
        guard let data = try? Data(contentsOf: fileURL),
              let field = try? JSONDecoder().decode(FarmFieldData.self, from: data)
        else {
            let field = FarmFieldData.randomLayout()
            save(field)
            return field
        }
        return field
    }

    static func save(_ field: FarmFieldData) {
        guard let data = try? JSONEncoder().encode(field) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

enum ExpansionFarmStorage {
    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("KeyCat", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("expansion-farm.json")
    }

    static func load() -> ExpansionFarmData {
        guard let data = try? Data(contentsOf: fileURL),
              let field = try? JSONDecoder().decode(ExpansionFarmData.self, from: data)
        else {
            let field = ExpansionFarmData()
            save(field)
            return field
        }
        return field
    }

    static func save(_ field: ExpansionFarmData) {
        guard let data = try? JSONEncoder().encode(field) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
