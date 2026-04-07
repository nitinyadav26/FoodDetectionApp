import SwiftUI

struct BadgesView: View {
    @ObservedObject var badgeManager = BadgeManager.shared
    @State private var selectedCategory: BadgeCategory? = nil
    @State private var selectedBadge: BadgeDefinition? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var filteredBadges: [BadgeDefinition] {
        if let cat = selectedCategory {
            return BadgeDefinition.allBadges.filter { $0.category == cat }
        }
        return BadgeDefinition.allBadges
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                Text("\(badgeManager.earnedCount) of \(badgeManager.totalCount) Badges Earned")
                    .font(.headline)
                    .padding(.top)

                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryButton(nil, label: NSLocalizedString("badge_cat_all", comment: ""))
                        ForEach(BadgeCategory.allCases) { cat in
                            categoryButton(cat, label: cat.localizedName)
                        }
                    }
                    .padding(.horizontal)
                }

                // Badge grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredBadges) { badge in
                        let isEarned = badgeManager.isUnlocked(badge.id)
                        BadgeCell(badge: badge, isEarned: isEarned)
                            .onTapGesture {
                                selectedBadge = badge
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(NSLocalizedString("badges_title", comment: ""))
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailSheet(badge: badge, isEarned: badgeManager.isUnlocked(badge.id))
        }
        .onAppear {
            badgeManager.checkBadges()
        }
    }

    @ViewBuilder
    private func categoryButton(_ cat: BadgeCategory?, label: String) -> some View {
        let isSelected = selectedCategory == cat
        Button(action: { selectedCategory = cat }) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(UIColor.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Badge Cell

struct BadgeCell: View {
    let badge: BadgeDefinition
    let isEarned: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isEarned ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: badge.icon)
                    .font(.title2)
                    .foregroundColor(isEarned ? .blue : .gray)
            }
            Text(NSLocalizedString(badge.name, comment: ""))
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(isEarned ? .primary : .secondary)
        }
        .opacity(isEarned ? 1.0 : 0.5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(NSLocalizedString(badge.name, comment: "")), \(isEarned ? "earned" : "locked")")
    }
}

// MARK: - Badge Detail Sheet

struct BadgeDetailSheet: View {
    let badge: BadgeDefinition
    let isEarned: Bool
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            ZStack {
                Circle()
                    .fill(isEarned ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: badge.icon)
                    .font(.system(size: 44))
                    .foregroundColor(isEarned ? .blue : .gray)
            }

            Text(NSLocalizedString(badge.name, comment: ""))
                .font(.title2)
                .bold()

            Text(NSLocalizedString(badge.description, comment: ""))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if isEarned {
                Label(NSLocalizedString("badge_earned", comment: ""), systemImage: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.headline)
            } else {
                Label(NSLocalizedString("badge_locked", comment: ""), systemImage: "lock.fill")
                    .foregroundColor(.secondary)
                    .font(.headline)
            }

            Text(badge.category.localizedName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)

            Spacer()
        }
    }
}

// MARK: - Identifiable conformance for BadgeDefinition (sheet)
extension BadgeDefinition: Hashable {
    static func == (lhs: BadgeDefinition, rhs: BadgeDefinition) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
