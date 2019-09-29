#import "FlutterPlayoutPlugin.h"
#import <flutter_playout/flutter_playout-Swift.h>

@implementation FlutterPlayoutPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterPlayoutPlugin registerWithRegistrar:registrar];
}
@end
