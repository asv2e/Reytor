//
//  WebsiteIsolationPolicyController.swift
//  Reynard
//
//  Created by Minh Ton on 16/9/26.
//

import GeckoView

enum WebsiteIsolationPolicyController {
    static func applyWebsiteIsolation() {
        let isEnabled = Prefs.WebsiteIsolationPreferences.enabled
        
        GeckoRuntime.setDefaultPrefs([
            // First-Party Isolation: keys cookies, cache, localStorage/
            // IndexedDB, service workers, permissions, blob URLs, HSTS/HPKP
            // state, connection pooling and more to the top-level site
            // being visited, so two different sites can't correlate a
            // visitor through any of that shared state - the mechanism Tor
            // Browser itself shipped as "Website Isolation" before Firefox
            // grew its own gentler default (Total Cookie Protection, which
            // this app already applies via Tracking Protection's
            // network.cookie.cookieBehavior=5 and only partitions cookies
            // and a subset of storage). This also blocks cross-first-party
            // window.opener access.
            "privacy.firstparty.isolate": isEnabled,
            "privacy.firstparty.isolate.restrict_opener_access": isEnabled,
            
            // Network State Partitioning: keys the HTTP cache, image
            // cache, and connection/TLS-session pooling to the top-level
            // site too, closing a side channel FPI's storage isolation
            // alone doesn't cover (a shared cache/connection can otherwise
            // reveal whether a visitor loaded a given resource on another
            // site).
            "privacy.partition.network_state": isEnabled,
            "privacy.partition.network_state.ocsp_cache": isEnabled,
        ])
    }
}
