//
//  AppAppearanceController.swift
//  Reynard
//
//  Created by Minh Ton on 22/6/26.
//

import UIKit

enum AppAppearanceController {
    static let alternateAppIconName = "AppIconAlt"

    static func apply(_ appearance: AppAppearance) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { window in
                window.overrideUserInterfaceStyle = userInterfaceStyle(for: appearance)
            }
    }

    static func applySelectedAppIcon() {
        guard UIApplication.shared.supportsAlternateIcons else {
            return
        }
        let useAlternate = Prefs.AppearanceSettings.useAlternateAppIcon
        setAppIcon(useAlternate)
    }

    static func setAppIcon(_ useAlternate: Bool) {
        guard UIApplication.shared.supportsAlternateIcons else {
            return
        }

        let iconName: String? = useAlternate ? alternateAppIconName : nil
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error {
                print("Failed to set alternate app icon: \(error.localizedDescription)")
            }
        }
    }

    static func userInterfaceStyle(for appearance: AppAppearance) -> UIUserInterfaceStyle {
        switch appearance {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
