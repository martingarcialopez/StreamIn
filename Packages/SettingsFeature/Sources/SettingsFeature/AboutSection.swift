//
//  AboutSection.swift
//  SettingsFeature
//
//  Settings' last section: TMDB's required attribution with their logo,
//  JustWatch's credit, the privacy policy and the app version.
//

import SwiftUI
import DesignSystem

struct AboutSection: View {
    var version: AppVersion = .current

    var body: some View {
        Section {
            // TMDB's terms: their logo, unmodified and less prominent than
            // StreamIn's own branding, beside the attribution sentence.
            VStack(alignment: .leading, spacing: Spacing.default) {
                TMDBLogo()
                ExternalLink(.settingsAboutTMDB, destination: AboutLinks.tmdb)
            }
            ExternalLink(.settingsAboutJustWatch, destination: AboutLinks.justWatch)
            ExternalLink(.settingsAboutPrivacy, destination: AboutLinks.privacyPolicy())
            Text(.settingsAboutVersion(version.version, version.build))
                .foregroundStyle(.secondary)
        } header: {
            Text(.settingsAboutHeader)
        }
    }
}

/// A row that opens a web page: the text is the link's name for VoiceOver,
/// and the trailing arrow says it leaves the app.
private struct ExternalLink: View {
    let title: LocalizedStringResource
    let destination: URL

    init(_ title: LocalizedStringResource, destination: URL) {
        self.title = title
        self.destination = destination
    }

    var body: some View {
        Link(destination: destination) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.comfortable) {
                Text(title)
                Spacer(minLength: 0)
                Image(systemName: Symbol.arrowUpRight)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        // Plain text: three sentences in the accent color would outshout
        // the rest of Settings. The arrow marks them as links.
        .tint(.primary)
    }
}

private struct TMDBLogo: View {
    /// Grows with Dynamic Type, but stays a small mark.
    @ScaledMetric(relativeTo: .footnote) private var height: CGFloat = 14

    var body: some View {
        Image("tmdbLogo", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            // The sentence next to it names TMDB already.
            .accessibilityHidden(true)
    }
}

#Preview {
    Form {
        AboutSection(version: AppVersion(version: "1.0.0", build: "1"))
            .cinemaRow()
    }
    .cinemaBackground()
    .preferredColorScheme(.dark)
}
