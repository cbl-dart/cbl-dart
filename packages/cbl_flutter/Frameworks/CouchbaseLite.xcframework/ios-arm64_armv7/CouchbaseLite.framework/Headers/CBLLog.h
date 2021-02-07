//
// CBLLog.h
//
// Copyright © 2019 Couchbase. All rights reserved.
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
#include "CBLBase.h"

#ifdef __cplusplus
extern "C" {
#endif


/** \defgroup logging   Logging
     @{
    Managing messages that Couchbase Lite logs at runtime. */

/** Subsystems that log information. */
typedef CBL_ENUM(uint8_t, CBLLogDomain) {
    kCBLLogDomainAll,
    kCBLLogDomainDatabase,
    kCBLLogDomainQuery,
    kCBLLogDomainReplicator,
    kCBLLogDomainNetwork,
};

/** Levels of log messages. Higher values are more important/severe. Each level includes the lower ones. */
typedef CBL_ENUM(uint8_t, CBLLogLevel) {
    CBLLogDebug,        ///< Extremely detailed messages, only written by debug builds of CBL.
    CBLLogVerbose,      ///< Detailed messages about normally-unimportant stuff.
    CBLLogInfo,         ///< Messages about ordinary behavior.
    CBLLogWarning,      ///< Messages warning about unlikely and possibly bad stuff.
    CBLLogError,        ///< Messages about errors
    CBLLogNone          ///< Disables logging entirely.
};


/** Formats and writes a message to the log, in the given domain at the given level.
    \warning This function takes a `printf`-style format string, with extra parameters to match the format placeholders, and has the same security vulnerabilities as other `printf`-style functions.
    If you are logging a fixed string, call \ref CBL_Log_s instead, otherwise any `%` characters in the
    `format` string will be misinterpreted as placeholders and the dreaded Undefined Behavior will result,
    possibly including crashes or overwriting the stack.
    @param domain  The log domain to associate this message with.
    @param level  The severity of the message. If this is lower than the current minimum level for the domain
                 (as set by \ref CBLLog_SetConsoleLevel), nothing is logged.
    @param format  A `printf`-style format string. `%` characters in this string introduce parameters,
                 and corresponding arguments must follow. */
void CBL_Log(CBLLogDomain domain, CBLLogLevel level, const char *format _cbl_nonnull, ...) CBLAPI
        __printflike(3, 4);

/** Writes a pre-formatted message to the log, exactly as given.
    @param domain  The log domain to associate this message with.
    @param level  The severity of the message. If this is lower than the current minimum level for the domain
                 (as set by \ref CBLLog_SetConsoleLevel), nothing is logged.
    @param message  The exact message to write to the log. */
void CBL_Log_s(CBLLogDomain domain, CBLLogLevel level, FLSlice message) CBLAPI;



/** \name Console Logging and Custom Logging
    @{ */

/** A logging callback that the application can register.
    @param domain  The domain of the message; \ref kCBLLogDomainAll if it doesn't fall into a specific domain.
    @param level  The severity level of the message.
    @param message  The actual formatted message. */
typedef void (*CBLLogCallback)(CBLLogDomain domain,
                               CBLLogLevel level,
                               const char *message _cbl_nonnull);

/** Gets the current log level for debug console logging.
    Only messages at this level or higher will be logged to the console or callback. */
CBLLogLevel CBLLog_ConsoleLevel(void) CBLAPI;

/** Sets the detail level of logging.
    Only messages whose level is ≥ the given level will be logged to the console or callback. */
void CBLLog_SetConsoleLevel(CBLLogLevel) CBLAPI;

/** Returns true if a message with the given domain and level would be logged to the console. */
bool CBLLog_WillLogToConsole(CBLLogDomain domain, CBLLogLevel level) CBLAPI;

/** Gets the current log callback. */
CBLLogCallback CBLLog_Callback(void) CBLAPI;

/** Sets the callback for receiving log messages. If set to NULL, no messages are logged to the console. */
void CBLLog_SetCallback(CBLLogCallback) CBLAPI;

/** @} */



/** \name Log File Configuration
    @{ */

/** The properties for configuring logging to files.
    @warning `usePlaintext` results in significantly larger log files and higher CPU usage that may slow
            down your app; we recommend turning it off in production. */
typedef struct {
    const char* directory;    ///< The directory where log files will be created.
    uint32_t maxRotateCount;  ///< Max number of older logs to keep (i.e. total number will be one more.)
    size_t maxSize;           ///< The size in bytes at which a file will be rotated out (best effort).
    bool usePlaintext;        ///< Whether or not to log in plaintext (as opposed to binary)
} CBLLogFileConfiguration;

/** Gets the current file logging configuration. */
const CBLLogFileConfiguration* CBLLog_FileConfig(void) CBLAPI;

/** Sets the file logging configuration. */
void CBLLog_SetFileConfig(CBLLogFileConfiguration) CBLAPI;

/** @} */

/** @} */

#ifdef __cplusplus
}
#endif
