import SwiftUI
import DesignSystem

struct LandingView: View {
    @Binding var searchText: String
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sectionGap) {
            Spacer(minLength: 0)
            AppLogoMark(size: 120)
            Text(verbatim: Self.appName)
                .font(.largeTitle.bold())
            VStack(spacing: Spacing.default) {
                SearchBar(text: $searchText, onSubmit: onSubmit)
                // TMDB's terms ask for credit, and for JustWatch's on watch-provider data.
                Text(.searchLandingCredits)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.screenPadding)
            Spacer(minLength: 0)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppPalette.background)
    }

    // Pulled from Info.plist so the localized display name (en/es) flows
    // through automatically — same source iOS uses for the Home Screen icon.
    private static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "StreamIn"
    }
}

private struct SearchBar: View {
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
        .background(AppPalette.secondaryBackground)
        .clipShape(.rect(cornerRadius: Radius.large))
    }
}

#Preview {
    @Previewable @State var text = ""
    NavigationStack {
        LandingView(searchText: $text, onSubmit: {})
    }
}
