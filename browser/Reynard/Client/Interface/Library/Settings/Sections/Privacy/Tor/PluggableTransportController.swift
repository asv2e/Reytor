//
//  PluggableTransportController.swift
//  Reynard
//
//  Created by Minh Ton on 19/9/26.
//

import Foundation
import IPtProxy

/// Runs Lyrebird/obfs4proxy and the Snowflake *client* transport in-process
/// via IPtProxy (github.com/tladesignz/IPtProxy - a gomobile-compiled
/// wrapper around the real, upstream Tor Project transports, the same
/// approach Orbot for iOS uses). This is what makes obfs4/snowflake
/// bridges possible on iOS at all: spawning them as separate subprocesses
/// - what arti's own `pt-client` feature otherwise expects - isn't
/// realistically available to an iOS app, but IPtProxy runs them as Go
/// routines linked into this same process instead, exposing a local port
/// arti can point at as an "unmanaged" transport.
///
/// meek and webtunnel aren't covered - IPtProxy doesn't currently provide
/// those transports.
///
/// API surface note: this targets IPtProxy's current class-based Swift API
/// (`IPtProxyController`), confirmed against a real fetch of the library's
/// generated Objective-C header at
/// github.com/tladesignz/IPtProxy/blob/master/IPtProxy.xcframework/ios-arm64/IPtProxy.framework/Headers/IPtProxy.objc.h.
/// The package is pinned in project.pbxproj to that exact commit via a
/// `revision` requirement rather than a version tag, because as of this
/// writing IPtProxy has no tagged release that ships a Package.swift (only
/// `master` does) - SPM has nothing else to resolve against. Per the
/// library's own README, only one `IPtProxyController` should ever be
/// instantiated for the process lifetime, so it's cached in `controller`
/// below and reused for both transports rather than recreated per call.
enum PluggableTransportController {
    private static var controller: IPtProxyController?
    
    static func startObfs4() -> UInt16? {
        guard let controller = sharedController() else {
            return nil
        }

        // Deliberately no bridge-specific arguments (cert, iat-mode):
        // those are supplied per-connection by arti itself over the PT
        // protocol's SOCKS-based handshake, derived from the bridge line
        // arti already parsed - this just needs the generic obfs4
        // listener running.
        do {
            try controller.start(IPtProxyObfs4, proxy: nil)
        } catch {
            return nil
        }

        let port = controller.port(IPtProxyObfs4)
        return port > 0 ? UInt16(port) : nil
    }

    static func stopObfs4() {
        controller?.stop(IPtProxyObfs4)
    }
    
    /// Starts the Snowflake *client* transport - NOT a Snowflake proxy
    /// (`IPtProxySnowflakeProxy`), which volunteers this device as a relay
    /// for other users; that's a different feature this isn't wiring up.
    /// broker/front/ICE values come from the matching snowflake bridge
    /// line's own url=/front=/ice=/ampcache= parameters when present (Tor
    /// Project's bridge distribution includes these), falling back to
    /// commonly published defaults otherwise. If the fallbacks are stale,
    /// get a current snowflake bridge line from torproject.org/bridges
    /// rather than relying on them.
    static func startSnowflake(bridgeLine: String?) -> UInt16? {
        guard let controller = sharedController() else {
            return nil
        }

        let parameters = parameters(from: bridgeLine)
        controller.snowflakeIceServers = parameters["ice"] ?? "stun:stun.l.google.com:19302"
        controller.snowflakeBrokerUrl = parameters["url"] ?? "https://snowflake-broker.torproject.net/"
        controller.snowflakeFrontDomains = parameters["front"] ?? "cdn.sstatic.net"
        if let ampCache = parameters["ampcache"] {
            controller.snowflakeAmpCacheUrl = ampCache
        }
        controller.snowflakeMaxPeers = 1

        do {
            try controller.start(IPtProxySnowflake, proxy: nil)
        } catch {
            return nil
        }

        let port = controller.port(IPtProxySnowflake)
        return port > 0 ? UInt16(port) : nil
    }

    static func stopSnowflake() {
        controller?.stop(IPtProxySnowflake)
    }

    /// Lazily creates the single, process-lifetime `IPtProxyController`,
    /// pointing it at a state directory in Caches (logs + PT state; not
    /// user data, doesn't need to survive reinstalls or sync to iCloud).
    private static func sharedController() -> IPtProxyController? {
        if let controller {
            return controller
        }

        let fileManager = FileManager.default
        guard let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let stateURL = cachesURL.appendingPathComponent("pt_state", isDirectory: true)
        try? fileManager.createDirectory(at: stateURL, withIntermediateDirectories: true)

        let newController = IPtProxyController(
            stateURL.path,
            enableLogging: true,
            unsafeLogging: false,
            logLevel: "ERROR",
            transportEvents: nil
        )
        controller = newController
        return newController
    }
    
    private static func parameters(from bridgeLine: String?) -> [String: String] {
        guard let bridgeLine else {
            return [:]
        }

        var result: [String: String] = [:]
        for token in bridgeLine.split(separator: " ") where token.contains("=") {
            let parts = token.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else {
                continue
            }
            result[parts[0].lowercased()] = String(parts[1])
        }
        return result
    }
}
