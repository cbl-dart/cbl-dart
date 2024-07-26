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

CBL_CAPI_BEGIN


/** \defgroup logging   Logging
     @{
    Managing messages that Couchbase Lite logs at runtime. */

/** Subsystems that log information. */
typedef CBL_ENUM(uint8_t, CBLLogDomain) {
    kCBLLogDomainDatabase,
    kCBLLogDomainQuery,
    kCBLLogDomainReplicator,
    kCBLLogDomainNetwork
};

/** Levels of log messages. Higher values are more important/severe. Each level includes the lower ones. */
typedef CBL_ENUM(uint8_t, CBLLogLevel) {
    kCBLLogDebug,        ///< Extremely detailed messages, only written by debug builds of CBL.
    kCBLLogVerbose,      ///< Detailed messages about normally-unimportant stuff.
    kCBLLogInfo,         ///< Messages about ordinary behavior.
    kCBLLogWarning,      ///< Messages warning about unlikely and possibly bad stuff.
    kCBLLogError,        ///< Messages about errors
    kCBLLogNone          ///< Disables logging entirely.
};


/** Formats and writes a message to the log, in the given domain at the given level.
    \warning This function takes a `printf`-style format string, with extra parameters to match the format placeholders, and has the same security vulnerabilities as other `printf`-style functions.

    If you are logging a fixed string, call \ref CBL_LogMessage instead, otherwise any `%`
    characters in the `format` string will be misinterpreted as placeholders and the dreaded
    Undefined Behavior will result, possibly including crashes or overwriting the stack.
    @param domain  The log domain to associate this message with.
    @param level  The severity of the message. If this is lower than the current minimum level for the domain
                 (as set by \ref CBLLog_SetConsoleLevel), nothing is logged.
    @param format  A `printf`-style format string. `%` characters in this string introduce parameters,
                 and corresponding arguments must follow. */
void CBL_Log(CBLLogDomain domain,
             CBLLogLevel level,
             const char *format, ...) CBLAPI __printflike(3, 4);

/** Writes a pre-formatted message to the log, exactly as given.
    @param domain  The log domain to associate this message with.
    @param level  The severity of the message. If this is lower than the current minimum level for the domain
                 (as set by \ref CBLLog_SetConsoleLevel), nothing is logged.
    @param message  The exact message to write to the log. */
void CBL_LogMessage(CBLLogDomain domain,
                    CBLLogLevel level,
                    FLSlice message) CBLAPI;



/** \name Console Logging and Custom Logging
    @{ */

/** A logging callback that the application can register.
    @param domain  The domain of the message
    @param level  The severity level of the message.
    @param message  The actual formatted message. */
typedef void (*CBLLogCallback)(CBLLogDomain domain,
                               CBLLogLevel level,
                               FLString message);

/** Gets the current log level for debug console logging.
    Only messages at this level or higher will be logged to the console. */
CBLLogLevel CBLLog_ConsoleLevel(void) CBLAPI;

/** Sets the detail level of logging.
    Only messages whose level is ≥ the given level will be logged to the console. */
void CBLLog_SetConsoleLevel(CBLLogLevel) CBLAPI;

/** Gets the current log level for debug console logging.
    Only messages at this level or higher will be logged to the callback. */
CBLLogLevel CBLLog_CallbackLevel(void) CBLAPI;

/** Sets the detail level of logging.
    Only messages whose level is ≥ the given level will be logged to the callback. */
void CBLLog_SetCallbackLevel(CBLLogLevel) CBLAPI;

/** Gets the current log callback. */
CBLLogCallback CBLLog_Callback(void) CBLAPI;

/** Sets the callback for receiving log messages. If set to NULL, no messages are logged to the console. */
void CBLLog_SetCallback(CBLLogCallback _cbl_nullable callback) CBLAPI;

/** @} */



/** \name Log File Configuration
    @{ */

/** The properties for configuring logging to files.
    @warning `usePlaintext` results in significantly larger log files and higher CPU usage that may slow
            down your app; we recommend turning it off in production. */
typedef struct {
    CBLLogLevel level;       ///< The minimum level of message to write (Required).
    
    FLString directory;      ///< The directory where log files will be created (Required).
    
    /** Max number of older log files to keep (in addition to current one.)
        The default is \ref kCBLDefaultLogFileMaxRotateCount. */
    uint32_t maxRotateCount;
    
    /** The size in bytes at which a file will be rotated out (best effort).
        The default is \ref kCBLDefaultLogFileMaxSize. */
    size_t maxSize;
    
    /** Whether or not to log in plaintext (as opposed to binary.) Plaintext logging is slower and bigger.
        The default is \ref kCBLDefaultLogFileUsePlaintext. */
    bool usePlaintext;
} CBLLogFileConfiguration;

/** Gets the current file logging configuration, or NULL if none is configured. */
const CBLLogFileConfiguration* _cbl_nullable CBLLog_FileConfig(void) CBLAPI;

/** Sets the file logging configuration, and begins logging to files. */
bool CBLLog_SetFileConfig(CBLLogFileConfiguration, CBLError* _cbl_nullable outError) CBLAPI;

/** @} */

/** @} */

CBL_CAPI_END
