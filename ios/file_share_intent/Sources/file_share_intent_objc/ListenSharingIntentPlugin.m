#import "file_share_intent/ListenSharingIntentPlugin.h"
#if __has_include(<file_share_intent/file_share_intent-Swift.h>)
#import <file_share_intent/file_share_intent-Swift.h>
#else
#import "file_share_intent-Swift.h"
#endif

@implementation ListenSharingIntentPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftListenSharingIntentPlugin registerWithRegistrar:registrar];
}
@end
