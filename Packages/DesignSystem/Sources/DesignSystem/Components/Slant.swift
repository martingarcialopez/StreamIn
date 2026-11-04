import SwiftUI

/// Leans a view right (negative amounts lean it left) about its vertical
/// centre, by `amount` points across per point up. Layout is unchanged.
struct Slant: GeometryEffect {
    let amount: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            a: 1, b: 0, c: -amount, d: 1, tx: amount * size.height / 2, ty: 0
        ))
    }
}
