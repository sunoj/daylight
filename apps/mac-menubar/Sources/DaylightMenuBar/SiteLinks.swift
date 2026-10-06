// Public web pages the app links to (privacy policy, support), per language.
// Exports: SiteLinks
// Deps: Foundation, Localization

import Foundation

enum SiteLinks {
    static let base = "https://daylight.mings.work"

    static func privacyPolicy(_ language: AppLanguage = Loc.language) -> URL {
        page("privacy", language)
    }

    static func support(_ language: AppLanguage = Loc.language) -> URL {
        page("support", language)
    }

    private static func page(_ name: String, _ language: AppLanguage) -> URL {
        let prefix: String
        switch language {
        case .en: prefix = ""
        case .zh: prefix = "/zh"
        case .zhHant: prefix = "/zh-hant"
        case .th: prefix = "/th"
        }
        return URL(string: "\(base)\(prefix)/\(name)")!
    }
}
