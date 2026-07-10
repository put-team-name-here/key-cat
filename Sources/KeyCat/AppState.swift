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

/// 상점 내부 상품 카테고리.
enum ShopCategory: String, CaseIterable, Identifiable {
    case seeds = "씨앗"
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

    var purchasePrice: Int {
        switch self {
        case .carrot: return 5
        case .cabbage: return 15
        }
    }

    /// 상점 카드에만 사용하는 안내용 성장시간. 실제 성장 타이머와는 무관하다.
    var displayedGrowthTime: String {
        switch self {
        case .carrot: return "2분"
        case .cabbage: return "5분"
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
        guard quantity > 0 else { return }
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

enum CatUnlockSource {
    case harvest
    case purchase
}

struct CatUnlockNotice: Identifiable {
    let id = UUID()
    let catID: String
    let source: CatUnlockSource
}

/// 축소/확장 + 농장 자원 상태를 담는 가벼운 상태 객체
final class AppState: ObservableObject {
    private static let cropGrowthInterval: TimeInterval = 5
    @Published var expanded = false {
        didSet {
            if shouldProcessFarmWorkInBackground {
                scheduleCollapsedFarmWorkIfNeeded()
            } else {
                collapsedFarmWorkItem?.cancel()
                collapsedFarmWorkItem = nil
            }
        }
    }
    /// 최초 30코인으로 시작하며 판매로 변경될 때마다 저장한다.
    @Published private(set) var coins: Int {
        didSet { UserDefaults.standard.set(coins, forKey: coinsKey) }
    }
    @Published private(set) var autoModeEnabled: Bool {
        didSet { UserDefaults.standard.set(autoModeEnabled, forKey: autoModeKey) }
    }
    /// 수확 가능 여부 (수확 시스템 연결 전 자리표시)
    @Published var harvestAvailable = false

    /// 확장 화면에서 선택한 하단 탭
    @Published var selectedFarmTab: FarmTab = .shop
    /// 상점 화면에서 선택한 상품 카테고리
    @Published var selectedShopCategory: ShopCategory = .seeds
    /// 도감 화면에서 선택한 내부 카테고리
    @Published var selectedCodexCategory: CodexCategory = .crops

    /// 기본 턱시도, 상점 구매 또는 수확 보상으로 획득한 고양이 ID.
    @Published private(set) var unlockedCatIDs: Set<String> {
        didSet { saveUnlockedCats() }
    }

    /// 새 고양이를 여러 마리 연속 획득해도 알림을 순서대로 보여주기 위한 큐.
    @Published private(set) var catUnlockNotices: [CatUnlockNotice] = []

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
        didSet {
            harvestAvailable = farmWorkQueue.contains { $0.kind == .harvesting }
            scheduleCollapsedFarmWorkIfNeeded()
        }
    }

    private let catKey = "selectedCatId"
    private let coinsKey = "coins"
    private let autoModeKey = "autoModeEnabled"
    private let seedInventoryKey = "seedInventory"
    private let cropInventoryKey = "cropInventory"
    private let unlockedCatIDsKey = "unlockedCatIDs"
    private let lastAppActiveAtKey = "lastAppActiveAt"
    private var growthTimer: Timer?
    private var lastHeartbeatWriteAt: Date?
    private var delayedAutoPlantWork: DispatchWorkItem?
    private var autoPlantedSeedCount = 0
    private var collapsedFarmWorkItem: DispatchWorkItem?
    private var farmPanelVisible = true

    init() {
        if UserDefaults.standard.object(forKey: coinsKey) == nil {
            coins = 30
        } else {
            coins = UserDefaults.standard.integer(forKey: coinsKey)
        }
        autoModeEnabled = UserDefaults.standard.bool(forKey: autoModeKey)
        var initialUnlockedCatIDs = UserDefaults.standard.data(forKey: unlockedCatIDsKey)
            .flatMap { try? JSONDecoder().decode(Set<String>.self, from: $0) }
            ?? []
        initialUnlockedCatIDs.insert("tuxedo")
        unlockedCatIDs = initialUnlockedCatIDs
        // 마지막으로 고른 보유 고양이를 복원. 없으면 기본 턱시도.
        if let savedId = UserDefaults.standard.string(forKey: catKey),
           initialUnlockedCatIDs.contains(savedId),
           let idx = CatCatalog.all.firstIndex(where: { $0.id == savedId }) {
            selectedCatIndex = idx
        } else {
            selectedCatIndex = CatCatalog.all.firstIndex(where: { $0.id == "tuxedo" }) ?? 0
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
        let launchTime = Date()
        let lastAppActiveAt = UserDefaults.standard.object(forKey: lastAppActiveAtKey) as? Date
        let inactiveDuration = lastAppActiveAt.map { max(0, launchTime.timeIntervalSince($0)) }
        // 앱이 종료돼 있던 시간은 wateredAt도 같은 만큼 앞으로 밀어 성장 계산에서 제외한다.
        for index in loadedField.tiles.indices
        where (loadedField.tiles[index].state == .wateredCarrotSeed
            || loadedField.tiles[index].state == .wateredCabbageSeed
            || loadedField.tiles[index].state == .growingCarrot
            || loadedField.tiles[index].state == .growingCabbage) {
            if let wateredAt = loadedField.tiles[index].wateredAt,
               let inactiveDuration {
                loadedField.tiles[index].wateredAt = wateredAt.addingTimeInterval(inactiveDuration)
            } else if loadedField.tiles[index].wateredAt == nil || lastAppActiveAt == nil {
                loadedField.tiles[index].wateredAt = launchTime
            }
        }
        UserDefaults.standard.set(launchTime, forKey: lastAppActiveAtKey)
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
        if autoModeEnabled {
            autoPlantNextSeed()
        }
        startGrowthTimer()
        scheduleCollapsedFarmWorkIfNeeded()
    }

    /// 현재 선택된 고양이 캐릭터
    var selectedCat: CatCharacter { CatCatalog.all[selectedCatIndex] }

    /// "변경" 버튼: 보유한 다음 고양이로 순환하고 선택을 영속화한다.
    func cycleCat() {
        let availableCats = CatCatalog.all.filter { unlockedCatIDs.contains($0.id) }
        guard !availableCats.isEmpty else { return }
        let currentAvailableIndex = availableCats.firstIndex(where: { $0.id == selectedCat.id }) ?? -1
        let nextCat = availableCats[(currentAvailableIndex + 1) % availableCats.count]
        guard let nextIndex = CatCatalog.all.firstIndex(where: { $0.id == nextCat.id }) else { return }
        selectedCatIndex = nextIndex
        UserDefaults.standard.set(selectedCat.id, forKey: catKey)
    }

    @discardableResult
    func selectCat(id: String) -> Bool {
        guard unlockedCatIDs.contains(id),
              let index = CatCatalog.all.firstIndex(where: { $0.id == id })
        else { return false }
        selectedCatIndex = index
        UserDefaults.standard.set(id, forKey: catKey)
        return true
    }

    func isCatUnlocked(id: String) -> Bool {
        unlockedCatIDs.contains(id)
    }

    func earnCoins(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
    }

    func toggleAutoMode() {
        autoModeEnabled.toggle()
        if autoModeEnabled {
            autoPlantNextSeed()
        } else {
            delayedAutoPlantWork?.cancel()
            delayedAutoPlantWork = nil
            autoPlantedSeedCount = 0
            farmWorkQueue.removeAll { $0.kind == .fetchingSeeds }
        }
    }

    /// 농장 창을 숨기면 확장 상태여도 상태 레이어가 작업 큐를 대신 처리한다.
    func setFarmPanelVisible(_ visible: Bool) {
        farmPanelVisible = visible
        if shouldProcessFarmWorkInBackground {
            scheduleCollapsedFarmWorkIfNeeded()
        } else {
            collapsedFarmWorkItem?.cancel()
            collapsedFarmWorkItem = nil
        }
    }

    func markAppTerminated() {
        UserDefaults.standard.set(Date(), forKey: lastAppActiveAtKey)
    }

    /// 씨앗을 선택한 수량만큼 구매하고 총 가격을 코인에서 차감한다.
    @discardableResult
    func purchase(_ seed: SeedKind, quantity: Int = 1) -> Bool {
        guard quantity > 0 else { return false }
        let totalPrice = seed.purchasePrice * quantity
        guard coins >= totalPrice else { return false }
        seedInventory.add(seed, quantity: quantity)
        coins -= totalPrice
        if autoModeEnabled {
            autoPlantNextSeed()
        }
        return true
    }

    /// 고양이 상품 한 마리를 구매한다. 이미 보유했거나 코인이 부족하면 구매하지 않는다.
    @discardableResult
    func purchaseCat(id: String, unitPrice: Int) -> Bool {
        guard unitPrice >= 0,
              !unlockedCatIDs.contains(id),
              coins >= unitPrice
        else { return false }
        var updatedIDs = unlockedCatIDs
        updatedIDs.insert(id)
        unlockedCatIDs = updatedIDs
        coins -= unitPrice
        catUnlockNotices.append(CatUnlockNotice(catID: id, source: .purchase))
        return true
    }

    func dismissCatUnlockNotice() {
        guard !catUnlockNotices.isEmpty else { return }
        catUnlockNotices.removeFirst()
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
        let completedSeedFetch = task.kind == .fetchingSeeds
        switch task.kind {
        case .watering:
            completeWatering(at: task.tile)
        case .harvesting:
            completeHarvest(at: task.tile)
        case .fetchingSeeds:
            autoPlantedSeedCount = 0
        }
        if farmWorkQueue.first == task {
            farmWorkQueue.removeFirst()
        } else {
            farmWorkQueue.removeAll { $0 == task }
        }
        if completedSeedFetch && autoModeEnabled {
            scheduleAutoPlant(after: 2)
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
        unlockHarvestCatsIfNeeded(for: crop)
        var updatedField = farmField
        updatedField.tiles[index].state = .empty
        updatedField.tiles[index].wateredAt = nil
        farmField = updatedField
        if autoModeEnabled {
            scheduleAutoPlant(after: 2)
        }
    }

    /// 빈 밭 중 한 곳을 무작위로 골라 씨앗 하나를 심고, 다음 파종은 2초 뒤 예약한다.
    private func autoPlantNextSeed() {
        guard autoModeEnabled, delayedAutoPlantWork == nil else { return }
        if autoPlantedSeedCount >= 5 {
            enqueueSeedFetchIfNeeded()
            return
        }

        let emptyTiles = (0..<FarmFieldData.rows).flatMap { row in
            (0..<FarmFieldData.cols).compactMap { column -> FarmTileCoordinate? in
                guard FarmFieldData.isDryGround(row: row, column: column),
                      farmField.tiles[farmField.index(row: row, column: column)].state == .empty
                else { return nil }
                return FarmTileCoordinate(row: row, column: column)
            }
        }

        guard let tile = emptyTiles.randomElement(),
              let seed = SeedKind.allCases.first(where: { seedCount($0) > 0 }),
              plant(seed, at: tile)
        else { return }

        autoPlantedSeedCount += 1
        if autoPlantedSeedCount >= 5 {
            enqueueSeedFetchIfNeeded()
            return
        }

        let hasRemainingSeed = SeedKind.allCases.contains { seedCount($0) > 0 }
        let hasEmptyGround = emptyTiles.count > 1
        if hasRemainingSeed && hasEmptyGround {
            scheduleAutoPlant(after: 2)
        }
    }

    /// 다섯 개를 심을 때마다 기존 작업 뒤에 고양이집 방문 작업을 한 번 추가한다.
    private func enqueueSeedFetchIfNeeded() {
        guard autoModeEnabled,
              !farmWorkQueue.contains(where: { $0.kind == .fetchingSeeds })
        else { return }
        farmWorkQueue.append(FarmWorkTask(kind: .fetchingSeeds, tile: FarmFieldData.catHouseCoordinate))
    }

    private func scheduleAutoPlant(after delay: TimeInterval) {
        guard autoModeEnabled, delayedAutoPlantWork == nil else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.delayedAutoPlantWork = nil
            self.autoPlantNextSeed()
        }
        delayedAutoPlantWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, delay), execute: work)
    }

    /// 축소 화면에서는 밭 뷰가 없어도 작업 큐를 상태 레이어에서 순서대로 완료한다.
    private func scheduleCollapsedFarmWorkIfNeeded() {
        guard shouldProcessFarmWorkInBackground,
              collapsedFarmWorkItem == nil,
              let task = farmWorkQueue.first
        else { return }

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.collapsedFarmWorkItem = nil
            guard self.shouldProcessFarmWorkInBackground,
                  self.farmWorkQueue.first == task
            else {
                self.scheduleCollapsedFarmWorkIfNeeded()
                return
            }
            self.completeFarmWork(task)
        }
        collapsedFarmWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: work)
    }

    private var shouldProcessFarmWorkInBackground: Bool {
        !expanded || !farmPanelVisible
    }

    private func saveSeedInventory() {
        guard let data = try? JSONEncoder().encode(seedInventory) else { return }
        UserDefaults.standard.set(data, forKey: seedInventoryKey)
    }

    private func saveCropInventory() {
        guard let data = try? JSONEncoder().encode(cropInventory) else { return }
        UserDefaults.standard.set(data, forKey: cropInventoryKey)
    }

    private func saveUnlockedCats() {
        guard let data = try? JSONEncoder().encode(unlockedCatIDs) else { return }
        UserDefaults.standard.set(data, forKey: unlockedCatIDsKey)
    }

    /// 당근은 치즈·오드아이, 양배추는 그레이만 각 드롭 확률에 따라 획득한다.
    private func unlockHarvestCatsIfNeeded(for crop: CropKind) {
        var updatedIDs = unlockedCatIDs
        var newlyUnlockedIDs: [String] = []
        let dropRates: [(catID: String, probability: Double)]
        switch crop {
        case .carrot:
            dropRates = [("cheese", 0.2), ("oddeye", 0.001)]
        case .cabbage:
            dropRates = [("gray", 0.2)]
        }
        for drop in dropRates where !updatedIDs.contains(drop.catID) {
            if Double.random(in: 0..<1) < drop.probability {
                updatedIDs.insert(drop.catID)
                newlyUnlockedIDs.append(drop.catID)
            }
        }
        if updatedIDs != unlockedCatIDs {
            unlockedCatIDs = updatedIDs
            catUnlockNotices.append(contentsOf: newlyUnlockedIDs.map {
                CatUnlockNotice(catID: $0, source: .harvest)
            })
        }
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
        writeActivityHeartbeatIfNeeded(at: now)
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

    private func writeActivityHeartbeatIfNeeded(at date: Date) {
        guard lastHeartbeatWriteAt.map({ date.timeIntervalSince($0) >= 1 }) ?? true else { return }
        lastHeartbeatWriteAt = date
        UserDefaults.standard.set(date, forKey: lastAppActiveAtKey)
    }

    deinit {
        growthTimer?.invalidate()
        delayedAutoPlantWork?.cancel()
        collapsedFarmWorkItem?.cancel()
    }
}
