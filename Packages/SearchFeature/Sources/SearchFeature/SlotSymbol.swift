import Foundation

/// One symbol on a landing-page reel: a movie poster, a service's logo or a
/// country's flag, or a stand-in glyph when the real thing isn't available.
struct SlotSymbol: Hashable, Sendable {
    enum Face: Hashable, Sendable {
        case poster(URL?)
        case logo(URL?)
        case flag(String)
        /// An SF Symbol, for a reel whose data couldn't be loaded.
        case glyph(String)
    }

    let face: Face
    /// What VoiceOver says when this symbol lands: a title, a service, a country.
    let name: String
}
