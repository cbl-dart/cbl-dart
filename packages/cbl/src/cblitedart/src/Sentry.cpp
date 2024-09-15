#include "Sentry.h"

#include <mutex>

#ifdef SENTRY_PLATFORM_UNIX
#include "dlfcn.h"
#endif

// Function typedefs
typedef sentry_value_t (*sentry_value_new_string_t)(const char *value);
typedef int (*sentry_value_set_by_key_t)(sentry_value_t value, const char *k,
                                         sentry_value_t v);
typedef sentry_value_t (*sentry_value_new_breadcrumb_t)(const char *type,
                                                        const char *message);
typedef void (*sentry_add_breadcrumb_t)(sentry_value_t breadcrumb);

// Function pointers
static sentry_value_new_string_t sentry_value_new_string_fp = nullptr;
static sentry_value_set_by_key_t sentry_value_set_by_key_fp = nullptr;
static sentry_value_new_breadcrumb_t sentry_value_new_breadcrumb_fp = nullptr;
static sentry_add_breadcrumb_t sentry_add_breadcrumb_fp = nullptr;

static bool sentryAPIisAvailable = false;

bool CBLDart_InitSentryAPI() {
  static std::once_flag initFlag;
  std::call_once(initFlag, []() {
#if defined(SENTRY_PLATFORM_LINUX)
    // Load libsentry as a shared libray. We expect the dynamic loader to
    // be able to find it. If the library is next to libcblitedart it will be
    // found, since libcblitedart is compiled with an RPATH which looks for
    // libraries in the same directory as libcblitedart.
    auto handle = dlopen("libsentry.so", RTLD_LAZY);
    if (!handle) {
      // Could not find libsentry.so.
      return;
    }

    // Initialize the fuction pointers.
    sentry_value_new_string_fp =
        (sentry_value_new_string_t)dlsym(handle, "sentry_value_new_string");
    sentry_value_set_by_key_fp =
        (sentry_value_set_by_key_t)dlsym(handle, "sentry_value_set_by_key");
    sentry_value_new_breadcrumb_fp = (sentry_value_new_breadcrumb_t)dlsym(
        handle, "sentry_value_new_breadcrumb");
    sentry_add_breadcrumb_fp =
        (sentry_add_breadcrumb_t)dlsym(handle, "sentry_add_breadcrumb");

    // Check that all functions where found and loaded.
    sentryAPIisAvailable =
        (sentry_value_new_string_fp && sentry_value_set_by_key_fp &&
         sentry_value_new_breadcrumb_fp && sentry_add_breadcrumb_fp);
    return;
#else
    // The platform is not supported.
    return;
#endif
  });

  return sentryAPIisAvailable;
}

// Function definitions
sentry_value_t sentry_value_new_string(const char *value) {
  return sentry_value_new_string_fp(value);
}

int sentry_value_set_by_key(sentry_value_t value, const char *k,
                            sentry_value_t v) {
  return sentry_value_set_by_key_fp(value, k, v);
}

sentry_value_t sentry_value_new_breadcrumb(const char *type,
                                           const char *message) {
  return sentry_value_new_breadcrumb_fp(type, message);
}

void sentry_add_breadcrumb(sentry_value_t breadcrumb) {
  sentry_add_breadcrumb_fp(breadcrumb);
}
