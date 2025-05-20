#import "ListenSharingIntentPlugin.h"
#if __has_include(<listen_sharing_intent/listen_sharing_intent-Swift.h>)
#import <listen_sharing_intent/listen_sharing_intent-Swift.h>
#else
#import "listen_sharing_intent-Swift.h"
#endif

@implementation ListenSharingIntentPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftListenSharingIntentPlugin registerWithRegistrar:registrar];
}
@end
