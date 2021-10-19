#import "CblFlutterLocalPlugin.h"
#if __has_include(<cbl_flutter_local/cbl_flutter_local-Swift.h>)
#import <cbl_flutter_local/cbl_flutter_local-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cbl_flutter_local-Swift.h"
#endif

@implementation CblFlutterLocalPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCblFlutterLocalPlugin registerWithRegistrar:registrar];
}
@end
