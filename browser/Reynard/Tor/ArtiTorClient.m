//
//  ArtiTorClient.m
//  Reynard
//
//  Created by Minh Ton on 13/9/26.
//

#import "ArtiTorClient.h"
#import "ArtiFFI.h"

@interface ArtiTorClient ()
@property(nonatomic, copy, nullable) ArtiTorEventHandler eventHandler;
@end

static void ArtiEventTrampoline(void *_Nullable context, int32_t kind, int32_t percent, const char *_Nullable message) {
    NSString *nsMessage = message ? [NSString stringWithUTF8String:message] : nil;
    ArtiTorEventKind mappedKind;
    switch (kind) {
        case ArtiEventBootstrapProgress:
            mappedKind = ArtiTorEventKindBootstrapProgress;
            break;
        case ArtiEventConnected:
            mappedKind = ArtiTorEventKindConnected;
            break;
        case ArtiEventStopped:
            mappedKind = ArtiTorEventKindStopped;
            break;
        case ArtiEventError:
        default:
            mappedKind = ArtiTorEventKindError;
            break;
    }

    // arti_start invokes this from an arbitrary Rust-owned thread; hop to
    // main before touching the stored handler / letting callers touch UI.
    dispatch_async(dispatch_get_main_queue(), ^{
        ArtiTorEventHandler handler = ArtiTorClient.shared.eventHandler;
        if (handler) {
            handler(mappedKind, (NSInteger)percent, nsMessage);
        }
    });
}

@implementation ArtiTorClient

+ (ArtiTorClient *)shared {
    static ArtiTorClient *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ArtiTorClient new];
    });
    return instance;
}

- (BOOL)isRunning {
    return arti_is_running() != 0;
}

- (void)startWithStateDirectory:(NSString *)stateDirectory
                  cacheDirectory:(NSString *)cacheDirectory
                       socksPort:(uint16_t)socksPort
                     bridgeLines:(nullable NSString *)bridgeLines
                   obfs4ProxyPort:(uint16_t)obfs4ProxyPort
               snowflakeProxyPort:(uint16_t)snowflakeProxyPort
                     eventHandler:(ArtiTorEventHandler)eventHandler {
    if (arti_is_running()) {
        // Already running: just swap the handler so the new caller keeps
        // receiving status updates for the existing client.
        self.eventHandler = eventHandler;
        return;
    }

    self.eventHandler = eventHandler;

    const char *stateDirCString = stateDirectory.fileSystemRepresentation;
    const char *cacheDirCString = cacheDirectory.fileSystemRepresentation;
    const char *bridgeLinesCString = bridgeLines.length > 0 ? bridgeLines.UTF8String : NULL;

    int32_t result = arti_start(stateDirCString, cacheDirCString, socksPort, bridgeLinesCString, obfs4ProxyPort, snowflakeProxyPort, ArtiEventTrampoline, NULL);
    if (result != 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (eventHandler) {
                eventHandler(ArtiTorEventKindError, 0, [NSString stringWithFormat:@"arti_start failed (code %d)", result]);
            }
        });
    }
}

- (void)requestNewIdentity {
    arti_request_new_identity();
}

- (void)requestNewCircuitForHost:(NSString *)host {
    if (host.length == 0) {
        return;
    }
    arti_request_new_circuit_for_host(host.UTF8String);
}

- (void)stop {
    arti_stop();
}

@end
