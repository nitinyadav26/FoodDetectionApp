import SwiftUI

struct FeedView: View {
    @EnvironmentObject var socialManager: SocialManager

    private let reactionEmojis = ["👍", "🔥", "❤️", "😋", "💪", "🎉"]

    var body: some View {
        ScrollView {
            if socialManager.feedItems.isEmpty && !socialManager.isLoading {
                emptyState
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(socialManager.feedItems) { item in
                        feedCard(item)
                    }
                }
                .padding()
            }
        }
        .refreshable {
            await socialManager.loadFeed()
        }
        .overlay {
            if socialManager.isLoading && socialManager.feedItems.isEmpty {
                ProgressView()
            }
        }
        .task {
            await socialManager.loadFeed()
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("social_feed_empty")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("social_feed_empty_subtitle")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
    }

    // MARK: - Feed card

    private func feedCard(_ item: SocialManager.FeedItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                    Text(String(item.displayName.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(.subheadline.weight(.semibold))
                    Text(item.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                feedTypeIcon(item.type)
            }

            // Content
            Text(item.title)
                .font(.subheadline.weight(.medium))

            if !item.description.isEmpty {
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            // Reactions
            HStack(spacing: 6) {
                ForEach(reactionEmojis, id: \.self) { emoji in
                    Button {
                        Task { await socialManager.reactToPost(item, emoji: emoji) }
                    } label: {
                        HStack(spacing: 2) {
                            Text(emoji)
                                .font(.caption)
                            if let count = item.reactions[emoji], count > 0 {
                                Text("\(count)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            item.userReaction == emoji
                                ? Color.green.opacity(0.2)
                                : Color(.systemGray6)
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func feedTypeIcon(_ type: SocialManager.FeedItemType) -> some View {
        Group {
            switch type {
            case .meal:
                Image(systemName: "fork.knife")
                    .foregroundColor(.orange)
            case .streak:
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
            case .challenge:
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
            case .achievement:
                Image(systemName: "medal.fill")
                    .foregroundColor(.purple)
            }
        }
        .font(.caption)
        .padding(6)
        .background(Color(.systemGray6))
        .clipShape(Circle())
    }
}
