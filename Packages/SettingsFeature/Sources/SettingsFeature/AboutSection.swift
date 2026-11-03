//
//  AboutSection.swift
//  SettingsFeature
//
//  Settings' last section: TMDB's required attribution with their logo,
//  JustWatch's credit, the privacy policy and the app version. Fine print
//  rather than settings: small, centred, gray, on the page itself, with room
//  above it so it never reads as part of the configuration.
//

import SwiftUI
import DesignSystem

struct AboutSection: View {
    var version: AppVersion = .current

    var body: some View {
        // One row per line: a Form row sends a tap anywhere in it to its
        // first button, so links sharing a row would all open the first.
        Section {
            TMDBLogo()
                // Well clear of the last setting, so it never reads as one.
                .padding(.top, Spacing.sectionGap * 3)
                .padding(.bottom, Spacing.tight)
                .modifier(FinePrintRow())
            QuietLink(.settingsAboutTMDB, underlining: "TMDB", destination: AboutLinks.tmdb)
                .modifier(FinePrintRow())
            QuietLink(.settingsAboutJustWatch, underlining: "JustWatch", destination: AboutLinks.justWatch)
                .modifier(FinePrintRow())
            QuietLink(.settingsAboutPrivacy, destination: AboutLinks.privacyPolicy())
                .modifier(FinePrintRow())
            Text(.settingsAboutVersion(version.version, version.build))
                .foregroundStyle(.tertiary)
                .modifier(FinePrintRow())
        }
    }
}

/// A line of fine print on the page: centred, small, no row background,
/// separator or row padding beyond a few points between lines.
private struct FinePrintRow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(
                top: Spacing.tight,
                leading: Spacing.screenPadding,
                bottom: Spacing.tight,
                trailing: Spacing.screenPadding
            ))
    }
}

/// A line of fine print that opens a web page: gray, a step brighter than
/// the version under it, with an underline that says it's a link. The text
/// is the link's name for VoiceOver.
struct QuietLink: View {
    let title: LocalizedStringResource
    /// The words to underline, such as the brand a sentence credits; `nil`
    /// underlines the whole line.
    let underlined: String?
    let destination: URL

    init(_ title: LocalizedStringResource, underlining underlined: String? = nil, destination: URL) {
        self.title = title
        self.underlined = underlined
        self.destination = destination
    }

    var body: some View {
        Link(destination: destination) {
            Text(Self.text(title, underlining: underlined))
        }
        .tint(.secondary)
    }

    /// Brand names read the same in every language, so they're found in the
    /// translated sentence; its first mention is underlined.
    static func text(_ title: LocalizedStringResource, underlining underlined: String?) -> AttributedString {
        var text = AttributedString(localized: title)
        if let underlined, let range = text.range(of: underlined) {
            text[range].underlineStyle = .single
        } else {
            text.underlineStyle = .single
        }
        return text
    }
}

/// TMDB's terms: their logo, unmodified and less prominent than StreamIn's
/// own branding.
private struct TMDBLogo: View {
    /// Grows with Dynamic Type, but stays a small mark.
    @ScaledMetric(relativeTo: .caption2) private var height: CGFloat = 10

    var body: some View {
        Image(.tmdbLogo)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            // The sentence under it names TMDB already.
            .accessibilityHidden(true)
    }
}

#Preview {
    Form {
        Section {
            Text(verbatim: "Streaming services")
        }
        .cinemaRow()
        AboutSection(version: AppVersion(version: "1.0.0", build: "1"))
    }
    .environment(\.defaultMinListRowHeight, 0)
    .cinemaBackground()
}
