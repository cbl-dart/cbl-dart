#pragma once

#ifdef _WIN32
#ifdef __cplusplus
#define CBLDART_EXPORT extern "C" __declspec(dllexport)
#else
#define CBLDART_EXPORT __declspec(dllexport)
#endif
#else
#ifdef __cplusplus
#define CBLDART_EXPORT extern "C" __attribute__((visibility("default")))
#else
#define CBLDART_EXPORT __attribute__((visibility("default")))
#endif
#endif
