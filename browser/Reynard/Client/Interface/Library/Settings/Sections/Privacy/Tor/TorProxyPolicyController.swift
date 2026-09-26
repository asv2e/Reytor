//
//  TorProxyPolicyController.swift
//  Reynard
//
//  Created by Minh Ton on 13/9/26.
//

import GeckoView

enum TorProxyPolicyController {
    // Nothing listens here, so pointing the proxy at it makes every
    // request fail fast instead of silently going out directly. Used
    // while Tor is enabled but not yet connected (or has errored) and
    // Prefs.TorPreferences.blocksNetworkUntilConnected is on.
    private static let unreachablePort: UInt16 = 1
    
    static func applyDisabled() {
        GeckoRuntime.setDefaultPrefs([
            "network.proxy.type": 0,
        ])
        
        // Restore whatever DoH setting the user actually has configured -
        // applyProxy() below overrides it with DoH forced off while Tor is
        // active, and that override shouldn't stick around after Tor is
        // turned off.
        DNSOverHTTPSPolicyController.applyDNSOverHTTPS()
    }
    
    static func applyConnecting(socksPort: UInt16, blocksNetworkUntilConnected: Bool) {
        applyProxy(port: blocksNetworkUntilConnected ? unreachablePort : socksPort)
    }
    
    static func applyConnected(socksPort: UInt16) {
        applyProxy(port: socksPort)
    }
    
    private static func applyProxy(port: UInt16) {
        GeckoRuntime.setDefaultPrefs([
            // Manual proxy configuration, SOCKS5, pointed at our embedded
            // Arti client's local forwarder.
            "network.proxy.type": 1,
            "network.proxy.socks": "127.0.0.1",
            "network.proxy.socks_port": Int(port),
            "network.proxy.socks_version": 5,
            
            // Resolve hostnames through Tor instead of the local/ISP
            // resolver - the single most important anti-leak setting here.
            "network.proxy.socks_remote_dns": true,
            
            // Never silently fall back to a direct connection if the SOCKS
            // proxy is unreachable or refuses a connection.
            "network.proxy.failover_direct": false,
            "network.proxy.allow_bypass": false,
            
            // Reduce opportunities for out-of-band DNS/network activity
            // that wouldn't go through the proxy.
            "network.dns.disablePrefetch": true,
            "network.dns.disablePrefetchFromHTTPS": true,
            "network.predictor.enabled": false,
            "network.http.speculative-parallel-limit": 0,
            
            // Force DoH off regardless of the user's separate DoH setting,
            // matching Tor Browser's own actual default (it disables DoH
            // entirely rather than relying on it going through the proxy).
            // The concrete risk this closes: this app's "Increased
            // Protection" DoH mode (network.trr.mode=2) falls back to a
            // native, non-proxy-aware OS resolver query whenever the DoH
            // request itself fails or times out - and DoH-over-Tor is
            // exactly the case where that failure becomes likely, so
            // without this a flaky DoH lookup can leak a hostname straight
            // past the SOCKS proxy. "Max Protection" (trr.mode=3) has no
            // native fallback and DoH's own HTTPS fetch is itself proxied,
            // so it's not a raw leak either way - this override just keeps
            // DNS resolution on the single, already-audited path
            // (socks_remote_dns -> the Tor exit node) instead of also
            // trusting a third-party DoH resolver while circuits are live.
            "network.trr.mode": DNSOverHTTPSProtectionLevel.noProtection.rawValue,
            
            // WebRTC can leak a real IP address even through a SOCKS
            // proxy; disable it outright while routing through Tor.
            "media.peerconnection.enabled": false,
        ])
    }
}
