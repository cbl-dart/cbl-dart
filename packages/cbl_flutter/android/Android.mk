
LOCAL_PATH := $(call my-dir)

# CouchbaseLiteC
include $(CLEAR_VARS)
LOCAL_MODULE := CouchbaseLiteC-prebuilt
LOCAL_SRC_FILES := lib/$(TARGET_ARCH_ABI)/libCouchbaseLiteC.so
include $(PREBUILT_SHARED_LIBRARY)

# CouchbaseLiteDart
include $(CLEAR_VARS)
LOCAL_MODULE := CouchbaseLiteDart-prebuilt
LOCAL_SRC_FILES := lib/$(TARGET_ARCH_ABI)/libCouchbaseLiteDart.so
include $(PREBUILT_SHARED_LIBRARY)

# Empty shared library. The PREBUILT_SHARED_LIBRARY script does not cause
# the prebuilt library to be embedded in the APK. By depending on the
# prebuild libraries from an empty shared library, BUILD_SHARED_LIBRARY
# embedds them in the APK.
include $(CLEAR_VARS)
LOCAL_MODULE := CblFlutter
LOCAL_SRC_FILES := CblFlutter.cpp
LOCAL_SHARED_LIBRARIES := CouchbaseLiteC-prebuilt CouchbaseLiteDart-prebuilt
include $(BUILD_SHARED_LIBRARY)
