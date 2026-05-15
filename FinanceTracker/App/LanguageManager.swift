import SwiftUI

class LanguageManager: ObservableObject {
    @Published var languageCode: String {
        didSet { UserDefaults.standard.set(languageCode, forKey: "app_language") }
    }

    init() {
        self.languageCode = UserDefaults.standard.string(forKey: "app_language") ?? "en"
    }

    var locale: Locale {
        Locale(identifier: languageCode == "zh" ? "zh-Hans" : "en")
    }

    var isEnglish: Bool { languageCode == "en" }
}
