import Foundation

/// 확장 화면 하단 탭.
enum FarmTab: String, CaseIterable, Identifiable {
    case shop = "상점"
    case storage = "창고"
    case codex = "도감"
    case log = "기록"

    var id: String { rawValue }
}

/// 도감 내부 카테고리.
enum CodexCategory: String, CaseIterable, Identifiable {
    case crops = "작물"
    case cats = "고양이"

    var id: String { rawValue }
}

/// 상점에서 구매하고 창고에 보관하는 씨앗 종류.
enum SeedKind: String, CaseIterable, Codable, Identifiable {
    case carrot
    case cabbage

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .carrot: return "당근 씨앗"
        case .cabbage: return "양배추 씨앗"
        }
    }

    var fieldState: FieldTileState {
        switch self {
        case .carrot: return .carrotSeed
        case .cabbage: return .cabbageSeed
        }
    }

    var growthImageName: String {
        switch self {
        case .carrot: return "carrot_growth_01"
        case .cabbage: return "cabbage_growth_01"
        }
    }
}

/// 씨앗 종류별 보유 수량. 새 종류가 추가되어도 기존 저장 데이터와 호환된다.
struct SeedInventory: Codable {
    private var quantities: [SeedKind: Int] = [:]

    func count(of seed: SeedKind) -> Int {
        quantities[seed, default: 0]
    }

    mutating func add(_ seed: SeedKind, quantity: Int = 1) {
        quantities[seed, default: 0] += quantity
    }

    mutating func consume(_ seed: SeedKind) -> Bool {
        guard count(of: seed) > 0 else { return false }
        quantities[seed, default: 0] -= 1
        return true
    }
}

enum CropKind: String, CaseIterable, Codable, Identifiable {
    case carrot
    case cabbage

    /// SeedKind와 같은 그리드에 표시되므로 서로 다른 식별자 공간을 사용한다.
    var id: String { "crop-\(rawValue)" }

    var displayName: String {
        switch self {
        case .carrot: return "당근"
        case .cabbage: return "양배추"
        }
    }

    var imageName: String { rawValue }

    var salePrice: Int {
        switch self {
        case .carrot: return 10
        case .cabbage: return 35
        }
    }
}

struct CropInventory: Codable {
    private var quantities: [CropKind: Int] = [:]

    func count(of crop: CropKind) -> Int {
        quantities[crop, default: 0]
    }

    mutating func add(_ crop: CropKind) {
        quantities[crop, default: 0] += 1
    }

    mutating func consume(_ crop: CropKind, quantity: Int = 1) -> Bool {
        guard quantity > 0, count(of: crop) >= quantity else { return false }
        quantities[crop, default: 0] -= quantity
        return true
    }
}

/// 축소/확장 + 농장 자원 상태를 담는 가벼운 상태 객체
final class AppState: ObservableObject {
    private static let cropGrowthInterval: TimeInterval = 5
    @Published var expanded = false
    /// 최초 30코인으로 시작하며 판매로 변경될 때마다 저장한다.
    @Published private(set) var coins: Int {
        didSet { UserDefaults.standard.set(coins, forKey: coinsKey) }
    }
    /// 수확 가능 여부 (수확 시스템 연결 전 자리표시)
    @Published var harvestAvailable = false

    /// 확장 화면에서 선택한 하단 탭
    @Published var selectedFarmTab: FarmTab = .shop
    /// 도감 화면에서 선택한 내부 카테고리
    @Published var selectedCodexCategory: CodexCategory = .crops

    /// 축소 화면에서 순환 선택 중인 고양이 인덱스 (CatCatalog.all 기준)
    @Published var selectedCatIndex: Int

    /// 밭 잔디 배치 + 칸별 상태. farm.json 에서 복원하고, 바뀔 때마다 다시 저장한다.
    @Published var farmField: FarmFieldData {
        didSet { FarmFieldStorage.save(farmField) }
    }

    /// 상점에서 구매한 씨앗. 변경될 때마다 UserDefaults에 저장한다.
    @Published private(set) var seedInventory: SeedInventory {
        didSet { saveSeedInventory() }
    }

    @Published private(set) var cropInventory: CropInventory {
        didSet { saveCropInventory() }
    }

