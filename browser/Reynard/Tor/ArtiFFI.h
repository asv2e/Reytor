//
//  ArtiFFI.h
//  Reynard
//
//  Created by Minh Ton on 13/9/26.
//
//  C ABI surface exported by the arti-ffi Rust crate (support/arti-ffi).
//  Mirrors the shape of IdeviceFFI.h: opaque control via a handful of
//  extern "C" functions, no ownership of Rust-side memory is handed to
//  Swift/Obj-C beyond what's passed back through the event callback.
//

#ifndef ArtiFFI_h
#define ArtiFFI_h

#include <stdint.h>

typedef enum {
    ArtiEventBootstrapProgress = 0, // percent: 0-100
    ArtiEventConnected = 1,         // Tor client bootstrapped and SOCKS proxy accepting connections
    ArtiEventError = 2,             // message describes what went wrong; client is not usable
    ArtiEventStopped = 3,           // arti_stop() completed, or the background thread exited
} ArtiEventKind;

// Invoked from an arbitrary background thread/task. Implementations must
// hop to the main thread themselves before touching UI. `message` is only
// valid for the duration of the call.
typedef void (*ArtiEventCallback)(void *_Nullable context, int32_t kind, int32_t percent, const char *_Nullable message);

// Starts bootstrapping a Tor client and, once ready, a local SOCKS5
// forwarder bound to 127.0.0.1:socksPort. Returns 0 if the client is
// starting (or already running), -1 if arguments were invalid, -2 if a
// client is already running with different parameters.
//
// stateDir/cacheDir must be writable, app-private directories (e.g. inside
// Application Support) - Arti persists consensus/descriptor state there.
//
// bridgeLines may be NULL or empty for no bridges, or a newline-separated
// list of bridge lines in the standard "Bridge [transport] IP:PORT
// FINGERPRINT [k=v ...]" format. Plain bridges (no transport keyword)
// always work. obfs4 and snowflake bridge lines work if the matching
// proxy port is nonzero (0 = that transport isn't running - its bridge
// lines are skipped). Those ports come from IPtProxy, started
// separately on the Swift side before calling this - see
// PluggableTransportController.swift. meek and webtunnel bridge lines
// are always skipped; IPtProxy doesn't provide those transports.
int32_t arti_start(const char *_Nonnull state_dir,
                    const char *_Nonnull cache_dir,
                    uint16_t socks_port,
                    const char *_Nullable bridge_lines,
                    uint16_t obfs4_proxy_port,
                    uint16_t snowflake_proxy_port,
                    ArtiEventCallback _Nonnull callback,
                    void *_Nullable context);

// Discards all current circuits so that subsequent connections build a
// fresh path through the network - the Tor-level half of "New Identity".
// No-op if no client is running.
void arti_request_new_identity(void);

// Narrower than arti_request_new_identity: forces a fresh circuit set for
// just one destination hostname, leaving every other host's circuits
// untouched. No-op if no client is running.
void arti_request_new_circuit_for_host(const char *_Nonnull host);

// Stops the SOCKS forwarder and tears down the Tor client. Safe to call
// even if arti_start was never called or already stopped. Blocks briefly
// for the background thread to exit.
void arti_stop(void);

// Returns 1 if a client is currently running (bootstrapped or not), 0 otherwise.
int32_t arti_is_running(void);

#endif /* ArtiFFI_h */
