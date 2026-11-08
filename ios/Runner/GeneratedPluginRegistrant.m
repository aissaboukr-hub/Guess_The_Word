//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<network_info_plus/FPPNetworkInfoPlusPlugin.h>)
#import <network_info_plus/FPPNetworkInfoPlusPlugin.h>
#else
@import network_info_plus;
#endif

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FPPNetworkInfoPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FPPNetworkInfoPlusPlugin"]];
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
}

@end
