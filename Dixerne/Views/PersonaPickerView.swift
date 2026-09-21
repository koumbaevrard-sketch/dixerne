import SwiftUI

/// Sélecteur de persona : change le system prompt sans effacer la conversation.
struct PersonaPickerView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(PersonaCatalog.all) { persona in
                Button {
                    viewModel.selectPersona(persona)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(persona.emoji)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(persona.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(persona.systemPrompt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        if viewModel.currentPersona.id == persona.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Persona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}
