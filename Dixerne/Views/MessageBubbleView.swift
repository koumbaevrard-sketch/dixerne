import SwiftUI
import LocalLLMClientCore

struct MessageBubbleView: View {
    let message: LLMInput.Message
    var onSpeak: ((String) -> Void)? = nil

    var body: some View {
        let isUser = message.role == .user

        HStack(alignment: .bottom, spacing: 8) {
            if isUser {
                Spacer(minLength: 48)
            }

            Text(message.content)
                .textSelection(.enabled)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isUser ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isUser ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if !isUser {
                if let onSpeak {
                    Button {
                        onSpeak(message.content)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
                Spacer(minLength: 48)
            }
        }
    }
}
