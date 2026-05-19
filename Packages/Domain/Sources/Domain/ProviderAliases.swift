//
//  ProviderAliases.swift
//  Domain
//
//  TMDB sometimes tags the same user-facing streaming brand with multiple
//  `provider_id`s — different regions, different subscription tiers, or
//  historical numbering quirks. Without aliasing, the app treats those as
//  distinct services: a Prime Video subscriber sees a film "missing" in
//  Nicaragua even though TMDB does list it there, just under a different id.
//
//  ## How we decide what to alias
//
//  ALIAS — same end-user subscription gives access to all variants:
//  - Tier variants of one paid subscription ("with Ads", "Basic", "Premium",
//    "Plus"). Holding any tier means the same base content library.
//  - Spelling or punctuation duplicates ("Disney+" vs "Disney Plus").
//  - Regional rebrands of the same service ("Starz" vs "Starzplay" vs
//    "Lionsgate Play").
//  - Free ad-supported sibling of a paid service when the paid subscriber
//    can also watch the free-tier content (e.g. "Prime Video Free with Ads").
//
//  DO NOT alias — different products, different commerce models:
//  - Channel add-ons ("X Amazon Channel", "Y Apple TV Channel"). These are
//    third-party services that use Amazon/Apple as a billing intermediary —
//    paid separately, NOT included in the host subscription.
//  - Storefront vs subscription (Amazon Video id 10 rent/buy vs Prime Video
//    id 9 sub; Apple TV Store id 2 vs Apple TV+ id 350).
//  - Linear TV channel vs streaming service (AMC id 80 vs AMC+ id 526;
//    ESPN id 1718 vs ESPN+ id 1768).
//  - Different products under one corporate umbrella (Sky Go vs SkyShowtime
//    vs Now TV — actually distinct paid services).
//  - Companion apps for cable bundles (DisneyNOW id 508 is the ABC/Disney
//    Channel TV-Everywhere app, not Disney+ id 122).
//
//  Discovered case-by-case from inspecting `/watch/providers/movie` output.
//  When a new alias surfaces during testing, append the group below.
//  Canonical id is auto-derived as the lowest in the group.
//

public enum ProviderAliases {

    /// One group per user-facing brand. Order within a group doesn't matter
    /// for membership but the canonical id is derived by `min(...)`.
    private static let groups: [Set<ProviderID>] = [
        // ── Netflix ────────────────────────────────────────────────────────
        // 8:    Netflix
        // 175:  Netflix Kids (built-in profile mode, same subscription)
        // 1796: Netflix Standard with Ads (ad-supported tier of the same sub)
        [ProviderID(8), ProviderID(175), ProviderID(1796)],

        // ── Amazon Prime Video ─────────────────────────────────────────────
        // 9:    Amazon Prime Video (canonical global)
        // 119:  Amazon Prime Video (regional variant id, mostly Latin America)
        // 613:  Amazon Prime Video Free with Ads (free tier — Prime
        //       subscribers also have access to this content via the same app)
        // 2100: Amazon Prime Video with Ads (default-ads tier post-2024)
        // NOT aliased: Amazon Video id 10 (rent/buy storefront), Amazon MX
        // Player id 1898 (separate Indian service), and the ~200 "X Amazon
        // Channel" entries (third-party add-ons paid separately on top of
        // Prime — MUBI, Crave, Starz, Paramount+, etc.).
        [ProviderID(9), ProviderID(119), ProviderID(613), ProviderID(2100)],

        // ── Disney+ ────────────────────────────────────────────────────────
        // 122: "Disney+"
        // 337: "Disney Plus" (spelling variant of the same service)
        // NOT aliased: DisneyNOW id 508 is the ABC/Disney Channel live-TV
        // companion app, a different product.
        [ProviderID(122), ProviderID(337)],

        // ── Paramount+ (subscription tiers) ────────────────────────────────
        // 531:  Paramount Plus (base)
        // 2303: Paramount Plus Premium (ad-free + 4K + downloads tier)
        // 2304: Paramount Plus Basic with Ads
        // 2616: Paramount Plus Essential
        // All four are tiers of the same Paramount+ subscription — content
        // library overlaps even if features (ads, 4K) differ.
        // NOT aliased: Paramount Pictures id 187 (film studio, not a service).
        [ProviderID(531), ProviderID(2303), ProviderID(2304), ProviderID(2616)],

        // ── Peacock ────────────────────────────────────────────────────────
        // 386: Peacock Premium (with ads)
        // 387: Peacock Premium Plus (ad-free)
        // Both tiers share the same content library; only the ad treatment
        // differs.
        [ProviderID(386), ProviderID(387)],

        // ── Discovery+ ─────────────────────────────────────────────────────
        // 510, 520, 524: all three labeled "Discovery+" (or "Discovery +"
        // with a space) in TMDB. Data-quality artefacts for the same
        // Warner-Bros.-owned service.
        [ProviderID(510), ProviderID(520), ProviderID(524)],

        // ── Pluto TV ───────────────────────────────────────────────────────
        // 300:  Pluto TV (on-demand)
        // 1965: Pluto TV Live (live linear streams within the same app)
        // Same free product. Films rarely surface as "Live" only, but TMDB
        // does tag some titles this way.
        [ProviderID(300), ProviderID(1965)],

        // ── Starz / Starzplay / Lionsgate Play ────────────────────────────
        // Lionsgate-owned premium streaming under regional brand names:
        // 43:  Starz (US)
        // 561: Lionsgate Play (India and select markets)
        // 630: STARZPLAY (international rebrand outside the US)
        // A user thinking "I have Starz" expects to see every region where
        // the film is available under any of these brands. Per-region account
        // portability varies in real life; the brand match is what the UX
        // promises.
        // NOT aliased: the Starz/Lionsgate Play "Amazon Channel" and "Apple
        // TV Channel" ids — those are add-ons paid through Amazon/Apple.
        [ProviderID(43), ProviderID(561), ProviderID(630)],

        // ── Canal+ ─────────────────────────────────────────────────────────
        // 381:  "Canal+"
        // 2101: "CANAL+" (uppercase spelling variant of the same service)
        // NOT aliased: Canal VOD id 58 (Canal+'s rent/buy storefront);
        // Premiery Canal+ id 2102 (Polish regional brand — kept separate
        // because cross-region account access is unclear).
        [ProviderID(381), ProviderID(2101)]
    ]

    /// Returns the canonical id for any id in an aliased group, or the id
    /// itself if it isn't aliased. Use this when partitioning, storing in
    /// `Preferences`, or matching: we never want two ids that represent the
    /// same brand to live independently in app state.
    public static func canonical(_ id: ProviderID) -> ProviderID {
        guard let group = groups.first(where: { $0.contains(id) }),
              let canonical = group.min(by: { $0.rawValue < $1.rawValue })
        else { return id }
        return canonical
    }

    /// Every id that belongs to the same brand as `id`. Singleton for non-
    /// aliased ids. Used by the Details filter to expand the user's
    /// subscription set ({9}) into every TMDB variant ({9, 119, 613, 2100})
    /// so region listings under any variant are matched.
    public static func aliasGroup(of id: ProviderID) -> Set<ProviderID> {
        groups.first(where: { $0.contains(id) }) ?? [id]
    }
}
