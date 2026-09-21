import SwiftUI

/// Sélecteur + téléchargeur de modèles GGUF.
struct ModelPickerView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(AIModel.allCases) { model in
                let isCurrent = viewModel.currentModel == model && viewModel.isModelLoaded

                Button {
                    if !viewModel.isLoadingModel {
                        Task { await viewModel.loadModel(model) }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text("\(model.estimatedSize) · hors ligne")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        statusView(for: model, isCurrent: isCurrent)
                    }
                    .padding(.vertical, 4)
                }
                .disabled(viewModel.isLoadingModel)
            }
            .navigationTitle("Modèle")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { progressBar }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func statusView(for model: AIModel, isCurrent: Bool) -> some View {
        if viewModel.isLoadingModel && viewModel.currentModel == model {
            Image(systemName: "arrow.down.circle")
        } else if isCurrent {
            Image(systemName: "checkmark")
                .foregroundStyle(Color.accentColor)
        } else {
            Image(systemName: "arrow.down.circle.dotted")
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        if viewModel.isLoadingModel {
            VStack(spacing: 8) {
                ProgressView(value: viewModel.loadProgress)
                Text("Téléchargement… \(Int(viewModel.loadProgress * 100)) %")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.bar)
        }
    }
}
