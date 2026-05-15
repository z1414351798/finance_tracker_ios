import SwiftUI

struct PrivacyPolicyView: View {
    private let sections: [(heading: String, body: String)] = [
        (
            "1. Information We Collect",
            """
            • Account info: username, email address
            • Financial data: transaction names, amounts, dates, categories, notes
            • Receipt images: photos you upload, stored securely in cloud storage
            • Usage data: login times (no third-party analytics)
            """
        ),
        (
            "2. How We Use Your Information",
            """
            • To provide and operate the FinanceTracker service
            • To display your financial summaries and history
            • We do NOT sell or share your data with third parties for marketing
            """
        ),
        (
            "3. Data Storage & Security",
            """
            • Data stored on US servers over HTTPS (TLS encryption)
            • Passwords are hashed and never stored in plain text
            • Receipt images use time-limited private access URLs
            """
        ),
        (
            "4. Third-Party Services",
            """
            • Google Sign-In (optional): Google's privacy policy applies to authentication only
            • Cloud Storage: stored on our own MinIO-compatible servers, no third-party image hosting
            """
        ),
        (
            "5. Data Retention",
            """
            • Data retained while account is active
            • Account deletion removes all data within 30 days
            """
        ),
        (
            "6. Your Rights (GDPR & CCPA)",
            """
            • Access, deletion, correction, and portability of your data
            • California residents: we do not sell personal information
            """
        ),
        (
            "7. Children's Privacy",
            "Not directed at children under 13."
        ),
        (
            "8. Contact",
            "Privacy questions: wisefintrakr.com"
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Last updated: May 2026")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.heading)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(section.body)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
