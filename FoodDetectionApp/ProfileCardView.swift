import SwiftUI
import CoreImage.CIFilterBuiltins
import FirebaseAuth

struct ProfileCardView: View {
    @StateObject private var authManager = AuthManager.shared

    @State private var userName: String = "FoodSense User"
    @State private var level: Int = 5
    @State private var badges: [String] = ["🥗", "🔥", "💪", "🏆"]
    @State private var streak: Int = 7

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card
                VStack(spacing: 20) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Text(String(userName.prefix(1)).uppercased())
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.white)
                    }

                    // Name & Level
                    VStack(spacing: 4) {
                        Text(userName)
                            .font(.title2.weight(.bold))
                        Text("Level \(level)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Badges
                    if !badges.isEmpty {
                        VStack(spacing: 6) {
                            Text("social_badges")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 8) {
                                ForEach(badges, id: \.self) { badge in
                                    Text(badge)
                                        .font(.title2)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }

                    // Streak
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(streak) \(String(localized: "social_day_streak"))")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(20)

                    // QR Code
                    if let qrImage = generateQRCode() {
                        VStack(spacing: 8) {
                            Text("social_scan_to_add")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 160)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.1), radius: 16, y: 4)
                .padding(.horizontal)

                // Share button
                if #available(iOS 16.0, *) {
                    ShareLink(
                        item: shareText,
                        subject: Text("social_profile_share_subject"),
                        message: Text("social_profile_share_message")
                    ) {
                        Label(String(localized: "social_share_profile"), systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(14)
                            .padding(.horizontal)
                    }
                } else {
                    Button {
                        let av = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let root = scene.windows.first?.rootViewController {
                            root.present(av, animated: true)
                        }
                    } label: {
                        Label(String(localized: "social_share_profile"), systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(14)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(Text("social_my_profile_card"))
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - QR Code

    private func generateQRCode() -> UIImage? {
        let userId = authManager.currentUser?.uid ?? "foodsense-user"
        let data = "foodsense://add-friend/\(userId)".data(using: .utf8)

        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }

        let scale = 10.0
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    private var shareText: String {
        let userId = authManager.currentUser?.uid ?? "foodsense-user"
        return "Add me on FoodSense! \(userName) - Level \(level) | foodsense://add-friend/\(userId)"
    }
}
