#include "p2p_issue.h"

#include <cbl/CBLLog.h>
#include <cbl/CBLLogSinks.h>
#include <cbl/CBLTLSIdentity.h>
#include <fleece/FLSlice.h>

#include <cstdio>

void CreatePersistedIdentity() {
  CBLLog_SetConsoleLevel(kCBLLogVerbose);

  auto error = CBLError{};

  if (!CBLTLSIdentity_DeleteIdentityWithLabel(FLSTR("test"), &error)) {
    auto errorMessage = CBLError_Message(&error);
    printf("Error deleting identity: %.*s\n", (int)errorMessage.size,
           (char*)errorMessage.buf);
    FLSliceResult_Release(errorMessage);
    return;
  } else {
    printf("Identity deleted successfully\n");
  }

  auto attributes = FLMutableDict_New();
  FLMutableDict_SetString(attributes, kCBLCertAttrKeyCommonName, FLSTR("test"));

  auto identity = CBLTLSIdentity_CreateIdentity(
      kCBLKeyUsagesServerAuth, attributes, 1000, FLSTR("test"), &error);

  FLMutableDict_Release(attributes);

  if (identity) {
    printf("Identity created successfully\n");
    CBLTLSIdentity_Release(identity);
    printf("Identity released successfully\n");
  } else {
    auto errorMessage = CBLError_Message(&error);
    printf("Error creating identity: %.*s\n", (int)errorMessage.size,
           (char*)errorMessage.buf);
    FLSliceResult_Release(errorMessage);
  }
}

void CreatePersistedIdentityInAutoReleasePool() {
  @autoreleasepool {
    CreatePersistedIdentity();
  }
}
