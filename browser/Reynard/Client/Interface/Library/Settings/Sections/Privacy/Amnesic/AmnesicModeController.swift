//
//  AmnesicModeController.swift
//  Reynard
//
//  Created by Minh Ton on 16/9/26.
//

import Foundation
import GeckoView

/// Amnesic Mode reuses the exact same no-disk-persistence path this app
/// already has for private tabs (GeckoSession.isPrivateMode, which the
/// engine itself treats as Private Browsing: in-memory cookies/cache, and
/// which every persistence-gating check in this app - history, favicons,
/// visited-link status, site permissions - already keys off) rather than
/// re-implementing that gating per store. See SessionManager.createSession
/// and TabManagerImpl.persistState for where it's applied.
enum AmnesicModeController {
    static func setEnabled(_ enabled: Bool) {
        Prefs.AmnesicPreferences.enabled = enabled
        guard enabled else { return }
        wipePersistedData()
    }
    
    /// Clears whatever browsing data already made it to disk before the
    /// toggle was switched on. Doesn't close open tabs - a tab whose
    /// session was created before this was enabled keeps whatever mode it
    /// started in until it's closed and reopened (Gecko's isPrivateMode is
    /// fixed at session creation, not changeable in place); see the
    /// settings screen's footer for the user-facing version of this.
    private static func wipePersistedData() {
        HistoryStore.shared.clearVisits(since: nil)
        FaviconStore.shared.clearCache()
        
        // Sync the on-disk tab list to "nothing" - persistTabs is a
        // full-replace sync, so passing empty arrays clears both the
        // regular and private rows already written (private tabs already
        // persist their URL/title for tab-restore purposes even though
        // they skip history/cookies).
        TabManagementStore.shared.persistTabs(
            regularTabs: [],
            privateTabs: [],
            selectedRegularTabID: nil,
            selectedPrivateTabID: nil,
            selectedTabMode: .regular
        )
        
        Task {
            try? await GeckoStorageController.clearHistory(since: nil)
            try? await GeckoStorageController.clearData(
                flags: GeckoStorageClearFlags.cookies | GeckoStorageClearFlags.authSessions
            )
            try? await GeckoStorageController.clearData(flags: GeckoStorageClearFlags.domStorages)
            try? await GeckoStorageController.clearData(flags: GeckoStorageClearFlags.allCaches)
        }
    }
}
