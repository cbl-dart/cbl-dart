//
//  CBL_Compat.h
//
// Copyright (c) 2018 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#pragma once


#ifndef __has_feature
    #define __has_feature(x) 0
#endif
#ifndef __has_attribute
    #define __has_attribute(x) 0
#endif
#ifndef __has_extension
    #define __has_extension(x) 0
#endif


#ifdef _MSC_VER
    #include <sal.h>
    #define CBLINLINE               __forceinline
    #define _cbl_nonnull            _In_
    #define _cbl_warn_unused        _Check_return_
#else
    #define CBLINLINE               inline
    #define _cbl_warn_unused        __attribute__((warn_unused_result))
#endif

// Macros for defining typed enumerations and option flags.
// To define an enumeration whose values won't be combined:
//      typedef CBL_ENUM(baseIntType, name) { ... };
// To define an enumeration of option flags that will be ORed together:
//      typedef CBL_OPTIONS(baseIntType, name) { ... };
// These aren't just a convenience; they are required for Swift bindings.
#if __has_attribute(enum_extensibility)
#define __CBL_ENUM_ATTRIBUTES __attribute__((enum_extensibility(open)))
#define __CBL_OPTIONS_ATTRIBUTES __attribute__((flag_enum,enum_extensibility(open)))
#else
#define __CBL_ENUM_ATTRIBUTES
#define __CBL_OPTIONS_ATTRIBUTES
#endif

#if __APPLE__
    #include <CoreFoundation/CFBase.h>      /* for CF_ENUM and CF_OPTIONS macros */
    #define CBL_ENUM CF_ENUM
    #define CBL_OPTIONS CF_OPTIONS
#elif DOXYGEN_PARSING
    #define CBL_ENUM(_type, _name)     enum _name : _type _name; enum _name : _type
    #define CBL_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
#else
    #if (__cplusplus && _MSC_VER) || (__cplusplus && __cplusplus >= 201103L && (__has_extension(cxx_strong_enums) || __has_feature(objc_fixed_enum))) || (!__cplusplus && __has_feature(objc_fixed_enum))
        #define CBL_ENUM(_type, _name) int __CBL_ENUM_ ## _name; enum __CBL_ENUM_ATTRIBUTES _name : _type; typedef enum _name _name; enum _name : _type
        #if (__cplusplus)
            #define CBL_OPTIONS(_type, _name) _type _name; enum __CBL_OPTIONS_ATTRIBUTES : _type
        #else
            #define CBL_OPTIONS(_type, _name) int __CBL_OPTIONS_ ## _name; enum __CBL_OPTIONS_ATTRIBUTES _name : _type; typedef enum _name _name; enum _name : _type
        #endif
    #else
        #define CBL_ENUM(_type, _name) _type _name; enum
        #define CBL_OPTIONS(_type, _name) _type _name; enum
    #endif
#endif


// Non-null annotations, for function parameters and struct fields.
// In between CBL_ASSUME_NONNULL_BEGIN and CBL_ASSUME_NONNULL_END, all pointer declarations implicitly
// disallow NULL values, unless annotated with _cbl_nullable (which must come after the `*`.)
// (_cbl_nonnull is occasionally necessary when there are C arrays or multiple levels of pointers.)
// NOTE: Only supported in Clang, so far.
#if __has_feature(nullability)
#  define CBL_ASSUME_NONNULL_BEGIN  _Pragma("clang assume_nonnull begin")
#  define CBL_ASSUME_NONNULL_END    _Pragma("clang assume_nonnull end")
#  define _cbl_nullable             _Nullable
#  define _cbl_nonnull              _Nonnull
#else
#  define CBL_ASSUME_NONNULL_BEGIN
#  define CBL_ASSUME_NONNULL_END
#  define _cbl_nullable
#ifndef _cbl_nonnull
#  define _cbl_nonnull
#endif
#endif


#ifdef __cplusplus
    #define CBLAPI          noexcept
    #define CBL_CAPI_BEGIN  extern "C" { CBL_ASSUME_NONNULL_BEGIN
    #define CBL_CAPI_END    CBL_ASSUME_NONNULL_END }
#else
    #define CBLAPI
    #define CBL_CAPI_BEGIN  CBL_ASSUME_NONNULL_BEGIN
    #define CBL_CAPI_END    CBL_ASSUME_NONNULL_END
#endif


// On Windows, CBL_PUBLIC marks symbols as being exported from the shared library.
// However, this is not the whole list of things that are exported.  The API methods
// are exported using a definition list, but it is not possible to correctly include
// initialized global variables, so those need to be marked (both in the header and 
// implementation) with CBL_PUBLIC.  See kCBLTypeProperty in CBLBlob.h and CBLBlob_CPI.cc
// for an example.
#ifdef _MSC_VER
    #ifdef CBL_EXPORTS
        #define CBL_PUBLIC __declspec(dllexport)
    #else
        #define CBL_PUBLIC __declspec(dllimport)
    #endif
#else // _MSC_VER
    #define CBL_PUBLIC
#endif

// Type-checking for printf-style vararg functions:
#ifdef _MSC_VER
    #define __printflike(A, B)
#else
    #ifndef __printflike
        #define __printflike(fmtarg, firstvararg) __attribute__((__format__ (__printf__, fmtarg, firstvararg)))
    #endif
#endif

