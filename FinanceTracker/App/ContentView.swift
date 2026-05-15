import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                MainTabView(selectedTab: $selectedTab)
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isLoggedIn)
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @State private var showMore = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            RecordView()
                .tabItem {
                    Label("Record", systemImage: "plus.circle.fill")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
                .tag(2)

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(3)

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(4)
        }
        .accentColor(.indigo)
    }
}

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: BudgetView()) {
                    Label("Budget", systemImage: "chart.pie.fill")
                        .foregroundColor(.indigo)
                }
                NavigationLink(destination: GoalsView()) {
                    Label("Goals", systemImage: "target")
                        .foregroundColor(.indigo)
                }
                NavigationLink(destination: RecurringView()) {
                    Label("Recurring", systemImage: "arrow.clockwise.circle.fill")
                        .foregroundColor(.indigo)
                }
                NavigationLink(destination: CalendarReportView()) {
                    Label("Calendar", systemImage: "calendar")
                        .foregroundColor(.indigo)
                }
                NavigationLink(destination: ProfileView()) {
                    Label("Profile", systemImage: "person.circle.fill")
                        .foregroundColor(.indigo)
                }
            }
            .navigationTitle("More")
        }
    }
}
