import SwiftUI

struct FutureSelfView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FutureSelfViewModel()

    private let glowAccent = Color(red: 124 / 255, green: 92 / 255, blue: 191 / 255)

    private static let writingPrompts: [String] = [
        "In one year, I want to be someone who...",
        "The habit I most want to build is...",
        "What I'm afraid to admit I want is...",
    ]

    var body: some View {
        ZStack {
            Color(hex: "#07040F")
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    glowAccent.opacity(0.1),
                    Color.clear,
                ],
                startPoint: .top,
                endPoint: .bottom,
            )
            .frame(height: 300)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(spacing: 0) {
                        heroSection
                        promptsSection
                        coachContextCard
                    }
                }
            }

            savedConfirmationOverlay
        }
        .onAppear {
            viewModel.onAppear()
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        ZStack {
            HStack(spacing: 0) {
                Group {
                    if viewModel.isEditing {
                        Button("Cancel") {
                            viewModel.discardChanges()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textMuted)
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    if viewModel.isEditing {
                        Button("Save") {
                            viewModel.saveMessage()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.accent)
                        .disabled(viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                    } else {
                        Button("Edit") {
                            viewModel.startEditing()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Text("Future Self")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Dear future me,")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 6)

            if viewModel.hasSavedMessage && !viewModel.isEditing {
                savedMessageHero
            } else if viewModel.isEditing {
                editingHero
            }
        }
    }

    private var savedMessageHero: some View {
        Group {
            Text(viewModel.savedMessage)
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

            Spacer(minLength: 12)
                .frame(height: 12)

            Text(viewModel.savedDateFormatted)
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

            Button {
                viewModel.startEditing()
            } label: {
                Text("Edit this message")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }

    private var editingHero: some View {
        Group {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.draftMessage)
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 200)
                    .padding(.horizontal, 20)

                if viewModel.draftMessage.isEmpty {
                    Text("Write to who you want to become. Be honest. Be specific.")
                        .font(.system(size: 16, weight: .light, design: .serif))
                        .foregroundStyle(Theme.Colors.textMuted)
                        .padding(.horizontal, 26)
                        .padding(.top, 14)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 4)

            Text("\(viewModel.wordCount) words")
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: "#333333"))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 24)
                .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var promptsSection: some View {
        if viewModel.isEditing {
            VStack(alignment: .leading, spacing: 10) {
                Text("WRITING PROMPTS")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#3A2A55"))
                    .tracking(1.2)
                    .textCase(.uppercase)

                VStack(spacing: 8) {
                    ForEach(Self.writingPrompts, id: \.self) { prompt in
                        Button {
                            appendPrompt(prompt)
                        } label: {
                            Text(prompt)
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "#555555"))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                                .background(Color(hex: "#0F0F0F"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
    }

    private var coachContextCard: some View {
        Group {
            if !viewModel.isEditing && viewModel.hasSavedMessage {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        CoachPeakIcon(size: 16)
                        Text("COACH")
                            .font(.system(size: 8))
                            .foregroundStyle(Color(hex: "#4A3880"))
                            .tracking(1.2)
                            .textCase(.uppercase)
                    }

                    Text("Your coach reads this when building your daily plan. Update it as you grow.")
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "#9B7FD4"))
                        .lineSpacing(4)
                        .padding(.top, 5)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#0F0828"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                )
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private var savedConfirmationOverlay: some View {
        VStack {
            Spacer(minLength: 0)
            if viewModel.isSaved {
                Text("Saved ✓")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white)
                    .padding(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .background(Color(hex: "#7C5CBF").opacity(0.9))
                    .clipShape(Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 28)
            }
        }
        .animation(.easeOut(duration: 0.25), value: viewModel.isSaved)
        .allowsHitTesting(false)
    }

    private func appendPrompt(_ text: String) {
        if viewModel.draftMessage.isEmpty {
            viewModel.draftMessage = text
        } else {
            viewModel.draftMessage += "\n" + text
        }
    }
}
