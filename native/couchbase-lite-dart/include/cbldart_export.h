
#ifndef CBLDART_EXPORT_H
#define CBLDART_EXPORT_H

#ifdef CBLDART_STATIC_DEFINE
#define CBLDART_EXPORT
#define CBLDART_NO_EXPORT
#else
#ifndef CBLDART_EXPORT
#ifdef CouchbaseLiteDart_EXPORTS
/* We are building this library */
#define CBLDART_EXPORT __attribute__((visibility("default")))
#else
/* We are using this library */
#define CBLDART_EXPORT __attribute__((visibility("default")))
#endif
#endif

#ifndef CBLDART_NO_EXPORT
#define CBLDART_NO_EXPORT __attribute__((visibility("hidden")))
#endif
#endif

#ifndef CBLDART_DEPRECATED
#define CBLDART_DEPRECATED __attribute__((__deprecated__))
#endif

#ifndef CBLDART_DEPRECATED_EXPORT
#define CBLDART_DEPRECATED_EXPORT CBLDART_EXPORT CBLDART_DEPRECATED
#endif

#ifndef CBLDART_DEPRECATED_NO_EXPORT
#define CBLDART_DEPRECATED_NO_EXPORT CBLDART_NO_EXPORT CBLDART_DEPRECATED
#endif

#if 0 /* DEFINE_NO_DEPRECATED */
#ifndef CBLDART_NO_DEPRECATED
#define CBLDART_NO_DEPRECATED
#endif
#endif

#endif /* CBLDART_EXPORT_H */
