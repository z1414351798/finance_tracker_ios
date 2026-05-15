import SwiftUI

@main
struct FinanceTrackerApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var languageManager = LanguageManager()
    @AppStorage("privacy_accepted") private var privacyAccepted: Bool = false

    var body: some Scene {
        WindowGroup {
            if !privacyAccepted {
                ConsentView(hasAccepted: $privacyAccepted)
            } else {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(languageManager)
                    .environment(\.locale, languageManager.locale)
            }
        }
    }
}
