//
//  AntiXSSFilter.swift
//  Reynard
//
//  Created by Minh Ton on 13/9/26.
//

import Foundation

/// Best-effort, heuristic protection against reflected cross-site
/// scripting: flags top-level navigations whose URL appears to carry a
/// script-injection payload in its query string or fragment - the same
/// class of attack the legacy Chrome/WebKit "XSS Auditor" targeted before
/// both browsers removed it as too easy to bypass and occasionally a
/// security liability itself (it could leak whether a pattern matched).
///
/// To avoid repeating that mistake, this filter deliberately does *not*
/// try to sanitize or rewrite page content - it only ever blocks
/// navigation and asks the person before proceeding. That keeps the
/// failure mode simple (an unnecessary confirmation prompt) instead of a
/// new content-injection surface.
///
/// This is explicitly NOT a substitute for a site's own input handling
/// and CSP - it's a coarse, client-side extra layer, off by default for
/// anyone who finds it noisy.
actor AntiXSSFilter {
    static let shared = AntiXSSFilter()
    
    private let patterns: [NSRegularExpression]
    private var bypassedURLs: Set<String> = []
    private var pendingPrompts: [String: Task<Bool, Never>] = [:]
    
    private init() {
        let rawPatterns = [
            "<\\s*script\\b",
            "<\\s*/\\s*script\\s*>",
            "javascript\\s*:",
            // An actual HTML tag carrying an inline event-handler
            // attribute (e.g. `<img onerror=`) - anchored to a real "<tag"
            // opening rather than a bare "on\\w+=" anywhere, since the
            // latter false-positives on ordinary query values like
            // "expiresOnDate=".
            "<[a-zA-Z][^>]*\\son\\w+\\s*=",
            "document\\s*\\.\\s*cookie",
            "document\\s*\\.\\s*write\\s*\\(",
            "\\beval\\s*\\(",
            "String\\s*\\.\\s*fromCharCode\\s*\\(",
            "<\\s*iframe\\b[^>]*\\bsrcdoc\\s*=",
        ]
        self.patterns = rawPatterns.compactMap {
            try? NSRegularExpression(pattern: $0, options: [.caseInsensitive])
        }
    }
    
    /// Pure pattern check - safe to call off-actor since it touches no
    /// mutable state, so callers can filter obviously-clean URLs without
    /// an actor hop before deciding whether to ask for a decision at all.
    nonisolated func isSuspicious(_ urlString: String) -> Bool {
        guard let components = URLComponents(string: urlString) else {
            return false
        }
        
        // Only the query and fragment are inspected - the parts of a URL
        // that commonly carry attacker-controlled, server-reflected
        // content. Path segments are left alone; flagging those has a
        // much higher false-positive rate for ordinary apps/APIs that
        // route on path components.
        var haystacks: [String] = []
        if let query = components.query {
            haystacks.append(query)
            if let decoded = query.removingPercentEncoding, decoded != query {
                haystacks.append(decoded)
            }
        }
        if let fragment = components.fragment {
            haystacks.append(fragment)
            if let decoded = fragment.removingPercentEncoding, decoded != fragment {
                haystacks.append(decoded)
            }
        }
        
        for haystack in haystacks {
            let range = NSRange(haystack.startIndex..., in: haystack)
            if patterns.contains(where: { $0.firstMatch(in: haystack, range: range) != nil }) {
                return true
            }
        }
        return false
    }
    
    /// Resolves to true if the navigation should proceed: either the URL
    /// was already approved this run, or the person just approved it via
    /// the confirmation alert. Concurrent calls for the same exact URL
    /// (onLoadRequest and onPreNavigation can both fire for one
    /// navigation) share a single in-flight prompt instead of asking
    /// twice.
    func confirmProceed(for urlString: String) async -> Bool {
        if bypassedURLs.contains(urlString) {
            return true
        }
        
        if let pending = pendingPrompts[urlString] {
            return await pending.value
        }
        
        let task = Task<Bool, Never> {
            await Self.presentConfirmation(for: urlString)
        }
        pendingPrompts[urlString] = task
        let approved = await task.value
        pendingPrompts[urlString] = nil
        if approved {
            bypassedURLs.insert(urlString)
        }
        return approved
    }
    
    @MainActor
    private static func presentConfirmation(for urlString: String) async -> Bool {
        await withCheckedContinuation { continuation in
            var didResume = false
            let resume: (Bool) -> Void = { value in
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: value)
            }
            
            AlertPresenter.show(
                title: NSLocalizedString("Potentially Unsafe Link", comment: ""),
                message: String(
                    format: NSLocalizedString(
                        "This link contains a pattern often used in cross-site scripting (XSS) attacks:\n\n%@\n\nThis is a heuristic check and can be wrong in either direction. Continue anyway?",
                        comment: ""
                    ),
                    urlString
                ),
                buttons: [
                    AlertPresenter.Button(
                        title: NSLocalizedString("Cancel", comment: ""),
                        style: .cancel
                    ) {
                        resume(false)
                    },
                    AlertPresenter.Button(
                        title: NSLocalizedString("Continue Anyway", comment: ""),
                        style: .destructive
                    ) {
                        resume(true)
                    },
                ]
            )
        }
    }
}
