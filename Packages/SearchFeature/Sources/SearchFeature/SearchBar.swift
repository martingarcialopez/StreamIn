import SwiftUI
import DesignSystem

/// The landing page's search field, with its halo behind it.
struct SearchBar: View {
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: Spacing.default) {
            Image(systemName: Symbol.magnifyingglass)
                .foregroundStyle(.secondary)
            TextField(String(localized: .searchPrompt), text: $text)
                .submitLabel(.search)
                .onSubmit(onSubmit)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, Spacing.comfortable)
        .padding(.vertical, Spacing.default)
        .background(AppPalette.secondaryBackground, in: .rect(cornerRadius: Radius.large))
        .background {
            SearchBarHalo(cornerRadius: Radius.large)
        }
    }
}
