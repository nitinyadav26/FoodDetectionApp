import SwiftUI

struct SocialTabView: View {
    enum SocialSection: String, CaseIterable {
        case friends = "Friends"
        case feed = "Feed"
        case challenges = "Challenges"
        case leaderboard = "Leaderboard"
    }

    @State private var selectedSection: SocialSection = .feed
    @StateObject private var socialManager = SocialManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedSection) {
                    ForEach(SocialSection.allCases, id: \.self) { section in
                        Text(LocalizedStringKey("social_section_\(section.rawValue.lowercased())"))
                            .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                Divider()
                    .padding(.top, 8)

                Group {
                    switch selectedSection {
                    case .friends:
                        FriendsView()
                    case .feed:
                        FeedView()
                    case .challenges:
                        ChallengesView()
                    case .leaderboard:
                        LeaderboardView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(Text("social_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        ProfileCardView()
                    } label: {
                        Image(systemName: "qrcode")
                            .accessibilityLabel("Share Profile")
                    }
                }
            }
        }
        .environmentObject(socialManager)
    }
}
