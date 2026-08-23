import Foundation

/// 확장 화면 하단 탭.
enum FarmTab: String, CaseIterable, Identifiable {
    case shop
    case storage
    case codex
    case log

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shop: return L10n.text("상점", "Shop")
        case .storage: return L10n.text("창고", "Storage")
        case .codex: return L10n.text("도감", "Collection")
        case .log: return L10n.text("기록", "Log")
        }
    }

}

/// 도감 내부 카테고리.
enum CodexCategory: String, CaseIterable, Identifiable {
    case crops
    case cats
    case toys

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .crops: return L10n.text("작물", "Crops")
        case .cats: return L10n.text("고양이", "Cats")
        case .toys: return L10n.text("장난감", "Toys")
        }
    }

}

/// 상점 내부 상품 카테고리.
enum ShopCategory: String, CaseIterable, Identifiable {
    case seeds
    case cats
    case toys

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .seeds: return L10n.text("씨앗", "Seeds")
        case .cats: return L10n.text("고양이", "Cats")
        case .toys: return L10n.text("장난감", "Toys")
        }
    }
}

/// 상점에서 구매하고 창고에 보관하는 씨앗 종류.
enum SeedKind: String, CaseIterable, Codable, Identifiable {
    case carrot
    case cabbage
    case tomato
    case peach
    case durian

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .carrot: return L10n.text("당근 씨앗", "Carrot Seeds")
        case .cabbage: return L10n.text("양배추 씨앗", "Cabbage Seeds")
        case .tomato: return L10n.text("토마토 씨앗", "Tomato Seeds")
        case .peach: return L10n.text("복숭아 씨앗", "Peach Seeds")
        case .durian: return L10n.text("두리안 씨앗", "Durian Seeds")
        }
    }

    var shortDisplayName: String {
        switch self {
        case .carrot: return L10n.text("당근", "Carrot")
        case .cabbage: return L10n.text("양배추", "Cabbage")
        case .tomato: return L10n.text("토마토", "Tomato")
        case .peach: return L10n.text("복숭아", "Peach")
        case .durian: return L10n.text("두리안", "Durian")
        }
    }

    var fieldState: FieldTileState {
        switch self {
        case .carrot: return .carrotSeed
        case .cabbage: return .cabbageSeed
        case .tomato: return .tomatoSeed
        case .peach: return .peachSeed
        case .durian: return .durianSeed
        }
    }

    var growthImageName: String {
        switch self {
        case .carrot: return "carrot_growth_01"
        case .cabbage: return "cabbage_growth_01"
        case .tomato: return "tomato_growth_01"
        case .peach: return "peach_growth_01"
        case .durian: return "durian_growth_01"
        }
    }

    var purchasePrice: Int {
        switch self {
        case .carrot: return 5
        case .cabbage: return 15
        case .tomato: return 50
        case .peach: return 250
        case .durian: return 1_000
        }
    }

    /// 급수 완료부터 수확 가능 상태가 될 때까지 걸리는 실제 성장 시간.
    var growthDuration: TimeInterval {
        switch self {
        case .carrot: return 2 * 60
        case .cabbage: return 5 * 60
        case .tomato: return 3 * 60
        case .peach: return 5 * 60
        case .durian: return 10 * 60
        }
    }

    var displayedGrowthTime: String {
        switch self {
        case .carrot: return L10n.minutes(2)
        case .cabbage: return L10n.minutes(5)
        case .tomato: return L10n.minutes(3)
        case .peach: return L10n.minutes(5)
        case .durian: return L10n.minutes(10)
        }
    }

    var unlockCatID: String? {
        switch self {
        case .carrot, .cabbage: return nil
        case .tomato: return "cheese"
        case .peach: return "gray"
        case .durian: return "persian"
        }
    }

    var unlockRequirement: String? {
        switch self {
        case .carrot, .cabbage: return nil
        case .tomato: return L10n.text("치즈 고양이 필요", "Requires Cheese")
        case .peach: return L10n.text("그레이 고양이 필요", "Requires Gray")
        case .durian: return L10n.text("페르시안 고양이 필요", "Requires Persian")
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

enum AutoSeedPurchasePolicy {
    static let batchQuantity = 10

    static func quantityToBuy(coins: Int, unitPrice: Int) -> Int {
        guard coins >= 0, unitPrice > 0 else { return 0 }
        return min(batchQuantity, coins / unitPrice)
    }
}

enum CropKind: String, CaseIterable, Codable, Identifiable {
    case carrot
    case cabbage
    case tomato
    case peach
    case durian

    /// SeedKind와 같은 그리드에 표시되므로 서로 다른 식별자 공간을 사용한다.
    var id: String { "crop-\(rawValue)" }

    var displayName: String {
        switch self {
        case .carrot: return L10n.text("당근", "Carrot")
        case .cabbage: return L10n.text("양배추", "Cabbage")
        case .tomato: return L10n.text("토마토", "Tomato")
        case .peach: return L10n.text("복숭아", "Peach")
        case .durian: return L10n.text("두리안", "Durian")
        }
    }

    var imageName: String { rawValue }

    var salePrice: Int {
        switch self {
        case .carrot: return 10
        case .cabbage: return 35
        case .tomato: return 100
        case .peach: return 400
        case .durian: return 1_400
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

func catHarvestDropRates(for crop: CropKind) -> [(catID: String, probability: Double)] {
    switch crop {
    case .carrot:
        return [("cheese", 0.001), ("oddeye", 0.000001)]
    case .cabbage:
        return [("gray", 0.001), ("calico", 0.000001)]
    case .tomato, .peach, .durian:
        return []
    }
}

struct CatUnlockNotice: Identifiable {
    let id = UUID()
    let catID: String
    let source: CatUnlockSource
}

/// 축소/확장 + 농장 자원 상태를 담는 가벼운 상태 객체
enum OverlaySizeMode {
    case compact
    case collapsed
    case expanded
}

final class AppState: ObservableObject {
    @Published private(set) var overlaySizeMode: OverlaySizeMode = .collapsed {
        didSet {
            if shouldProcessFarmWorkInBackground {
                scheduleCollapsedFarmWorkIfNeeded()
            } else {
                collapsedFarmWorkItem?.cancel()
                collapsedFarmWorkItem = nil
            }
        }
    }

    var expanded: Bool { overlaySizeMode == .expanded }

    func toggleExpanded() {
        overlaySizeMode = expanded ? .collapsed : .expanded
    }

    func minimizeOverlay() {
        overlaySizeMode = .compact
    }

    func restoreCollapsedOverlay() {
        overlaySizeMode = .collapsed
    }
    /// 최초 실행 시 표시되는 온보딩 화면의 표시 여부.
    @Published private(set) var isOnboardingPresented: Bool
    /// 최초 30코인으로 시작하며 판매로 변경될 때마다 저장한다.
    @Published private(set) var coins: Int {
        didSet { UserDefaults.standard.set(coins, forKey: coinsKey) }
    }
    @Published private(set) var autoModeEnabled: Bool {
        didSet { UserDefaults.standard.set(autoModeEnabled, forKey: autoModeKey) }
    }
    @Published private(set) var autoSeedPurchaseEnabled: Bool {
        didSet { UserDefaults.standard.set(autoSeedPurchaseEnabled, forKey: autoSeedPurchaseEnabledKey) }
    }
    @Published private(set) var autoSeedPurchaseKind: SeedKind {
        didSet { UserDefaults.standard.set(autoSeedPurchaseKind.rawValue, forKey: autoSeedPurchaseKindKey) }
    }
    @Published private(set) var preferredPlantingSeed: SeedKind {
        didSet { UserDefaults.standard.set(preferredPlantingSeed.rawValue, forKey: preferredPlantingSeedKey) }
    }
    /// 수확 가능 여부 (수확 시스템 연결 전 자리표시)
    @Published var harvestAvailable = false

    /// 확장 화면에서 선택한 하단 탭
    @Published var selectedFarmTab: FarmTab = .shop
    /// 확장 화면 맵에서 현재 보고 있는 위치
    @Published var selectedMapLocation: MapLocation = .field {
        didSet { scheduleCollapsedFarmWorkIfNeeded() }
    }
    /// 상점 화면에서 선택한 상품 카테고리
    @Published var selectedShopCategory: ShopCategory = .seeds
    /// 창고 화면에서 선택한 보관품 카테고리
    @Published var selectedStorageCategory: StorageCategory = .seeds
    /// 도감 화면에서 선택한 내부 카테고리
    @Published var selectedCodexCategory: CodexCategory = .crops

    /// 기본 턱시도, 상점 구매 또는 수확 보상으로 획득한 고양이 ID.
    @Published private(set) var unlockedCatIDs: Set<String> {
        didSet {
            saveUnlockedCats()
            normalizeFarmWorkerAssignments()
        }
    }

    /// 가운데 농장과 확장 농장에 배정된 고양이 ID.
    @Published private(set) var farmWorkerIDs: [FarmArea: String] {
        didSet { saveFarmWorkerAssignments() }
    }

    /// 새 고양이를 여러 마리 연속 획득해도 알림을 순서대로 보여주기 위한 큐.
    @Published private(set) var catUnlockNotices: [CatUnlockNotice] = []

    /// 축소 화면에서 순환 선택 중인 고양이 인덱스 (CatCatalog.all 기준)
    @Published var selectedCatIndex: Int

    /// 밭 잔디 배치 + 칸별 상태. farm.json 에서 복원하고, 바뀔 때마다 다시 저장한다.
    @Published var farmField: FarmFieldData {
        didSet { FarmFieldStorage.save(farmField) }
    }

    /// 오른쪽 확장 구역의 밭 상태와 순차 구매 진행도.
    @Published var expansionFarm: ExpansionFarmData {
        didSet { ExpansionFarmStorage.save(expansionFarm) }
    }

    /// 집에 배치한 가구. 집+가구 스냅샷에서 복원한다.
    @Published private(set) var home: HomeData

    /// 상점에서 구매한 씨앗. 변경될 때마다 UserDefaults에 저장한다.
    @Published private(set) var seedInventory: SeedInventory {
        didSet { saveSeedInventory() }
    }

    @Published private(set) var cropInventory: CropInventory {
        didSet { saveCropInventory() }
    }

    /// 상점에서 구매한 가구. 집+가구 스냅샷에서 복원한다.
    @Published private(set) var furnitureInventory: FurnitureInventory

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
    private let autoSeedPurchaseEnabledKey = "autoSeedPurchaseEnabled"
    private let autoSeedPurchaseKindKey = "autoSeedPurchaseKind"
    private let preferredPlantingSeedKey = "preferredPlantingSeed"
    private let seedInventoryKey = "seedInventory"
    private let cropInventoryKey = "cropInventory"
    private let furnitureInventoryKey = "furnitureInventory"
    private let unlockedCatIDsKey = "unlockedCatIDs"
    private let farmWorkerIDsKey = "farmWorkerIDs"
    private let onboardingCompletedKey = "onboardingCompleted"
    private let lastAppActiveAtKey = "lastAppActiveAt"
    private var growthTimer: Timer?
    private var lastHeartbeatWriteAt: Date?
    private var delayedAutoPlantWork: DispatchWorkItem?
    private var autoPlantedSeedCount = 0
    private var collapsedFarmWorkItem: DispatchWorkItem?
    private var farmPanelVisible = true

    init() {
        isOnboardingPresented = !UserDefaults.standard.bool(forKey: onboardingCompletedKey)
        if UserDefaults.standard.object(forKey: coinsKey) == nil {
            coins = 30
        } else {
            coins = UserDefaults.standard.integer(forKey: coinsKey)
        }
        autoModeEnabled = UserDefaults.standard.bool(forKey: autoModeKey)
        autoSeedPurchaseEnabled = UserDefaults.standard.bool(forKey: autoSeedPurchaseEnabledKey)
        let savedAutoSeedPurchaseKind = UserDefaults.standard.string(forKey: autoSeedPurchaseKindKey)
            .flatMap(SeedKind.init(rawValue:)) ?? .carrot
        let savedPreferredPlantingSeed = UserDefaults.standard.string(forKey: preferredPlantingSeedKey)
            .flatMap(SeedKind.init(rawValue:)) ?? .carrot
        var initialUnlockedCatIDs = UserDefaults.standard.data(forKey: unlockedCatIDsKey)
            .flatMap { try? JSONDecoder().decode(Set<String>.self, from: $0) }
            ?? []
        initialUnlockedCatIDs.insert("tuxedo")
        unlockedCatIDs = initialUnlockedCatIDs
        let savedFarmWorkerIDs = UserDefaults.standard.data(forKey: farmWorkerIDsKey)
            .flatMap { try? JSONDecoder().decode([FarmArea: String].self, from: $0) }
            ?? [:]
        farmWorkerIDs = FarmCatAssignment.normalized(
            savedFarmWorkerIDs,
            unlockedCatIDs: initialUnlockedCatIDs
        )
        if let requiredCatID = savedAutoSeedPurchaseKind.unlockCatID,
           !initialUnlockedCatIDs.contains(requiredCatID) {
            autoSeedPurchaseKind = .carrot
        } else {
            autoSeedPurchaseKind = savedAutoSeedPurchaseKind
        }
        if let requiredCatID = savedPreferredPlantingSeed.unlockCatID,
           !initialUnlockedCatIDs.contains(requiredCatID) {
            preferredPlantingSeed = .carrot
        } else {
            preferredPlantingSeed = savedPreferredPlantingSeed
        }
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
        let legacyFurnitureInventory: FurnitureInventory
        if let data = UserDefaults.standard.data(forKey: furnitureInventoryKey),
           let inventory = try? JSONDecoder().decode(FurnitureInventory.self, from: data) {
            legacyFurnitureInventory = inventory
        } else {
            legacyFurnitureInventory = FurnitureInventory()
        }
        let homeState = HomeStorage.load(fallbackFurnitureInventory: legacyFurnitureInventory)
        home = homeState.home
        furnitureInventory = homeState.furnitureInventory
        var loadedField = FarmFieldStorage.load()
        var loadedExpansionFarm = ExpansionFarmStorage.load()
        let launchTime = Date()
        let lastAppActiveAt = UserDefaults.standard.object(forKey: lastAppActiveAtKey) as? Date
        let inactiveDuration = lastAppActiveAt.map { max(0, launchTime.timeIntervalSince($0)) }
        // 앱이 종료돼 있던 시간은 wateredAt도 같은 만큼 앞으로 밀어 성장 계산에서 제외한다.
        for index in loadedField.tiles.indices
        where loadedField.tiles[index].state.growingSeedKind != nil {
            if let wateredAt = loadedField.tiles[index].wateredAt,
               let inactiveDuration {
                loadedField.tiles[index].wateredAt = wateredAt.addingTimeInterval(inactiveDuration)
            } else if loadedField.tiles[index].wateredAt == nil || lastAppActiveAt == nil {
                loadedField.tiles[index].wateredAt = launchTime
            }
        }
        for index in loadedExpansionFarm.field.tiles.indices
        where loadedExpansionFarm.field.tiles[index].state.growingSeedKind != nil {
            if let wateredAt = loadedExpansionFarm.field.tiles[index].wateredAt,
               let inactiveDuration {
                loadedExpansionFarm.field.tiles[index].wateredAt = wateredAt.addingTimeInterval(inactiveDuration)
            } else if loadedExpansionFarm.field.tiles[index].wateredAt == nil || lastAppActiveAt == nil {
                loadedExpansionFarm.field.tiles[index].wateredAt = launchTime
            }
        }
        UserDefaults.standard.set(launchTime, forKey: lastAppActiveAtKey)
        FarmFieldStorage.save(loadedField)
        ExpansionFarmStorage.save(loadedExpansionFarm)
        farmField = loadedField
        expansionFarm = loadedExpansionFarm
        let mainTasks = farmField.tiles.enumerated().compactMap { index, tile -> FarmWorkTask? in
            let coordinate = FarmTileCoordinate(row: index / FarmFieldData.cols,
                                                column: index % FarmFieldData.cols)
            if tile.state.needsWater {
                return FarmWorkTask(kind: .watering, tile: coordinate)
            }
            if tile.state.isMature {
                return FarmWorkTask(kind: .harvesting, tile: coordinate)
            }
            return nil
        }
        let expansionTasks = expansionFarm.field.tiles.enumerated().compactMap { index, tile -> FarmWorkTask? in
            let coordinate = FarmTileCoordinate(row: index / FarmFieldData.cols,
                                                column: index % FarmFieldData.cols)
            guard expansionFarm.isPurchased(row: coordinate.row, column: coordinate.column) else {
                return nil
            }
            if tile.state.needsWater {
                return FarmWorkTask(kind: .watering, tile: coordinate, area: .expansion)
            }
            if tile.state.isMature {
                return FarmWorkTask(kind: .harvesting, tile: coordinate, area: .expansion)
            }
            return nil
        }
        farmWorkQueue = mainTasks + expansionTasks
        harvestAvailable = farmWorkQueue.contains { $0.kind == .harvesting }
        if autoModeEnabled {
            autoPlantNextSeed()
        }
        startGrowthTimer()
        scheduleCollapsedFarmWorkIfNeeded()
    }

    /// 온보딩을 완료하고 다음 실행부터는 바로 농장 화면을 표시한다.
    func completeOnboarding() {
        guard isOnboardingPresented else { return }
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        isOnboardingPresented = false
    }

    /// 현재 선택된 고양이 캐릭터
    var selectedCat: CatCharacter { CatCatalog.all[selectedCatIndex] }

    /// 가운데 농장과 확장 농장에 각각 고정 배정된 보유 고양이.
    func farmWorker(for area: FarmArea) -> CatCharacter? {
        guard let workerID = farmWorkerIDs[area] else { return nil }
        return CatCatalog.all.first { $0.id == workerID }
    }

    @discardableResult
    func assignFarmWorker(catID: String, to area: FarmArea) -> Bool {
        guard unlockedCatIDs.contains(catID) else { return false }
        let swapped = FarmCatAssignment.assigning(
            catID: catID,
            to: area,
            current: farmWorkerIDs
        )
        farmWorkerIDs = FarmCatAssignment.normalized(
            swapped,
            unlockedCatIDs: unlockedCatIDs
        )
        return true
    }

    /// 두 농장 담당을 제외하고 집에서 쉬는 보유 고양이들.
    var homeCats: [CatCharacter] {
        let homeCatIDs = Set(FarmCatAssignment.homeCatIDs(
            unlockedCatIDs: unlockedCatIDs,
            assignments: farmWorkerIDs
        ))
        return CatCatalog.all.filter { homeCatIDs.contains($0.id) }
    }

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

    func isSeedUnlocked(_ seed: SeedKind) -> Bool {
        guard let requiredCatID = seed.unlockCatID else { return true }
        return unlockedCatIDs.contains(requiredCatID)
    }

    func earnCoins(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
        resumeAutoPlantIfPossible()
    }

    var activeHomeBonuses: HomeBonusSummary {
        home.activeBonuses
    }

    func saleProceeds(for crop: CropKind, quantity: Int) -> Int? {
        activeHomeBonuses.cropSaleProceeds(
            unitPrice: crop.salePrice,
            quantity: quantity
        )
    }

    func earnTypingMilestoneBonus() {
        earnCoins(activeHomeBonuses.typingBonusPerHundred)
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

    func toggleAutoSeedPurchase() {
        autoSeedPurchaseEnabled.toggle()
        resumeAutoPlantIfPossible()
    }

    func setAutoSeedPurchaseKind(_ seed: SeedKind) {
        guard isSeedUnlocked(seed) else { return }
        autoSeedPurchaseKind = seed
        resumeAutoPlantIfPossible()
    }

    func setPreferredPlantingSeed(_ seed: SeedKind) {
        guard isSeedUnlocked(seed) else { return }
        preferredPlantingSeed = seed
        resumeAutoPlantIfPossible()
    }

    var isWaitingForAutoSeedPurchaseFunds: Bool {
        autoModeEnabled
            && autoSeedPurchaseEnabled
            && !SeedKind.allCases.contains(where: { seedCount($0) > 0 })
            && coins < autoSeedPurchaseKind.purchasePrice
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
        guard isSeedUnlocked(seed) else { return false }
        guard commitSeedPurchase(seed, quantity: quantity) else { return false }
        resumeAutoPlantIfPossible()
        return true
    }

    private func commitSeedPurchase(_ seed: SeedKind, quantity: Int) -> Bool {
        guard quantity > 0 else { return false }
        let (totalPrice, overflow) = seed.purchasePrice.multipliedReportingOverflow(by: quantity)
        guard !overflow else { return false }
        guard coins >= totalPrice else { return false }
        seedInventory.add(seed, quantity: quantity)
        coins -= totalPrice
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

    var nextExpansionPlotNumber: Int? {
        expansionFarm.nextPlotNumber
    }

    func expansionPlotPrice(_ plotNumber: Int) -> Int? {
        ExpansionPlotPricing.price(for: plotNumber)
    }

    @discardableResult
    func purchaseExpansionPlot(_ plotNumber: Int) -> Bool {
        guard plotNumber == expansionFarm.nextPlotNumber,
              let price = ExpansionPlotPricing.price(for: plotNumber),
              coins >= price
        else { return false }

        var updatedExpansion = expansionFarm
        guard updatedExpansion.purchaseNext(plotNumber: plotNumber) else { return false }
        expansionFarm = updatedExpansion
        coins -= price
        resumeAutoPlantIfPossible()
        return true
    }

    func visibleFarmTask(for area: FarmArea) -> FarmWorkTask? {
        guard farmWorkQueue.first?.area == area else { return nil }
        return farmWorkQueue.first
    }

    func tileState(for task: FarmWorkTask) -> FieldTileState? {
        let field = fieldData(for: task.area)
        guard field.isValid(row: task.tile.row, column: task.tile.column) else { return nil }
        return field.tiles[field.index(row: task.tile.row, column: task.tile.column)].state
    }

    func furnitureCount(_ furniture: FurnitureItem) -> Int {
        furnitureInventory.count(of: furniture)
    }

    /// 창고 보관분과 집에 배치한 수량을 합친 전체 보유량.
    func ownedFurnitureCount(_ furniture: FurnitureItem) -> Int {
        let storedCount = furnitureInventory.count(of: furniture)
        let placedCount = home.placedFurniture.lazy
            .filter { $0.furnitureID == furniture.id }
            .count
        let (total, overflow) = storedCount.addingReportingOverflow(placedCount)
        return overflow ? Int.max : total
    }

    func ownsFurniture(_ furniture: FurnitureItem) -> Bool {
        ownedFurnitureCount(furniture) > 0
    }

    /// 상점에서 가구를 선택한 수량만큼 구매하고 총 가격을 코인에서 차감한다.
    @discardableResult
    func purchase(_ furniture: FurnitureItem, quantity: Int = 1) -> Bool {
        guard quantity > 0,
              let catalogFurniture = FurnitureCatalog.item(withID: furniture.id),
              catalogFurniture.purchasePrice > 0,
              catalogFurniture.allowsPurchase(
                  quantity: quantity,
                  currentlyOwned: ownedFurnitureCount(catalogFurniture)
              )
        else { return false }

        let (totalPrice, overflow) = catalogFurniture.purchasePrice
            .multipliedReportingOverflow(by: quantity)
        guard !overflow else { return false }
        guard coins >= totalPrice else { return false }
        var updatedInventory = furnitureInventory
        guard updatedInventory.add(catalogFurniture, quantity: quantity) else {
            return false
        }
        guard persistHomeState(home: home, furnitureInventory: updatedInventory) else {
            return false
        }
        furnitureInventory = updatedInventory
        coins -= totalPrice
        return true
    }

    /// 창고의 작물을 선택한 수량만큼 판매하고 판매 대금을 코인에 더한다.
    @discardableResult
    func sell(_ crop: CropKind, quantity: Int) -> Bool {
        guard let proceeds = saleProceeds(for: crop, quantity: quantity) else { return false }
        var updatedInventory = cropInventory
        guard updatedInventory.consume(crop, quantity: quantity) else { return false }
        cropInventory = updatedInventory
        coins += proceeds
        resumeAutoPlantIfPossible()
        return true
    }

    /// 창고에서 선택한 가구를 집의 빈 칸에 하나 배치한다.
    @discardableResult
    func placeFurniture(_ furniture: FurnitureItem, at tile: FarmTileCoordinate) -> Bool {
        guard FurnitureCatalog.item(withID: furniture.id) != nil,
              home.isValid(row: tile.row, column: tile.column),
              !home.isOccupied(row: tile.row, column: tile.column)
        else { return false }

        var updatedInventory = furnitureInventory
        guard updatedInventory.consume(furniture) else { return false }

        var updatedHome = home
        updatedHome.placedFurniture.append(PlacedFurniture(
            furnitureID: furniture.id,
            row: tile.row,
            column: tile.column
        ))
        guard persistHomeState(home: updatedHome, furnitureInventory: updatedInventory) else {
            return false
        }
        furnitureInventory = updatedInventory
        home = updatedHome
        return true
    }

    /// 집에 놓인 가구를 빈 칸으로 옮긴다.
    @discardableResult
    func moveFurniture(_ placedFurniture: PlacedFurniture, to tile: FarmTileCoordinate) -> Bool {
        guard home.isValid(row: tile.row, column: tile.column),
              let index = home.placedFurniture.firstIndex(where: { $0.id == placedFurniture.id })
        else { return false }

        let current = home.placedFurniture[index]
        guard current.row != tile.row || current.column != tile.column else { return true }
        guard !home.isOccupied(row: tile.row, column: tile.column) else { return false }

        var updatedHome = home
        updatedHome.placedFurniture[index] = PlacedFurniture(
            id: current.id,
            furnitureID: current.furnitureID,
            row: tile.row,
            column: tile.column
        )
        guard persistHomeState(home: updatedHome, furnitureInventory: furnitureInventory) else {
            return false
        }
        home = updatedHome
        return true
    }

    /// 집에 놓인 가구를 다시 창고로 돌려놓는다.
    @discardableResult
    func returnFurnitureToStorage(_ placedFurniture: PlacedFurniture) -> Bool {
        guard let furniture = FurnitureCatalog.item(withID: placedFurniture.furnitureID),
              home.placedFurniture.contains(where: { $0.id == placedFurniture.id })
        else { return false }

        var updatedHome = home
        updatedHome.placedFurniture.removeAll { $0.id == placedFurniture.id }
        var updatedInventory = furnitureInventory
        guard updatedInventory.add(furniture) else { return false }
        guard persistHomeState(home: updatedHome, furnitureInventory: updatedInventory) else {
            return false
        }
        home = updatedHome
        furnitureInventory = updatedInventory
        return true
    }

    /// 빈 밭 타일에 씨앗 하나를 심고 창고 수량을 차감한다.
    @discardableResult
    func plant(_ seed: SeedKind, at tile: FarmTileCoordinate, area: FarmArea = .main) -> Bool {
        guard FarmFieldData.isDryGround(row: tile.row, column: tile.column),
              area == .main || expansionFarm.isPurchased(row: tile.row, column: tile.column)
        else { return false }

        var updatedField = fieldData(for: area)
        guard updatedField.isValid(row: tile.row, column: tile.column) else { return false }
        let index = updatedField.index(row: tile.row, column: tile.column)
        guard updatedField.tiles[index].state == .empty,
              seedInventory.consume(seed)
        else { return false }

        updatedField.tiles[index].state = seed.fieldState
        updatedField.tiles[index].wateredAt = nil
        setFieldData(updatedField, for: area)
        farmWorkQueue.append(FarmWorkTask(kind: .watering, tile: tile, area: area))
        return true
    }

    func completeFarmWork(_ task: FarmWorkTask) {
        let completedSeedFetch = task.kind == .fetchingSeeds
        switch task.kind {
        case .watering:
            completeWatering(at: task.tile, area: task.area)
        case .harvesting:
            completeHarvest(at: task.tile, area: task.area)
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
    private func completeWatering(at tile: FarmTileCoordinate, area: FarmArea) {
        var updatedField = fieldData(for: area)
        guard updatedField.isValid(row: tile.row, column: tile.column) else { return }
        let index = updatedField.index(row: tile.row, column: tile.column)
        guard updatedField.tiles[index].state.needsWater else { return }
        updatedField.tiles[index].state = updatedField.tiles[index].state.watered
        if updatedField.tiles[index].state == .wateredCarrotSeed
            || updatedField.tiles[index].state == .wateredCabbageSeed
            || updatedField.tiles[index].state == .wateredTomatoSeed
            || updatedField.tiles[index].state == .wateredPeachSeed
            || updatedField.tiles[index].state == .wateredDurianSeed {
            updatedField.tiles[index].wateredAt = Date()
        }
        setFieldData(updatedField, for: area)
    }

    /// 완전히 자란 작물을 창고로 옮기고 타일을 빈 밭으로 되돌린다.
    private func completeHarvest(at tile: FarmTileCoordinate, area: FarmArea) {
        var updatedField = fieldData(for: area)
        guard updatedField.isValid(row: tile.row, column: tile.column) else { return }
        let index = updatedField.index(row: tile.row, column: tile.column)
        let crop: CropKind
        switch updatedField.tiles[index].state {
        case .matureCarrot: crop = .carrot
        case .matureCabbage: crop = .cabbage
        case .matureTomato: crop = .tomato
        case .maturePeach: crop = .peach
        case .matureDurian: crop = .durian
        default: return
        }
        var updatedInventory = cropInventory
        updatedInventory.add(crop)
        cropInventory = updatedInventory
        unlockHarvestCatsIfNeeded(for: crop)
        updatedField.tiles[index].state = .empty
        updatedField.tiles[index].wateredAt = nil
        setFieldData(updatedField, for: area)
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

        let mainEmptyTiles = (0..<FarmFieldData.rows).flatMap { row in
            (0..<FarmFieldData.cols).compactMap { column -> (FarmArea, FarmTileCoordinate)? in
                guard FarmFieldData.isDryGround(row: row, column: column),
                      farmField.tiles[farmField.index(row: row, column: column)].state == .empty
                else { return nil }
                return (.main, FarmTileCoordinate(row: row, column: column))
            }
        }
        let expansionEmptyTiles = (0..<FarmFieldData.rows).flatMap { row in
            (0..<FarmFieldData.cols).compactMap { column -> (FarmArea, FarmTileCoordinate)? in
                guard expansionFarm.isPurchased(row: row, column: column),
                      expansionFarm.field.tiles[expansionFarm.field.index(row: row, column: column)].state == .empty
                else { return nil }
                return (.expansion, FarmTileCoordinate(row: row, column: column))
            }
        }
        let emptyTiles = mainEmptyTiles + expansionEmptyTiles

        guard let destination = emptyTiles.randomElement() else { return }

        if !SeedKind.allCases.contains(where: { seedCount($0) > 0 }) {
            _ = autoPurchaseSeedsIfNeeded()
        }

        let availableSeeds = SeedKind.allCases.filter { seedCount($0) > 0 }
        guard let seed = SeedPlantingPriority.nextSeed(
            preferred: preferredPlantingSeed,
            available: availableSeeds
        ),
              plant(seed, at: destination.1, area: destination.0)
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
        farmWorkQueue.append(FarmWorkTask(
            kind: .fetchingSeeds,
            tile: FarmFieldData.catHouseCoordinate,
            area: .main
        ))
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

    private func autoPurchaseSeedsIfNeeded() -> Bool {
        guard autoModeEnabled,
              autoSeedPurchaseEnabled,
              isSeedUnlocked(autoSeedPurchaseKind),
              !SeedKind.allCases.contains(where: { seedCount($0) > 0 })
        else { return false }

        let quantity = AutoSeedPurchasePolicy.quantityToBuy(
            coins: coins,
            unitPrice: autoSeedPurchaseKind.purchasePrice
        )
        guard quantity > 0 else { return false }
        return commitSeedPurchase(autoSeedPurchaseKind, quantity: quantity)
    }

    private func resumeAutoPlantIfPossible() {
        guard autoModeEnabled else { return }
        scheduleAutoPlant(after: 0)
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
        guard expanded, farmPanelVisible else { return true }
        guard let taskArea = farmWorkQueue.first?.area else { return false }
        return selectedMapLocation.farmArea != taskArea
    }

    private func saveSeedInventory() {
        guard let data = try? JSONEncoder().encode(seedInventory) else { return }
        UserDefaults.standard.set(data, forKey: seedInventoryKey)
    }

    private func saveCropInventory() {
        guard let data = try? JSONEncoder().encode(cropInventory) else { return }
        UserDefaults.standard.set(data, forKey: cropInventoryKey)
    }

    @discardableResult
    private func persistHomeState(home: HomeData, furnitureInventory: FurnitureInventory) -> Bool {
        HomeStorage.save(HomeStateSnapshot(
            home: home,
            furnitureInventory: furnitureInventory
        ))
    }

    private func fieldData(for area: FarmArea) -> FarmFieldData {
        switch area {
        case .main: return farmField
        case .expansion: return expansionFarm.field
        }
    }

    private func setFieldData(_ field: FarmFieldData, for area: FarmArea) {
        switch area {
        case .main:
            farmField = field
        case .expansion:
            var updatedExpansion = expansionFarm
            updatedExpansion.field = field
            expansionFarm = updatedExpansion
        }
    }

    private func saveUnlockedCats() {
        guard let data = try? JSONEncoder().encode(unlockedCatIDs) else { return }
        UserDefaults.standard.set(data, forKey: unlockedCatIDsKey)
    }

    private func saveFarmWorkerAssignments() {
        guard let data = try? JSONEncoder().encode(farmWorkerIDs) else { return }
        UserDefaults.standard.set(data, forKey: farmWorkerIDsKey)
    }

    private func normalizeFarmWorkerAssignments() {
        let normalized = FarmCatAssignment.normalized(
            farmWorkerIDs,
            unlockedCatIDs: unlockedCatIDs
        )
        if normalized != farmWorkerIDs {
            farmWorkerIDs = normalized
        }
    }

    /// 작물별 드롭 확률에 따라 미보유 고양이를 획득한다.
    private func unlockHarvestCatsIfNeeded(for crop: CropKind) {
        var updatedIDs = unlockedCatIDs
        var newlyUnlockedIDs: [String] = []
        let dropRates = catHarvestDropRates(for: crop)
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

    /// 작물별 성장시간의 절반에 02, 전체 시간이 지나면 03 이미지로 성장시킨다.
    private func advanceGrowth(now: Date = Date()) {
        writeActivityHeartbeatIfNeeded(at: now)
        var harvestTasks: [FarmWorkTask] = []
        for area in FarmArea.allCases {
            var updatedField = fieldData(for: area)
            var changed = false
            for index in updatedField.tiles.indices {
                let tile = updatedField.tiles[index]
                guard let seed = tile.state.growingSeedKind,
                      let wateredAt = tile.wateredAt
                else { continue }

                let elapsed = now.timeIntervalSince(wateredAt)
                let growthDuration = activeHomeBonuses.growthDuration(from: seed.growthDuration)
                if elapsed >= growthDuration, let matureStage = tile.state.matureStage {
                    updatedField.tiles[index].state = matureStage
                    harvestTasks.append(FarmWorkTask(
                        kind: .harvesting,
                        tile: FarmTileCoordinate(row: index / FarmFieldData.cols,
                                                 column: index % FarmFieldData.cols),
                        area: area
                    ))
                } else if elapsed >= growthDuration / 2,
                          let nextGrowthStage = tile.state.nextGrowthStage {
                    updatedField.tiles[index].state = nextGrowthStage
                } else {
                    continue
                }
                changed = true
            }
            if changed {
                setFieldData(updatedField, for: area)
            }
        }
        farmWorkQueue.append(contentsOf: harvestTasks)
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
