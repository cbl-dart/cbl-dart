#import "CblFlutterPlugin.h"
#if __has_include(<cbl_flutter/cbl_flutter-Swift.h>)
#import <cbl_flutter/cbl_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cbl_flutter-Swift.h"
#endif

@implementation CblFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCblFlutterPlugin registerWithRegistrar:registrar];
}
@end
