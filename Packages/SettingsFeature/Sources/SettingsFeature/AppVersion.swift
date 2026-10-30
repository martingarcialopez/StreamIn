//
//  AppVersion.swift
//  SettingsFeature
//
//  The marketing version and build number shown in Settings → About,
//  read from the app's Info.plist.
//

import Foundation

struct AppVersion: Equatable {
    let version: String
    let build: String

    init(version: String, build: String) {
        self.version = version
        self.build = build
    }

    /// A missing key shows as "–" rather than hiding the line.
    init(infoDictionary: [String: Any]?) {
        self.version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        self.build = infoDictionary?["CFBundleVersion"] as? String ?? "–"
    }

    static var current: AppVersion {
        AppVersion(infoDictionary: Bundle.main.infoDictionary)
    }
}
