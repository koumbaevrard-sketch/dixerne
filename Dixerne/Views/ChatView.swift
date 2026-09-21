import SwiftUI
import PhotosUI
import UIKit
import LocalLLMClient

/// Écran principal : conversation + barre d'entrée (texte, dictée, photo, caméra).
struct ChatView: View {
    @Bindable var viewModel: ChatViewModel

    @State private var showPersonas = false
    @State private var showModels = false
    @State private var showCamera = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var pickedImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.isModelLoaded {
                modelBanner
            }
            if let error = viewModel.lastError {
                errorBanner(error)
            }

            MessageList(messages: viewModel.messages) { text in
                viewModel.speech.speak(text)
            }

            inputBar
        }
        .navigationTitle("Dixerne")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showPersonas = true
                } label: {
                    Image(systemName: "person.crop.circle")
                }
                Button {
                    showModels = true
                } label: {
                    Image(systemName: "brain.head.profile")
                }
                Button {
                    viewModel.clearChat()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showPersonas) {
            PersonaPickerView(viewModel: viewModel)
        }
        .sheet(isPresented: $showModels) {
            ModelPickerView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $pickedImage)
        }
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            pickedPhoto = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await viewModel.sendImageText(image)
                }
            }
        }
        .onChange(of: pickedImage) { _, image in
            guard let image else { return }
            pickedImage = nil
            Task { await viewModel.sendImageText(image) }
        }
    }

    // MARK: - Bandeaux

    private var modelBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Aucun modèle chargé")
                    .font(.subheadline)
                    .bold()
                Text("Téléchargez un modèle pour commencer (100 % hors ligne).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Télécharger") { showModels = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.yellow.opacity(0.15))
    }

    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(error)
                .font(.footnote)
            Spacer()
            Button {
                viewModel.lastError = nil
            } label: {
                Image(systemName: "xmark")
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
    }

    // MARK: - Barre d'entrée

    private var inputBar: some View {
        HStack(spacing: 8) {
            PhotosPicker(selection: $pickedPhoto, matching: .images) {
                Image(systemName: "photo")
            }
            Button {
                showCamera = true
            } label: {
                Image(systemName: "camera")
            }

            TextField("Message…", text: $viewModel.inputText)
                .textFieldStyle(.plain)
                .submitLabel(.send)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
                .onSubmit {
                    viewModel.sendMessage()
                }
                .disabled(viewModel.isGenerating)

            micButton

            if viewModel.isGenerating {
                Button {
                    viewModel.cancelGeneration()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
            } else {
                Button {
                    viewModel.sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(trimmedInput.isEmpty || !viewModel.isModelLoaded)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var trimmedInput: String {
        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var micButton: some View {
        Button {
            if viewModel.speech.isRecording {
                viewModel.speech.stopRecording()
                viewModel.inputText = viewModel.speech.transcript
            } else {
                Task {
                    if await viewModel.speech.requestAuthorization() {
                        try? viewModel.speech.startRecording()
                    } else {
                        viewModel.lastError = "Autorisation microphone refusée."
                    }
                }
            }
        } label: {
            Image(systemName: viewModel.speech.isRecording ? "stop.circle" : "mic")
                .font(.title3)
        }
    }
}

// MARK: - Liste des messages

private struct MessageList: View {
    let messages: [LLMInput.Message]
    var onSpeak: (String) -> Void

    @State private var position = ScrollPosition(idType: LLMInput.Message.ID.self)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(messages) { message in
                    MessageBubbleView(message: message, onSpeak: onSpeak)
                        .id(message.id)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .scrollPosition($position)
        .onChange(of: messages) { _, _ in
            position.scrollTo(edge: .bottom)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
