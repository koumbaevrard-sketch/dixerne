import SwiftUI

struct RootView: View {
    @State private var viewModel = ChatViewModel()

    var body: some View {
        ChatView(viewModel: viewModel)
    }
}
