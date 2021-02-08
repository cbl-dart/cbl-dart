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
    #define CBLINLINE           __forceinline
    #define _cbl_nonnull            _In_
    #define _cbl_returns_nonnull    _Ret_notnull_
    #define _cbl_warn_unused        _Check_return_
    #define _cbl_deprecated
#else
    #define CBLINLINE            inline
    #define _cbl_returns_nonnull __attribute__((returns_nonnull))
    #define _cbl_warn_unused     __attribute__((warn_unused_result))
    #ifdef __clang__
        #define _cbl_nonnull         __attribute((nonnull))
    #else
        #define _cbl_nonnull   /* GCC does not support the way we use nonnull */
    #endif
    #define _cbl_deprecated    __attribute__((deprecated()))
#endif

// Macros for defining typed enumerations and option flags.
// To define an enumeration whose values won't be combined:
//      typedef CBL_ENUM(baseIntType, name) { ... };
// To define an enumeration of option flags that will be ORed together:
//      typedef CBL_OPTIONS(baseIntType, name) { ... };
// These aren't just a convenience; they are required for Swift bindings.
#if __APPLE__
    #include <CoreFoundation/CFBase.h>      /* for CF_ENUM and CF_OPTIONS macros */
    #define CBL_ENUM CF_ENUM
    #define CBL_OPTIONS CF_OPTIONS
#elif DOXYGEN_PARSING
    #define CBL_ENUM(_type, _name)     enum _name : _type _name; enum _name : _type
    #define CBL_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
#else
    #if (__cplusplus && _MSC_VER) || (__cplusplus && __cplusplus >= 201103L && (__has_extension(cxx_strong_enums) || __has_feature(objc_fixed_enum))) || (!__cplusplus && __has_feature(objc_fixed_enum))
        #define CBL_ENUM(_type, _name)     enum _name : _type _name; enum _name : _type
        #if (__cplusplus)
            #define CBL_OPTIONS(_type, _name) _type _name; enum : _type
        #else
            #define CBL_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
        #endif
    #else
        #define CBL_ENUM(_type, _name) _type _name; enum
        #define CBL_OPTIONS(_type, _name) _type _name; enum
    #endif
#endif


#ifdef __cplusplus
    #define CBLAPI noexcept
#else
    #define CBLAPI
#endif


// Export/import stuff:
#ifdef _MSC_VER
    #ifdef LITECORE_EXPORTS
        #define CBL_CORE_API __declspec(dllexport)
    #else
        #define CBL_CORE_API __declspec(dllimport)
    #endif
#else // _MSC_VER
    #define CBL_CORE_API
#endif

// Type-checking for printf-style vararg functions:
#ifdef _MSC_VER
    #define __printflike(A, B)
#else
    #ifndef __printflike
        #define __printflike(fmtarg, firstvararg) __attribute__((__format__ (__printf__, fmtarg, firstvararg)))
    #endif
#endif
