import Foundation

/// 축소/확장 + 농장 자원 상태를 담는 가벼운 상태 객체
final class AppState: ObservableObject {
    @Published var expanded = false
    /// 보유 코인 (코인 획득 시스템 연결 전 자리표시)
    @Published var coins = 0
    /// 수확 가능 여부 (수확 시스템 연결 전 자리표시)
    @Published var harvestAvailable = false
}
