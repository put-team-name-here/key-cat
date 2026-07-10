import Foundation

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

/// 밭 한 칸의 상태. 작물 시스템 연결 전이라 지금은 empty만 존재한다.
enum FieldTileState: String, Codable {
    case empty
}

struct FieldTile: Codable {
    var grass: GrassKind
    var state: FieldTileState
}

/// 밭 전체 레이아웃 + 칸별 상태. Application Support/KeyCat/farm.json 에 영속화된다.
struct FarmFieldData: Codable {
    static let cols = 8
    static let rows = 12

    var tiles: [FieldTile] // row-major, count == cols * rows

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
