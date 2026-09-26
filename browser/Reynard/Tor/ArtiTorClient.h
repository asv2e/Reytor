//
//  ArtiTorClient.h
//  Reynard
//
//  Created by Minh Ton on 13/9/26.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ArtiTorEventKind) {
    ArtiTorEventKindBootstrapProgress,
    ArtiTorEventKindConnected,
    ArtiTorEventKindError,
    ArtiTorEventKindStopped,
};

// Mirrors ArtiFFI.h's ArtiEventCallback, marshalled onto the main queue.
typedef void (^ArtiTorEventHandler)(ArtiTorEventKind kind, NSInteger percent, NSString *_Nullable message);

// Thin Obj-C wrapper around the arti-ffi static library (see
// support/arti-ffi and ArtiFFI.h). Keeps the raw C ABI out of Swift/the
// bridging header, matching how JITEnabler wraps IdeviceFFI.h.
@interface ArtiTorClient : NSObject

@property(class, nonatomic, readonly) ArtiTorClient *shared;
@property(nonatomic, readonly) BOOL isRunning;

// stateDirectory/cacheDirectory must already exist and be writable. Safe to
// call again while already running - it's a no-op in that case.
// bridgeLines is nil/empty for no bridges, or a newline-separated list of
// bridge lines. Plain lines always work; obfs4/snowflake lines work when
// the matching port is nonzero (start the matching IPtProxy transport via
// PluggableTransportController first and pass back its port - 0 means
// "not running", and that transport's bridge lines are skipped rather
// than failing the whole connection).
- (void)startWithStateDirectory:(NSString *)stateDirectory
                  cacheDirectory:(NSString *)cacheDirectory
                       socksPort:(uint16_t)socksPort
                     bridgeLines:(nullable NSString *)bridgeLines
                   obfs4ProxyPort:(uint16_t)obfs4ProxyPort
               snowflakeProxyPort:(uint16_t)snowflakeProxyPort
                     eventHandler:(ArtiTorEventHandler)eventHandler;

- (void)requestNewIdentity;
- (void)requestNewCircuitForHost:(NSString *)host;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
