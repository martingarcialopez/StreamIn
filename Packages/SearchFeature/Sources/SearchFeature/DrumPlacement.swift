import CoreGraphics
import Foundation

/// Where a symbol `rowsFromLine` rows from the winning line (negative: above
/// it) appears on its reel's drum, seen from the front.
///
/// Symbols sit `radiansPerRow` apart around a cylinder whose circumference
/// spaces them one row apart. Turning away from the line, a symbol's offset is
/// the cylinder's projection of its angle, so the symbols bunch up, squash as
/// they turn edge-on (`flattening`), fade, and vanish round the back. Only the
/// vertical turns: nothing narrows or leans sideways, so the machine stays a
/// plain rectangle.
struct DrumPlacement: Equatable, Sendable {
    static let radiansPerRow = Double.pi / 4

    /// Vertical offset from the winning line.
    let offset: CGFloat
    /// Vertical squash as the symbol turns edge-on.
    let flattening: CGFloat
    let opacity: Double

    init(rowsFromLine: Double, rowHeight: CGFloat) {
        let angle = rowsFromLine * Self.radiansPerRow
        guard abs(angle) < .pi / 2 else {
            offset = 0
            flattening = 0
            opacity = 0
            return
        }
        let radius = rowHeight / Self.radiansPerRow
        offset = radius * CGFloat(sin(angle))
        flattening = CGFloat(cos(angle))
        opacity = cos(angle) * cos(angle)
    }
}
