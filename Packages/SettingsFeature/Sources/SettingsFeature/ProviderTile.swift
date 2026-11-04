//
//  ProviderTile.swift
//  SettingsFeature
//
//  One service in the picker's grid: its app-icon logo with the name under
//  it. A picked one gets an accent ring and a check badge.
//

import SwiftUI
import Domain
import DesignSystem

struct ProviderTile: View {
    let provider: WatchProvider
    let isSelected: Bool
    let imageURLBuilder: ImageURLBuilder
    let toggle: () -> Void

    @ScaledMetric(relativeTo: .body) private var logoSize: CGFloat = LogoSize.tile
    @ScaledMetric(relativeTo: .body) private var ringGap: CGFloat = Spacing.tight

    var body: some View {
        Button(action: toggle) {
            VStack(spacing: Spacing.default) {
                ProviderLogo(
                    url: provider.logoPath.flatMap {
                        imageURLBuilder.url(for: $0, size: .providerLogo)
                    },
                    providerName: provider.name,
                    size: logoSize,
                    cornerRadius: Radius.tile
                )
                // The gap is always there, so picking doesn't shift the grid.
                .padding(ringGap)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Radius.tile + ringGap, style: .continuous)
                            .strokeBorder(AppPalette.accent, lineWidth: 2.5)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        SelectedBadge()
                    }
                }

                Text(provider.name)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .modifier(TileNameLines())
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(provider.name)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Two lines, kept even when one is enough, so the tiles in a row line up.
/// At accessibility text sizes a long name ("Amazon Prime Video with Ads")
/// needs more, so it wraps as far as it must.
private struct TileNameLines: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            content.fixedSize(horizontal: false, vertical: true)
        } else {
            content.lineLimit(2, reservesSpace: true)
        }
    }
}

/// A filled check on the ring's corner, cut out of the page so it reads on
/// any logo.
private struct SelectedBadge: View {
    var body: some View {
        Image(systemName: Symbol.checkmarkCircleFill)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, AppPalette.accent)
            .font(.body.bold())
            .background(AppPalette.background, in: .circle)
            .offset(x: Spacing.tight, y: -Spacing.tight)
    }
}

#Preview {
    HStack(alignment: .top) {
        ProviderTile(
            provider: WatchProvider(id: ProviderID(8), name: "Netflix", logoPath: nil, priority: 1),
            isSelected: true,
            imageURLBuilder: PreviewImageURLBuilder(),
            toggle: {}
        )
        ProviderTile(
            provider: WatchProvider(id: ProviderID(1773), name: "SkyShowtime", logoPath: nil, priority: 2),
            isSelected: false,
            imageURLBuilder: PreviewImageURLBuilder(),
            toggle: {}
        )
        ProviderTile(
            provider: WatchProvider(id: ProviderID(149), name: "Movistar Plus+ Ficción Total", logoPath: nil, priority: 3),
            isSelected: false,
            imageURLBuilder: PreviewImageURLBuilder(),
            toggle: {}
        )
    }
    .padding()
    .cinemaBackground()
    .preferredColorScheme(.dark)
}

private struct PreviewImageURLBuilder: ImageURLBuilder {
    func url(for path: ImagePath, size: ImageSize) -> URL? { nil }
}
