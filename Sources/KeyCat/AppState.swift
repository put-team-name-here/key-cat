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

/// 축소/확장 + 농장 자원 상태를 담는 가벼운 상태 객체
final class AppState: ObservableObject {
    @Published var expanded = false
    /// 보유 코인 (코인 획득 시스템 연결 전 자리표시)
    @Published var coins = 0
    /// 수확 가능 여부 (수확 시스템 연결 전 자리표시)
    @Published var harvestAvailable = false

    /// 확장 화면에서 선택한 하단 탭
    @Published var selectedFarmTab: FarmTab = .shop
    /// 도감 화면에서 선택한 내부 카테고리
    @Published var selectedCodexCategory: CodexCategory = .crops

    /// 축소 화면에서 순환 선택 중인 고양이 인덱스 (CatCatalog.all 기준)
    @Published var selectedCatIndex: Int

    private let catKey = "selectedCatId"

    init() {
        // 마지막으로 고른 고양이를 id 로 복원. 없거나 못 찾으면 첫 번째.
        if let savedId = UserDefaults.standard.string(forKey: catKey),
           let idx = CatCatalog.all.firstIndex(where: { $0.id == savedId }) {
            selectedCatIndex = idx
        } else {
            selectedCatIndex = 0
        }
    }

    /// 현재 선택된 고양이 캐릭터
    var selectedCat: CatCharacter { CatCatalog.all[selectedCatIndex] }

    /// "변경" 버튼: 다음 고양이로 순환하고 선택을 영속화
    func cycleCat() {
        selectedCatIndex = (selectedCatIndex + 1) % CatCatalog.all.count
        UserDefaults.standard.set(selectedCat.id, forKey: catKey)
    }
}
