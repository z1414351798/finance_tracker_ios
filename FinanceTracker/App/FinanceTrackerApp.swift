import SwiftUI

@main
struct FinanceTrackerApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var languageManager = LanguageManager()
    @AppStorage("privacy_accepted") private var privacyAccepted: Bool = false
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !privacyAccepted {
                    ConsentView(hasAccepted: $privacyAccepted)
                        .opacity(showSplash ? 0 : 1)
                } else {
                    ContentView()
                        .environmentObject(authViewModel)
                        .environmentObject(languageManager)
                        .environment(\.locale, languageManager.locale)
                        .opacity(showSplash ? 0 : 1)
                }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

// MARK: - Splash Screen

struct SplashView: View {
    @State private var iconScale: CGFloat = 0.4
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0

    var body: some View {
        ZStack {
            // Background gradient — matches Dashboard hero
            LinearGradient(
                colors: [
                    Color(red: 0.24, green: 0.27, blue: 0.91),
                    Color(red: 0.20, green: 0.18, blue: 0.82),
                    Color(red: 0.27, green: 0.13, blue: 0.70)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 320, height: 320)
                .offset(x: -120, y: -220)
                .blur(radius: 2)

            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 400, height: 400)
                .offset(x: 140, y: 260)
                .blur(radius: 2)

            // Center content
            VStack(spacing: 24) {
                ZStack {
                    // Glow ring
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 110, height: 110)
                        .blur(radius: glowRadius)

                    // Icon background
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 90, height: 90)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1.5)
                        )

                    Image(systemName: "wallet.bifold.fill")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundColor(.white)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                VStack(spacing: 6) {
                    Text("FinanceTracker")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(textOpacity)

                    Text("Smart money, smarter life")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                        .opacity(taglineOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.1)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                glowRadius = 18
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.55)) {
                taglineOpacity = 1.0
            }
        }
    }
}
