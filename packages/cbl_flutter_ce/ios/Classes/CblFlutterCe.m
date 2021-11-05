#import "CblFlutterCe.h"
#if __has_include(<cbl_flutter_ce/cbl_flutter_ce-Swift.h>)
#import <cbl_flutter_ce/cbl_flutter_ce-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cbl_flutter_ce-Swift.h"
#endif

@implementation CblFlutterCe
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCblFlutterCe registerWithRegistrar:registrar];
}
@end
