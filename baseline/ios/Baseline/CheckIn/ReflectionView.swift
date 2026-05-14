import SwiftUI

struct ReflectionView: View {
    @EnvironmentObject private var viewModel: CheckInViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text("Short answers are enough—they show up in your coach note and memory.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(viewModel.reflectionDrafts) { draft in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(draft.questionText)
                            .font(Theme.Typography.headline())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        TextEditor(
                            text: Binding(
                                get: { viewModel.answer(for: draft.id) },
                                set: { viewModel.updateReflectionAnswer(id: draft.id, text: $0) },
                            ),
                        )
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100, alignment: .topLeading)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Tomorrow’s intention (optional)")
                        .font(Theme.Typography.subheadline())
                        .foregroundStyle(Theme.Colors.textSecondary)
                    TextField(
                        "e.g. Block 90m for writing before noon",
                        text: Binding(
                            get: { viewModel.tomorrowIntention },
                            set: { viewModel.tomorrowIntention = $0 },
                        ),
                        axis: .vertical,
                    )
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1 ... 3)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                }

                BaselineButton(title: "Finish check-in") {
                    viewModel.submitReflectionAndShowResult()
                }
                .padding(.top, Theme.Spacing.xs)
            }
            .padding(Theme.Spacing.sm)
        }
        .background(Theme.Colors.background)
    }
}
