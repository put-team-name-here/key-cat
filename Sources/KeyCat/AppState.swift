import Foundation

/// 축소/확장 상태만 담는 가벼운 상태 객체
final class AppState: ObservableObject {
    @Published var expanded = false
}
