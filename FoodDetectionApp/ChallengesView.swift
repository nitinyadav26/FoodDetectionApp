import SwiftUI

struct ChallengesView: View {
    @EnvironmentObject var socialManager: SocialManager
    @State private var showCreateChallenge = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Active challenges
                if !socialManager.activeChallenges.isEmpty {
                    sectionHeader(String(localized: "social_active_challenges"))

                    ForEach(socialManager.activeChallenges) { challenge in
                        activeChallengeCard(challenge)
                    }
                }

                // Available challenges
                if !socialManager.availableChallenges.isEmpty {
                    sectionHeader(String(localized: "social_available_challenges"))

                    ForEach(socialManager.availableChallenges) { challenge in
                        availableChallengeCard(challenge)
                    }
                }

                // Empty state
                if socialManager.activeChallenges.isEmpty && socialManager.availableChallenges.isEmpty && !socialManager.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "trophy")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("social_no_challenges")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("social_create_first_challenge")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                }
            }
            .padding()
        }
        .refreshable {
            await socialManager.loadChallenges()
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showCreateChallenge = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(20)
            .accessibilityLabel("Create Challenge")
        }
        .sheet(isPresented: $showCreateChallenge) {
            CreateChallengeSheet()
                .environmentObject(socialManager)
        }
        .task {
            await socialManager.loadChallenges()
        }
    }

    // MARK: - Subviews

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
    }

    private func activeChallengeCard(_ challenge: SocialManager.Challenge) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: challenge.iconName)
                    .font(.title2)
                    .foregroundColor(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.subheadline.weight(.semibold))
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                if challenge.isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: Double(challenge.currentValue), total: Double(challenge.targetValue))
                    .tint(challenge.isCompleted ? .green : .blue)

                HStack {
                    Text("\(challenge.currentValue)/\(challenge.targetValue) \(challenge.unit)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(daysRemaining(challenge.endDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(challenge.participantCount) \(String(localized: "social_participants"))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func availableChallengeCard(_ challenge: SocialManager.Challenge) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: challenge.iconName)
                    .font(.title2)
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.subheadline.weight(.semibold))
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(challenge.participantCount) \(String(localized: "social_participants"))")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)

                Spacer()

                Button {
                    Task { await socialManager.joinChallenge(challenge) }
                } label: {
                    Text("social_join")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func daysRemaining(_ endDate: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        if days <= 0 {
            return String(localized: "social_ended")
        }
        return String(localized: "social_days_left \(days)")
    }
}

// MARK: - Create Challenge Sheet

struct CreateChallengeSheet: View {
    @EnvironmentObject var socialManager: SocialManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var targetValue = ""
    @State private var unit = "calories"
    @State private var durationDays = 7
    @State private var isCreating = false

    private let units = ["calories", "meals", "steps", "glasses"]
    private let durations = [3, 7, 14, 30]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("social_challenge_details")) {
                    TextField(String(localized: "social_challenge_title"), text: $title)
                    TextField(String(localized: "social_challenge_description"), text: $description)
                }

                Section(header: Text("social_challenge_goal")) {
                    TextField(String(localized: "social_target_value"), text: $targetValue)
                        .keyboardType(.numberPad)

                    Picker(String(localized: "social_unit"), selection: $unit) {
                        ForEach(units, id: \.self) { u in
                            Text(u.capitalized).tag(u)
                        }
                    }

                    Picker(String(localized: "social_duration"), selection: $durationDays) {
                        ForEach(durations, id: \.self) { d in
                            Text("\(d) \(String(localized: "social_days"))").tag(d)
                        }
                    }
                }
            }
            .navigationTitle(Text("social_create_challenge"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "social_create")) {
                        guard let target = Int(targetValue), !title.isEmpty else { return }
                        isCreating = true
                        Task {
                            await socialManager.createChallenge(
                                title: title,
                                description: description,
                                targetValue: target,
                                unit: unit,
                                durationDays: durationDays
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || targetValue.isEmpty || isCreating)
                }
            }
        }
    }
}
