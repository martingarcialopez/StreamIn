import SwiftUI

/// A list row's answer to "where can I watch it?": up to three small logos
/// and "+N" (abroad ones behind `AbroadMark`), a caption, or a spinner while
/// it loads. Holds the logos' height in every state, so rows don't jump as
/// availability lands. Search results and the Watchlist share it.
public struct ProviderLine<Provider: Identifiable>: View {
    public let content: ProviderLineContent<Provider>
    public let logoURL: @MainActor (Provider) -> URL?
    public let name: @MainActor (Provider) -> String

    @ScaledMetric(relativeTo: .caption) private var logoSize: CGFloat = LogoSize.small

    public init(
        _ content: ProviderLineContent<Provider>,
        logoURL: @escaping @MainActor (Provider) -> URL?,
        name: @escaping @MainActor (Provider) -> String
    ) {
        self.content = content
        self.logoURL = logoURL
        self.name = name
    }

    public var body: some View {
        Group {
            switch content {
            case .loading:
                ProgressView()
                    .controlSize(.mini)
            case .logos(let providers, let abroad):
                HStack(spacing: Spacing.default) {
                    if abroad {
                        AbroadMark(size: logoSize)
                    }
                    ProviderLogoStrip(providers, maxLogos: 3, logoSize: logoSize, logoURL: logoURL, name: name)
                }
            case .caption(let text):
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: logoSize, alignment: .leading)
        .animation(.smooth, value: content)
    }
}

#Preview("States") {
    struct Sample: Identifiable {
        let id: Int
    }
    let line = { (content: ProviderLineContent<Sample>) in
        ProviderLine(content, logoURL: { _ in nil }, name: { "Provider \($0.id)" })
    }
    return VStack(alignment: .leading, spacing: Spacing.comfortable) {
        line(.loading)
        line(.logos((1...2).map(Sample.init), abroad: false))
        line(.logos((1...5).map(Sample.init), abroad: false))
        line(.logos((1...2).map(Sample.init), abroad: true))
        line(.caption("Not on your services"))
    }
    .padding()
    .cinemaBackground()
}
