#pragma once

#ifdef _WIN32
#if __cplusplus
#define CBLDART_EXPORT extern "C" __declspec(dllexport)
#else
#define CBLDART_EXPORT __declspec(dllexport)
#endif
#else
#if __cplusplus
#define CBLDART_EXPORT extern "C"
#else
#define CBLDART_EXPORT
#endif
#endif