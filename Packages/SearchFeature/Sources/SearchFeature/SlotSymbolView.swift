import SwiftUI
import DesignSystem

/// One cell of a reel: the same square Liquid Glass tile for every symbol,
/// sized from the reel's row height, so all three reels carry the same
/// weight. Posters and logos fill their tile inside a thin glass rim; flags
/// and glyphs sit large in its centre.
struct SlotSymbolView: View {
    let symbol: SlotSymbol
    let rowHeight: CGFloat

    /// The tile's side, as a share of the row height.
    static let tileSide: CGFloat = 0.78
    /// The glass rim showing around a poster or a logo (and the lever's knob).
    static let rim: CGFloat = 3

    var body: some View {
        let side = rowHeight * Self.tileSide
        let corner = Radius.card
        let inner = side - Self.rim * 2
        Group {
            switch symbol.face {
            case .poster(let url):
                RemoteImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.clear
                }
                .frame(width: inner, height: inner)
                .clipShape(.rect(cornerRadius: corner - Self.rim))
            case .logo(let url):
                ProviderLogo(url: url, providerName: symbol.name, size: inner, cornerRadius: corner - Self.rim)
            case .flag(let flag):
                // Sized from the row height, which already follows Dynamic Type.
                Text(verbatim: flag)
                    .font(.system(size: side * 0.62))
            case .glyph(let name):
                Image(systemName: name)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(AppPalette.accent)
                    .frame(width: side * 0.5, height: side * 0.5)
            }
        }
        .frame(width: side, height: side)
        .glassEffect(.regular, in: .rect(cornerRadius: corner))
    }
}
