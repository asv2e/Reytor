//
//  FingerprintingProtectionPolicyController.swift
//  Reynard
//
//  Created by Minh Ton on 13/9/26.
//

import GeckoView

enum FingerprintingProtectionPolicyController {
    /// Applies Tor Browser-style "Resist Fingerprinting" protections.
    ///
    /// When enabled, this spoofs several commonly-fingerprinted signals (screen
    /// dimensions via letterboxing, timezone, locale, hardware concurrency, etc.)
    /// so that Reynard's users are harder to distinguish from one another, the
    /// same strategy used by Tor Browser to blend users into a common anonymity
    /// set instead of just blocking known trackers.
    static func applyFingerprintingProtection() {
        let preferences = Prefs.FingerprintingProtectionPreferences.self
        let isEnabled = preferences.enabled
        
        GeckoRuntime.setDefaultPrefs([
            // Core resist-fingerprinting mode: spoofs timezone (UTC), locale,
            // hardware concurrency, canvas/audio/font enumeration, and more.
            "privacy.resistFingerprinting": isEnabled,
            
            // Rounds the reported window/content dimensions to a fixed set of
            // "letterboxed" buckets instead of the device's real size, exactly
            // like Tor Browser's window resizing protection.
            "privacy.resistFingerprinting.letterboxing": isEnabled && preferences.letterboxingEnabled,
            
            // WebRTC can leak a device's local/public IP addresses even through
            // a proxy or VPN, so Tor Browser disables it outright.
            "media.peerconnection.enabled": !(isEnabled && preferences.blocksWebRTC),
            
            // Reports a single, generic "en-US" language instead of the user's
            // real locale preferences, matching Tor Browser's default of not
            // revealing locale via Accept-Language.
            "privacy.spoof_english": isEnabled && preferences.spoofsAcceptLanguage ? 2 : 0,
        ])
    }
}
