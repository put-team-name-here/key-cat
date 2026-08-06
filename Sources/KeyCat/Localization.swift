import Foundation

/// 앱이 지원하는 표시 언어. 현재 시스템의 최우선 언어를 따라 한국어 또는 영어를 선택한다.
enum AppLanguage: String {
    case korean = "ko"
    case english = "en"

    static var current: AppLanguage {
        let languageCode = Locale.preferredLanguages.first?
            .split(separator: "-")
            .first
            .map(String.init)
        return languageCode == AppLanguage.korean.rawValue ? .korean : .english
    }
}

enum L10n {
    static func text(_ korean: String, _ english: String) -> String {
        text(korean, english, language: AppLanguage.current)
    }

    static func text(_ korean: String, _ english: String, language: AppLanguage) -> String {
        language == .korean ? korean : english
    }

    static func count(_ value: Int) -> String {
        text("\(value)개", "\(value)")
    }

    static func keystrokes(_ value: Int) -> String {
        text("\(value)타", "\(value) keys")
    }

    static func characters(_ value: Int) -> String {
        text("\(value)자", "\(value) chars")
    }

    static func coins(_ value: Int) -> String {
        text("\(value)코인", "\(value) coins")
    }

    static func minutes(_ value: Int) -> String {
        text("\(value)분", "\(value) min")
    }

    static func number(_ value: Int) -> String {
        value.formatted(.number.locale(Locale(identifier: AppLanguage.current == .korean ? "ko_KR" : "en_US")))
    }
}
