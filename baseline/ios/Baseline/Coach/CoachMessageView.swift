import SwiftUI

struct CoachMessageView: View {
    @EnvironmentObject private var viewModel: CoachViewModel

    private var canSend: Bool {
        !viewModel.draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            sessionTypeSelector
            messagesArea
            inputBar
        }
        .background(Theme.Colors.background)
    }

    private var sessionTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.sessionTypes) { type in
                    sessionTypeChip(type)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func sessionTypeChip(_ type: CoachSessionType) -> some View {
        let isActive = viewModel.sessionType == type
        return Button {
            viewModel.selectSessionType(type)
        } label: {
            Text(type.displayName)
                .font(.system(size: 10))
                .foregroundStyle(isActive ? Color(hex: "#9B7FD4") : Color(hex: "#555555"))
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(isActive ? Color(hex: "#1A1228") : Color(hex: "#0F0F0F"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color(hex: "#2D1F4A") : Color(hex: "#1E1E1E"), lineWidth: 1),
                )
        }
        .buttonStyle(.plain)
    }

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.messages) { message in
                        Group {
                            switch message.role {
                            case .coach:
                                CoachBubble(message: message)
                            case .user:
                                UserBubble(message: message)
                            }
                        }
                        .id(message.id)
                    }

                    if viewModel.isTyping {
                        TypingIndicator()
                            .id("typing-indicator")
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("messages-bottom")
                }
                .padding(12)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.isTyping) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if viewModel.isTyping {
                proxy.scrollTo("typing-indicator", anchor: .bottom)
            } else {
                proxy.scrollTo("messages-bottom", anchor: .bottom)
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField(
                "",
                text: $viewModel.draftMessage,
                prompt: Text("Message the coach...")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textMuted),
            )
            .font(.system(size: 13))
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(hex: "#0F0F0F"))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
            )

            Button {
                viewModel.sendMessage(viewModel.draftMessage)
            } label: {
                Circle()
                    .fill(Theme.Colors.accent)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white),
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .opacity(canSend ? 1 : 0.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: "#1A1A1A"))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Bubbles

private struct CoachBubble: View {
    let message: CoachMessage

    private var maxWidth: CGFloat {
        UIScreen.main.bounds.width * 0.85
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Theme.Colors.accent)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 3) {
                Text("COACH")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#4A3880"))
                    .tracking(1.2)
                    .textCase(.uppercase)

                Text(message.text)
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

private struct UserBubble: View {
    let message: CoachMessage

    private var maxWidth: CGFloat {
        UIScreen.main.bounds.width * 0.80
    }

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Text(message.text)
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

// MARK: - Typing indicator

private struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Theme.Colors.accent)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

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
            .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
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
        .onAppear {
            animating = true
        }
    }
}