    /// 발생 순서대로 고양이가 처리할 급수·수확 작업 큐.
    @Published private(set) var farmWorkQueue: [FarmWorkTask] = [] {
        didSet { harvestAvailable = farmWorkQueue.contains { $0.kind == .harvesting } }
    }

    private let catKey = "selectedCatId"
    private let coinsKey = "coins"
    private let seedInventoryKey = "seedInventory"
    private let cropInventoryKey = "cropInventory"
    private var growthTimer: Timer?

    init() {
        if UserDefaults.standard.object(forKey: coinsKey) == nil {
            coins = 30
        } else {
            coins = UserDefaults.standard.integer(forKey: coinsKey)
        }
        // 마지막으로 고른 고양이를 id 로 복원. 없거나 못 찾으면 첫 번째.
        if let savedId = UserDefaults.standard.string(forKey: catKey),
           let idx = CatCatalog.all.firstIndex(where: { $0.id == savedId }) {
            selectedCatIndex = idx
        } else {
            selectedCatIndex = 0
        }
        if let data = UserDefaults.standard.data(forKey: seedInventoryKey),
           let inventory = try? JSONDecoder().decode(SeedInventory.self, from: data) {
            seedInventory = inventory
        } else {
            seedInventory = SeedInventory()
        }
        if let data = UserDefaults.standard.data(forKey: cropInventoryKey),
           let inventory = try? JSONDecoder().decode(CropInventory.self, from: data) {
            cropInventory = inventory
        } else {
            cropInventory = CropInventory()
        }
        var loadedField = FarmFieldStorage.load()
        // 이전 버전에서 이미 물을 준 작물은 현재 시점부터 성장을 시작한다.
        for index in loadedField.tiles.indices
        where (loadedField.tiles[index].state == .wateredCarrotSeed
            || loadedField.tiles[index].state == .wateredCabbageSeed
            || loadedField.tiles[index].state == .growingCarrot
            || loadedField.tiles[index].state == .growingCabbage)
            && loadedField.tiles[index].wateredAt == nil {
            loadedField.tiles[index].wateredAt = Date()
        }
        FarmFieldStorage.save(loadedField)
        farmField = loadedField
        farmWorkQueue = farmField.tiles.enumerated().compactMap { index, tile in
            let coordinate = FarmTileCoordinate(row: index / FarmFieldData.cols,
                                                column: index % FarmFieldData.cols)
            if tile.state.needsWater {
                return FarmWorkTask(kind: .watering, tile: coordinate)
            }
            if tile.state == .matureCarrot || tile.state == .matureCabbage {
                return FarmWorkTask(kind: .harvesting, tile: coordinate)
            }
            return nil
        }
        harvestAvailable = farmWorkQueue.contains { $0.kind == .harvesting }
        startGrowthTimer()
    }

    /// 현재 선택된 고양이 캐릭터
    var selectedCat: CatCharacter { CatCatalog.all[selectedCatIndex] }

    /// "변경" 버튼: 다음 고양이로 순환하고 선택을 영속화
    func cycleCat() {
        selectedCatIndex = (selectedCatIndex + 1) % CatCatalog.all.count
        UserDefaults.standard.set(selectedCat.id, forKey: catKey)
    }

    /// 현재 상점 가격(0코인)으로 씨앗 한 개를 구매한다.
    func purchase(_ seed: SeedKind) {
        seedInventory.add(seed)
    }

    func seedCount(_ seed: SeedKind) -> Int {
        seedInventory.count(of: seed)
    }

    func cropCount(_ crop: CropKind) -> Int {
        cropInventory.count(of: crop)
    }

    /// 창고의 작물을 선택한 수량만큼 판매하고 판매 대금을 코인에 더한다.
    @discardableResult
    func sell(_ crop: CropKind, quantity: Int) -> Bool {
        var updatedInventory = cropInventory
        guard updatedInventory.consume(crop, quantity: quantity) else { return false }
        cropInventory = updatedInventory
        coins += crop.salePrice * quantity
        return true
    }

    /// 빈 밭 타일에 씨앗 하나를 심고 창고 수량을 차감한다.
    @discardableResult
    func plant(_ seed: SeedKind, at tile: FarmTileCoordinate) -> Bool {
        guard FarmFieldData.isDryGround(row: tile.row, column: tile.column),
              farmField.isValid(row: tile.row, column: tile.column)
        else { return false }

        let index = farmField.index(row: tile.row, column: tile.column)
        guard farmField.tiles[index].state == .empty,
              seedInventory.consume(seed)
        else { return false }

        farmField.tiles[index].state = seed.fieldState
        farmField.tiles[index].wateredAt = nil
        farmWorkQueue.append(FarmWorkTask(kind: .watering, tile: tile))
        return true
    }

