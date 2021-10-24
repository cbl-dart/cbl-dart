// clang-format off

#ifndef CBLDART_EXPORT_H
#define CBLDART_EXPORT_H

#if defined _WIN32 || defined __CYGWIN__
    #ifdef _MSC_VER
        #define CBLDART_EXPORT __declspec(dllexport)
    #else
        #define CBLDART_EXPORT __attribute__((dllexport))
    #endif
#else
    #define CBLDART_EXPORT __attribute__((visibility("default")))
#endif


#endif /* CBLDART_EXPORT_H */
