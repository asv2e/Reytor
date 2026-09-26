//
//  SecurityLevel.swift
//  Reynard
//
//  Created by Minh Ton on 19/9/26.
//

import Foundation

/// Mirrors Tor Browser's own Security Level concept, but as a preset over
/// this app's existing independent toggles rather than a single built-in
/// engine mechanism. One real difference worth knowing: Tor Browser's
/// "Safer" only disables JavaScript on non-HTTPS sites (site-by-site,
/// based on connection security); this app's JavaScript blocking is a
/// simpler global default with per-site exceptions (see
/// JavaScriptPreferences/JavaScriptSettingManager), so "Safer" and
/// "Safest" here both block JavaScript by default everywhere - the
/// distinction between them is Website Isolation, not JS scope.
enum SecurityLevel: String, CaseIterable {
    case standard
    case safer
    case safest
    
    var title: String {
        switch self {
        case .standard:
            return NSLocalizedString("Standard", comment: "")
        case .safer:
            return NSLocalizedString("Safer", comment: "")
        case .safest:
            return NSLocalizedString("Safest", comment: "")
        }
    }
    
    var subtitle: String {
        switch self {
        case .standard:
            return NSLocalizedString("All browser features are on. This is the most compatible option.", comment: "")
        case .safer:
            return NSLocalizedString("Blocks JavaScript by default and enables Fingerprinting Protection. Some sites may lose functionality.", comment: "")
        case .safest:
            return NSLocalizedString("Adds Website Isolation on top of Safer. The most restrictive option - many sites will need per-site exceptions to work.", comment: "")
        }
    }
    
    fileprivate var blocksJavaScriptByDefault: Bool {
        self != .standard
    }
    
    fileprivate var enablesFingerprintingProtection: Bool {
        self != .standard
    }
    
    fileprivate var enablesWebsiteIsolation: Bool {
        self == .safest
    }
}

enum SecurityLevelController {
    /// Applies the given level's preset values to the underlying
    /// preferences and re-applies the affected engine policies
    /// immediately (matching how each individual settings screen already
    /// applies its own toggle). Does not touch settings this preset
    /// doesn't model, e.g. HTTPS-Only Mode, Tor, or Anti-XSS - those keep
    /// whatever the person separately set them to.
    static func apply(_ level: SecurityLevel) {
        Prefs.SecurityLevelPreferences.level = level
        
        Prefs.JavaScriptPreferences.blocksByDefault = level.blocksJavaScriptByDefault
        
        Prefs.FingerprintingProtectionPreferences.enabled = level.enablesFingerprintingProtection
        Prefs.FingerprintingProtectionPreferences.letterboxingEnabled = level.enablesFingerprintingProtection
        Prefs.FingerprintingProtectionPreferences.blocksWebRTC = level.enablesFingerprintingProtection
        Prefs.FingerprintingProtectionPreferences.spoofsAcceptLanguage = level.enablesFingerprintingProtection
        FingerprintingProtectionPolicyController.applyFingerprintingProtection()
        
        Prefs.WebsiteIsolationPreferences.enabled = level.enablesWebsiteIsolation
        WebsiteIsolationPolicyController.applyWebsiteIsolation()
    }
    
    /// Whether the currently-stored preference values still match one of
    /// the three presets exactly, vs. having been hand-edited afterward
    /// in the individual JavaScript/Fingerprinting Protection/Website
    /// Isolation screens (in which case none of the three rows should
    /// show as selected).
    static func matchesStoredPreset(_ level: SecurityLevel) -> Bool {
        return Prefs.JavaScriptPreferences.blocksByDefault == level.blocksJavaScriptByDefault
            && Prefs.FingerprintingProtectionPreferences.enabled == level.enablesFingerprintingProtection
            && Prefs.WebsiteIsolationPreferences.enabled == level.enablesWebsiteIsolation
    }
}
