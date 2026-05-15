import SwiftUI

struct ConsentView: View {
    @Binding var hasAccepted: Bool
    @Environment(\.openURL) private var openURL

    private let privacyURL = URL(string: "https://www.wisefintrakr.com/privacy")!
    private let termsURL = URL(string: "https://www.wisefintrakr.com/terms")!

    private let privacyPoints: [(icon: String, color: Color, text: String)] = [
        ("shield.fill",        .indigo,  "Your data is encrypted and stored securely on our US servers"),
        ("eye.slash.fill",     .blue,    "We never sell your personal or financial data to third parties"),
        ("trash.fill",         .red,     "You can delete your account and all data at any time"),
        ("location.slash.fill",.green,   "We don't track your location or share data with advertisers"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    // Logo
                    ZStack {
                        LinearGradient(
                            colors: [Color.indigo, Color.indigo.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color.indigo.opacity(0.35), radius: 12, x: 0, y: 6)

                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 48)

                    // Header
                    VStack(spacing: 8) {
                        Text("Before you begin")
                            .font(.title.bold())
                        Text("FinanceTracker takes your privacy seriously")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Privacy points
                    VStack(spacing: 0) {
                        ForEach(Array(privacyPoints.enumerated()), id: \.offset) { index, point in
                            HStack(alignment: .top, spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(point.color.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: point.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(point.color)
                                }

                                Text(point.text)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)

                            if index < privacyPoints.count - 1 {
                                Divider()
                                    .padding(.leading, 80)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)

                    // Legal links
                    HStack(spacing: 6) {
                        Text("By continuing you agree to our")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Link("Privacy Policy", destination: privacyURL)
                            .font(.caption.bold())
                            .foregroundColor(.indigo)
                        Text("and")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Link("Terms of Service", destination: termsURL)
                            .font(.caption.bold())
                            .foregroundColor(.indigo)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }

            // CTA button pinned at bottom
            VStack(spacing: 0) {
                Divider()
                Button {
                    UserDefaults.standard.set(true, forKey: "privacy_accepted")
                    hasAccepted = true
                } label: {
                    Text("I Agree & Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.indigo, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    ConsentView(hasAccepted: .constant(false))
}
