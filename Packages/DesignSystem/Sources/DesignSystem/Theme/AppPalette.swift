import SwiftUI

public enum AppPalette {
    /// A warm near-black. The app is always dark; screens sit on it through
    /// `cinemaBackground()`. The launch screen paints the same colour from
    /// the app's `LaunchBackground` colour set: keep the two in sync.
    public static let background = Color("background", bundle: .module)
    public static let secondaryBackground = Color("secondaryBackground", bundle: .module)
    public static let separator = Color("separator", bundle: .module)
    public static let accent = Color("accent", bundle: .module)
    /// Good news, such as "you can watch this now".
    public static let positive = Color.green
    /// A gentle "not available", lilac rather than an alarming red.
    public static let unavailable = Color.purple
}
