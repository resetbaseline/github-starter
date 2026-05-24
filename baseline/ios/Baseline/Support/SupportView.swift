import PhotosUI
import SwiftUI
import UIKit

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SupportViewModel()
    @State private var photoPickerItem: PhotosPickerItem?

    var initialCategory: SupportCategory?

    private let glowAccent = Color(red: 124 / 255, green: 92 / 255, blue: 191 / 255)

    var body: some View {
        ZStack {
            Color(hex: "#07040F")
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    glowAccent.opacity(0.15),
                    Color.clear,
                ],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0,
                endRadius: 420,
            )
            .ignoresSafeArea()

            if viewModel.isSubmitted {
                submittedPhase
            } else {
                VStack(spacing: 0) {
                    topBar

                    if viewModel.selectedCategory == nil {
                        categoryPhase
                    } else {
                        conversationPhase
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.applyInitialCategory(initialCategory)
        }
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.selectedScreenshot = image
                }
            }
        }
    }

    private var topBar: some View {
        ZStack {
            Text("Support")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack {
                Spacer(minLength: 0)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.textMuted)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
        }
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Phase 1

    private var categoryPhase: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("How can we help?")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Select a topic to get started.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                    ],
                    spacing: 8,
                ) {
                    ForEach(SupportCategory.allCases) { category in
                        Button {
                            viewModel.selectCategory(category)
                        } label: {
                            VStack(spacing: 0) {
                                Text(category.emoji)
                                    .font(.system(size: 22))
                                Text(category.displayName)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 6)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color(hex: "#0F0F0F"))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 24)
            }
            .padding(28)
        }
    }

    // MARK: - Phase 2 & 3

    private var conversationPhase: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            messageView(message)
                                .id(message.id)
                        }

                        if viewModel.isTyping {
                            SupportTypingIndicator()
                                .id("typing")
                        }

                        if viewModel.showForm {
                            supportFormCard
                                .id("form")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.isTyping) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.showForm) { _, shown in
                    if shown {
                        withAnimation {
                            proxy.scrollTo("form", anchor: .bottom)
                        }
                    }
                }
            }

            inputBar
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if viewModel.isTyping {
            withAnimation {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        } else if let last = viewModel.messages.last {
            withAnimation {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    @ViewBuilder
    private func messageView(_ message: SupportMessage) -> some View {
        switch message.role {
        case .user:
            SupportUserBubble(text: message.text)
        case .bot:
            SupportCoachBubble(text: message.text)
        case .escalatePrompt:
            Button {
                viewModel.showEscalationForm()
            } label: {
                Text(message.text)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 28)
            }
            .buttonStyle(.plain)
        }
    }

    private var inputBar: some View {
        let trimmedEmpty = viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return HStack(spacing: 10) {
            TextField("Type your message...", text: $viewModel.userInput, axis: .vertical)
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1 ... 4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "#0F0F0F"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                )
                .disabled(viewModel.isTyping)

            Button {
                viewModel.sendUserMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 26, height: 26)
                    .background(Theme.Colors.accent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(trimmedEmpty || viewModel.isTyping)
            .opacity(trimmedEmpty || viewModel.isTyping ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#07040F"))
    }

    private var supportFormCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tell us more")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.textPrimary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.formText)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 80)

                if viewModel.formText.isEmpty {
                    Text("Describe what happened, what you expected, and steps to reproduce…")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textMuted)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
            }
            .padding(10)
            .background(Color(hex: "#0A0A0A"))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
            )

            HStack(spacing: 10) {
                PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.textMuted)
                        Text("Attach screenshot (optional)")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(hex: "#111111"))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                    )
                }
                .buttonStyle(.plain)

                if let image = viewModel.selectedScreenshot {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                        Button {
                            viewModel.selectedScreenshot = nil
                            photoPickerItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.white, Color.black.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .offset(x: 6, y: -6)
                    }
                }
            }

            if viewModel.selectedCategory == .betaFeedback {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Device info will be attached automatically")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Colors.textMuted)
                    Text("\(viewModel.deviceInfo["model"] ?? "") · iOS \(viewModel.deviceInfo["systemVersion"] ?? "")")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Colors.textMuted)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#0A0614"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            BaselineButton(title: "Submit") {
                viewModel.submitForm()
            }
            .disabled(
                viewModel.formText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || viewModel.isSubmitting,
            )
            .opacity(
                viewModel.formText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || viewModel.isSubmitting ? 0.5 : 1,
            )
        }
        .padding(14)
        .background(Color(hex: "#0F0F0F"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
        )
    }

    // MARK: - Phase 4

    private var submittedPhase: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Colors.accent)

            Text("Sent to our team")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("We'll reply to your account email within 24–48 hours.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.Colors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Close") {
                dismiss()
            }
            .font(.system(size: 11))
            .foregroundStyle(Theme.Colors.accent)
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Bubbles

private struct SupportCoachBubble: View {
    let text: String

    private var maxWidth: CGFloat {
        UIScreen.main.bounds.width * 0.85
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CoachPeakIcon(size: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text("COACH")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#4A3880"))
                    .tracking(1.2)
                    .textCase(.uppercase)

                Text(text)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#9B7FD4"))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
            .frame(maxWidth: maxWidth, alignment: .leading)
            .background(Color(hex: "#0A0614"))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 4,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 12,
                    style: .continuous,
                ),
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 4,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 12,
                    style: .continuous,
                )
                .stroke(Color(hex: "#1A1030"), lineWidth: 1),
            )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SupportUserBubble: View {
    let text: String

    private var maxWidth: CGFloat {
        UIScreen.main.bounds.width * 0.80
    }

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(Color.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(EdgeInsets(top: 8, leading: 11, bottom: 8, trailing: 11))
                .frame(maxWidth: maxWidth, alignment: .trailing)
                .background(Color(hex: "#1A1228"))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 4,
                        topTrailingRadius: 12,
                        style: .continuous,
                    ),
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 4,
                        topTrailingRadius: 12,
                        style: .continuous,
                    )
                    .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                )
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private struct SupportTypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CoachPeakIcon(size: 20)
                .padding(.top, 2)

            HStack(spacing: 4) {
                ForEach(0 ..< 3, id: \.self) { index in
                    Circle()
                        .fill(Color(hex: "#4A3880"))
                        .frame(width: 5, height: 5)
                        .opacity(animating ? 1.0 : 0.3)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animating,
                        )
                }
            }
            .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            .background(Color(hex: "#0A0614"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Spacer(minLength: 0)
        }
        .onAppear { animating = true }
    }
}
