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

struct FarmWorkTask: Equatable {
    let kind: FarmWorkKind
    let tile: FarmTileCoordinate
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
    case wateredCarrotSeed
    case wateredCabbageSeed
    case growingCarrot
    case growingCabbage
    case matureCarrot
    case matureCabbage

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
        }
    }

    var needsWater: Bool {
        self == .carrotSeed || self == .cabbageSeed
    }

    var isWatered: Bool {
        self == .wateredCarrotSeed || self == .wateredCabbageSeed
            || self == .growingCarrot || self == .growingCabbage
            || self == .matureCarrot || self == .matureCabbage
    }

    var watered: FieldTileState {
        switch self {
        case .carrotSeed: return .wateredCarrotSeed
        case .cabbageSeed: return .wateredCabbageSeed
        default: return self
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

    static func randomLayout() -> FarmFieldData {
        let tiles = (0..<(cols * rows)).map { _ in
            FieldTile(grass: Bool.random() ? .flower : .normal, state: .empty)
        }
        return FarmFieldData(tiles: tiles)
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
