import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var socialManager: SocialManager
    @State private var searchText = ""
    @State private var showAddFriend = false
    @State private var addFriendIdentifier = ""
    @State private var isAddingFriend = false

    var filteredFriends: [SocialManager.FriendProfile] {
        if searchText.isEmpty {
            return socialManager.friends
        }
        return socialManager.friends.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(String(localized: "social_search_friends"), text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    // Pending requests
                    if !socialManager.pendingRequests.isEmpty {
                        Section {
                            ForEach(socialManager.pendingRequests) { request in
                                pendingRequestRow(request)
                            }
                        } header: {
                            sectionHeader(String(localized: "social_pending_requests"), count: socialManager.pendingRequests.count)
                        }
                    }

                    // Friends list
                    Section {
                        if filteredFriends.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("social_no_friends")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(filteredFriends) { friend in
                                friendRow(friend)
                            }
                        }
                    } header: {
                        sectionHeader(String(localized: "social_friends_header"), count: filteredFriends.count)
                    }
                }
            }
            .refreshable {
                await socialManager.loadFriends()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showAddFriend = true
            } label: {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(20)
            .accessibilityLabel("Add Friend")
        }
        .alert(String(localized: "social_add_friend"), isPresented: $showAddFriend) {
            TextField(String(localized: "social_friend_email_username"), text: $addFriendIdentifier)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button(String(localized: "social_send_request")) {
                guard !addFriendIdentifier.isEmpty else { return }
                Task {
                    isAddingFriend = true
                    await socialManager.addFriend(identifier: addFriendIdentifier)
                    addFriendIdentifier = ""
                    isAddingFriend = false
                }
            }
            Button(String(localized: "cancel"), role: .cancel) {
                addFriendIdentifier = ""
            }
        } message: {
            Text("social_add_friend_message")
        }
        .task {
            await socialManager.loadFriends()
        }
    }

    // MARK: - Subviews

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text("\(count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func pendingRequestRow(_ request: SocialManager.FriendRequest) -> some View {
        HStack(spacing: 12) {
            avatarView(name: request.fromDisplayName, url: request.fromAvatarURL)

            VStack(alignment: .leading, spacing: 2) {
                Text(request.fromDisplayName)
                    .font(.subheadline.weight(.semibold))
                Text("social_wants_to_be_friend")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                Task { await socialManager.acceptRequest(request) }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .accessibilityLabel("Accept")

            Button {
                Task { await socialManager.declineRequest(request) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .accessibilityLabel("Decline")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func friendRow(_ friend: SocialManager.FriendProfile) -> some View {
        HStack(spacing: 12) {
            avatarView(name: friend.displayName, url: friend.avatarURL)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 8) {
                    Label("Lv.\(friend.level)", systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Label("\(friend.streak)d", systemImage: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }

            Spacer()

            if !friend.badges.isEmpty {
                Text(friend.badges.prefix(3).joined())
                    .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                Task { await socialManager.removeFriend(friend) }
            } label: {
                Label("Remove", systemImage: "person.badge.minus")
            }
        }
    }

    private func avatarView(name: String, url: String?) -> some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
            Text(String(name.prefix(1)).uppercased())
                .font(.headline)
                .foregroundColor(.green)
        }
        .frame(width: 44, height: 44)
    }
}
