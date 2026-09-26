//
//  SessionSettingsManager.swift
//  Reynard
//
//  Created by Minh Ton on 28/6/26.
//

import Foundation
import GeckoView

final class SessionSettingsManager {
    let websiteMode: WebsiteModeSettingManager
    let pageZoom: PageZoomSettingManager
    let language: LanguageSettingManager
    let javaScript: JavaScriptSettingManager
    
    init(
        websiteMode: WebsiteModeSettingManager = WebsiteModeSettingManager(),
        pageZoom: PageZoomSettingManager = PageZoomSettingManager(),
        language: LanguageSettingManager = LanguageSettingManager(),
        javaScript: JavaScriptSettingManager = JavaScriptSettingManager()
    ) {
        self.websiteMode = websiteMode
        self.pageZoom = pageZoom
        self.language = language
        self.javaScript = javaScript
    }
    
    func settings(for url: String?, tabID: UUID?) -> GeckoSessionSettings {
        let languageSetting = language.setting()
        guard let url else {
            return GeckoSessionSettings(
                websiteMode: .mobile,
                pageZoom: .default,
                language: languageSetting,
                allowJavascript: !Prefs.JavaScriptPreferences.blocksByDefault
            )
        }
        
        return GeckoSessionSettings(
            websiteMode: websiteMode.setting(for: url, tabID: tabID),
            pageZoom: pageZoom.setting(for: url),
            language: languageSetting,
            allowJavascript: javaScript.allowsJavaScript(for: url)
        )
    }
    
    func needsUpdate(
        for session: GeckoSession,
        currentURL: String?,
        requestedURL: String,
        tabID: UUID
    ) -> Bool {
        let requestedSettings = settings(for: requestedURL, tabID: tabID)
        if session.settings.language != requestedSettings.language {
            return true
        }
        
        guard let currentURL,
              let currentHost = DomainMatcher.host(from: currentURL),
              let requestedHost = DomainMatcher.host(from: requestedURL),
              currentHost != requestedHost else {
            return false
        }
        return session.settings != requestedSettings
    }
}
