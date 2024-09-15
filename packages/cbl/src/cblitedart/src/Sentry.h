#pragma once

#include <inttypes.h>

// === Sentry API Initialization ==============================================

/**
 * Initializes the Sentry API by attempting to open libsentry and bind
 * the APIs below to the functions in libsentry.
 *
 * Returns whether the initialization was successful. The Sentry API cannot be
 * used if this function returns false.
 */
bool CBLDart_InitSentryAPI();

// === Sentry API =============================================================

// Subset of Sentry Native SDK API copied from `sentry.h`
// https://github.com/getsentry/sentry-native/blob/0e17d7c238d784d0283da582165f2d4f85bbb0a8/include/sentry.h

/* common platform detection */
#ifdef _WIN32
#define SENTRY_PLATFORM_WINDOWS
#elif defined(__APPLE__)
#include <TargetConditionals.h>
#if defined(TARGET_OS_OSX) && TARGET_OS_OSX
#define SENTRY_PLATFORM_MACOS
#elif defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE
#define SENTRY_PLATFORM_IOS
#endif
#define SENTRY_PLATFORM_DARWIN
#define SENTRY_PLATFORM_UNIX
#elif defined(__ANDROID__)
#define SENTRY_PLATFORM_ANDROID
#define SENTRY_PLATFORM_LINUX
#define SENTRY_PLATFORM_UNIX
#elif defined(__linux) || defined(__linux__)
#define SENTRY_PLATFORM_LINUX
#define SENTRY_PLATFORM_UNIX
#elif defined(_AIX)
/* IBM i PASE is also counted as AIX */
#define SENTRY_PLATFORM_AIX
#define SENTRY_PLATFORM_UNIX
#else
#error unsupported platform
#endif

// Don't make the Sentry API public.
#define SENTRY_API

/**
 * Represents a sentry protocol value.
 *
 * The members of this type should never be accessed.  They are only here
 * so that alignment for the type can be properly determined.
 *
 * Values must be released with `sentry_value_decref`.  This lowers the
 * internal refcount by one.  If the refcount hits zero it's freed.  Some
 * values like primitives have no refcount (like null) so operations on
 * those are no-ops.
 *
 * In addition values can be frozen.  Some values like primitives are always
 * frozen but lists and dicts are not and can be frozen on demand.  This
 * automatically happens for some shared values in the event payload like
 * the module list.
 */
union sentry_value_u {
  uint64_t _bits;
  double _double;
};
typedef union sentry_value_u sentry_value_t;

/**
 * Creates a new null terminated string.
 */
SENTRY_API sentry_value_t sentry_value_new_string(const char *value);

/**
 * Sets a key to a value in the map.
 *
 * This moves the ownership of the value into the map.  The caller does not
 * have to call `sentry_value_decref` on it.
 */
SENTRY_API int sentry_value_set_by_key(sentry_value_t value, const char *k,
                                       sentry_value_t v);

/**
 * Creates a new Breadcrumb with a specific type and message.
 *
 * See https://develop.sentry.dev/sdk/event-payloads/breadcrumbs/
 *
 * Either parameter can be NULL in which case no such attributes is created.
 */
SENTRY_API sentry_value_t sentry_value_new_breadcrumb(const char *type,
                                                      const char *message);

/**
 * Adds the breadcrumb to be sent in case of an event.
 */
SENTRY_API void sentry_add_breadcrumb(sentry_value_t breadcrumb);
