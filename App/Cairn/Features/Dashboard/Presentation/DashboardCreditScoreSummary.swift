import SwiftUI

struct DashboardCreditScoreSummary: View {
    let repository: any CreditScoreRepository
    @State private var scores: [CreditScore] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if !scores.isEmpty {
                VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                    CairnSectionHeading("Credit scores", subtitle: "Manually entered")

                    ForEach(scores, id: \.provider) { score in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: CairnSpacing.extraSmall) {
                                Text(score.provider.displayName)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(CairnColor.textPrimary)
                                Text("Updated \(score.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.footnote)
                                    .foregroundStyle(CairnColor.textSecondary)
                            }

                            Spacer(minLength: CairnSpacing.medium)

                            VStack(alignment: .trailing) {
                                Text(score.value.formatted())
                                    .cairnRowAmount()
                                    .foregroundStyle(CairnColor.textPrimary)
                                Text("of \(score.scale.maximum.formatted())")
                                    .font(.caption)
                                    .foregroundStyle(CairnColor.textSecondary)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(score.provider.displayName) credit score, \(score.value) of \(score.scale.maximum), manually entered, updated \(score.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    }

                    if let errorMessage {
                        Button("\(errorMessage) Retry") {
                            Task { await load() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(CairnColor.textSecondary)
                    }
                }
            } else if let errorMessage {
                Button("Credit scores unavailable. Retry") {
                    Task { await load() }
                }
                .font(.subheadline)
                .foregroundStyle(CairnColor.textSecondary)
                .accessibilityLabel("\(errorMessage) Retry loading credit scores")
            } else if isLoading {
                ProgressView("Loading credit scores")
                    .font(.subheadline)
                    .tint(CairnColor.plum)
                    .foregroundStyle(CairnColor.textSecondary)
            } else if !isLoading {
                VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                    CairnSectionHeading("Credit score")

                    Text("No scores added")
                        .font(.subheadline)
                        .foregroundStyle(CairnColor.textSecondary)

                    NavigationLink {
                        CreditScoresView(repository: repository)
                    } label: {
                        Text("Add credit score")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(CairnSecondaryButtonStyle())
                    .accessibilityLabel("Add credit score")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { Task { await load() } }
    }

    private func load() async {
        isLoading = true
        do {
            scores = try await repository.fetchScores()
            errorMessage = nil
        } catch {
            errorMessage = "Credit scores could not be loaded."
        }
        isLoading = false
    }
}
