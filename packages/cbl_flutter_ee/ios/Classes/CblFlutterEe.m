#import "CblFlutterEe.h"
#if __has_include(<cbl_flutter_ee/cbl_flutter_ee-Swift.h>)
#import <cbl_flutter_ee/cbl_flutter_ee-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cbl_flutter_ee-Swift.h"
#endif

@implementation CblFlutterEe
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCblFlutterEe registerWithRegistrar:registrar];
}
@end
