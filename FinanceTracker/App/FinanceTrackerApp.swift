import SwiftUI

@main
struct FinanceTrackerApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var languageManager = LanguageManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.locale)
        }
    }
}
