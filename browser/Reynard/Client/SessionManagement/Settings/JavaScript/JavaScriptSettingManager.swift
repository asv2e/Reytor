//
//  JavaScriptSettingManager.swift
//  Reynard
//
//  Created by Minh Ton on 13/9/26.
//

import Foundation
import GeckoView

/// Resolves whether JavaScript should run for a given URL: a per-site
/// override in SiteSettingsStore always wins; otherwise falls back to the
/// global Prefs.JavaScriptPreferences.blocksByDefault default. This is the
/// NoScript-style allow/block-by-default model.
final class JavaScriptSettingManager {
    private let siteSettingsStore: SiteSettingsStore
    
    init(siteSettingsStore: SiteSettingsStore = .shared) {
        self.siteSettingsStore = siteSettingsStore
    }
    
    func allowsJavaScript(for url: String) -> Bool {
        guard let url = URL(string: url) else {
            return !Prefs.JavaScriptPreferences.blocksByDefault
        }
        
        if let blocked = siteSettingsStore.javascriptBlocked(for: url) {
            return !blocked
        }
        
        return !Prefs.JavaScriptPreferences.blocksByDefault
    }
    
    @discardableResult
    func setBlocked(_ blocked: Bool?, for url: String) -> Bool {
        guard let url = URL(string: url) else {
            return false
        }
        
        return siteSettingsStore.setJavaScriptBlocked(blocked, for: url)
    }
}
