import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var socialManager: SocialManager

    @State private var selectedScope = "friends"
    @State private var selectedPeriod = "weekly"

    private let scopes = ["friends", "global"]
    private let periods = ["daily", "weekly", "monthly", "allTime"]

    var body: some View {
        VStack(spacing: 0) {
            // Scope picker
            HStack(spacing: 12) {
                Picker(String(localized: "social_scope"), selection: $selectedScope) {
                    Text("social_scope_friends").tag("friends")
                    Text("social_scope_global").tag("global")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)

                Picker(String(localized: "social_period"), selection: $selectedPeriod) {
                    Text("social_period_daily").tag("daily")
                    Text("social_period_weekly").tag("weekly")
                    Text("social_period_monthly").tag("monthly")
                    Text("social_period_all_time").tag("allTime")
                }
                .pickerStyle(.menu)
                .tint(.green)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            ScrollView {
                if socialManager.leaderboard.isEmpty && !socialManager.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("social_leaderboard_empty")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 0) {
                        // Top 3 podium
                        if socialManager.leaderboard.count >= 3 {
                            podiumView
                                .padding(.bottom, 16)
                        }

                        // Ranked list
                        ForEach(socialManager.leaderboard) { entry in
                            leaderboardRow(entry)
                        }
                    }
                    .padding()
                }
            }
            .refreshable {
                await socialManager.loadLeaderboard(scope: selectedScope, period: selectedPeriod)
            }
        }
        .overlay {
            if socialManager.isLoading && socialManager.leaderboard.isEmpty {
                ProgressView()
            }
        }
        .onChange(of: selectedScope) { _ in
            Task { await socialManager.loadLeaderboard(scope: selectedScope, period: selectedPeriod) }
        }
        .onChange(of: selectedPeriod) { _ in
            Task { await socialManager.loadLeaderboard(scope: selectedScope, period: selectedPeriod) }
        }
        .task {
            await socialManager.loadLeaderboard(scope: selectedScope, period: selectedPeriod)
        }
    }

    // MARK: - Podium

    private var podiumView: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if socialManager.leaderboard.count >= 3 {
                // 2nd place
                podiumColumn(socialManager.leaderboard[1], height: 80, medal: "2", color: .gray)
                // 1st place
                podiumColumn(socialManager.leaderboard[0], height: 110, medal: "1", color: .yellow)
                // 3rd place
                podiumColumn(socialManager.leaderboard[2], height: 60, medal: "3", color: .orange)
            }
        }
        .padding(.top, 12)
    }

    private func podiumColumn(_ entry: SocialManager.LeaderboardEntry, height: CGFloat, medal: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Text(String(entry.displayName.prefix(1)).uppercased())
                    .font(.title3.weight(.bold))
                    .foregroundColor(color)
            }
            .overlay(alignment: .bottomTrailing) {
                Text(medal)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(color)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }

            Text(entry.displayName)
                .font(.caption2)
                .lineLimit(1)

            Text("\(entry.score)")
                .font(.caption.weight(.bold))
                .foregroundColor(.green)

            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.3))
                .frame(height: height)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Row

    private func leaderboardRow(_ entry: SocialManager.LeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(entry.rank <= 3 ? .orange : .secondary)
                .frame(width: 36)

            ZStack {
                Circle()
                    .fill(entry.isCurrentUser ? Color.green.opacity(0.3) : Color(.systemGray5))
                Text(String(entry.displayName.prefix(1)).uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundColor(entry.isCurrentUser ? .green : .primary)
            }
            .frame(width: 36, height: 36)

            Text(entry.displayName)
                .font(.subheadline)
                .fontWeight(entry.isCurrentUser ? .bold : .regular)

            Spacer()

            Text("\(entry.score) pts")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.green)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            entry.isCurrentUser
                ? Color.green.opacity(0.08)
                : Color.clear
        )
        .cornerRadius(10)
    }
}