    func completeFarmWork(_ task: FarmWorkTask) {
        switch task.kind {
        case .watering:
            completeWatering(at: task.tile)
        case .harvesting:
            completeHarvest(at: task.tile)
        }
        if farmWorkQueue.first == task {
            farmWorkQueue.removeFirst()
        } else {
            farmWorkQueue.removeAll { $0 == task }
        }
    }

    /// 급수가 끝난 타일을 젖은 밭으로 바꾼다.
    private func completeWatering(at tile: FarmTileCoordinate) {
        guard farmField.isValid(row: tile.row, column: tile.column) else { return }
        let index = farmField.index(row: tile.row, column: tile.column)
        guard farmField.tiles[index].state.needsWater else { return }
        var updatedField = farmField
        updatedField.tiles[index].state = updatedField.tiles[index].state.watered
        if updatedField.tiles[index].state == .wateredCarrotSeed
            || updatedField.tiles[index].state == .wateredCabbageSeed {
            updatedField.tiles[index].wateredAt = Date()
        }
        farmField = updatedField
    }

    /// 완전히 자란 작물을 창고로 옮기고 타일을 빈 밭으로 되돌린다.
    private func completeHarvest(at tile: FarmTileCoordinate) {
        guard farmField.isValid(row: tile.row, column: tile.column) else { return }
        let index = farmField.index(row: tile.row, column: tile.column)
        let crop: CropKind
        switch farmField.tiles[index].state {
        case .matureCarrot: crop = .carrot
        case .matureCabbage: crop = .cabbage
        default: return
        }
        var updatedInventory = cropInventory
        updatedInventory.add(crop)
        cropInventory = updatedInventory
        var updatedField = farmField
        updatedField.tiles[index].state = .empty
        updatedField.tiles[index].wateredAt = nil
        farmField = updatedField
    }

    private func saveSeedInventory() {
        guard let data = try? JSONEncoder().encode(seedInventory) else { return }
        UserDefaults.standard.set(data, forKey: seedInventoryKey)
    }

    private func saveCropInventory() {
        guard let data = try? JSONEncoder().encode(cropInventory) else { return }
        UserDefaults.standard.set(data, forKey: cropInventoryKey)
    }

    private func startGrowthTimer() {
        advanceGrowth()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.advanceGrowth()
        }
        RunLoop.main.add(timer, forMode: .common)
        growthTimer = timer
    }

    /// 급수 후 5초마다 01 → 02 → 03 이미지로 한 단계씩 성장시킨다.
    private func advanceGrowth(now: Date = Date()) {
        var updatedField = farmField
        var changed = false
        var harvestTasks: [FarmWorkTask] = []
        for index in updatedField.tiles.indices {
            let tile = updatedField.tiles[index]
            guard tile.state == .wateredCarrotSeed || tile.state == .wateredCabbageSeed
                    || tile.state == .growingCarrot || tile.state == .growingCabbage,
                  let wateredAt = tile.wateredAt,
                  now.timeIntervalSince(wateredAt) >= Self.cropGrowthInterval
            else { continue }

            let elapsed = now.timeIntervalSince(wateredAt)
            if elapsed >= Self.cropGrowthInterval * 2 {
                updatedField.tiles[index].state = (tile.state == .wateredCarrotSeed || tile.state == .growingCarrot)
                    ? .matureCarrot
                    : .matureCabbage
                harvestTasks.append(FarmWorkTask(
                    kind: .harvesting,
                    tile: FarmTileCoordinate(row: index / FarmFieldData.cols,
                                             column: index % FarmFieldData.cols)
                ))
            } else if tile.state == .wateredCarrotSeed || tile.state == .wateredCabbageSeed {
                updatedField.tiles[index].state = tile.state == .wateredCarrotSeed
                    ? .growingCarrot
                    : .growingCabbage
            } else {
                continue
            }
            changed = true
        }
        if changed {
            farmField = updatedField
            farmWorkQueue.append(contentsOf: harvestTasks)
        }
    }

    deinit {
        growthTimer?.invalidate()
    }
}
