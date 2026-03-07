//
// CBLLogSink.h
//
// Copyright © 2024 Couchbase. All rights reserved.
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

/** \defgroup logging   Logging (Deprecated)
     @{
     Manages Couchbase Lite logging configuration, with three log sinks:
     - **Console Log Sink**: Enabled by default at the **warning** level for all domains.
     - **Custom Log Sink**: Logs to a user-defined callback.
     - **File Log Sink**: Logs to files with customizable settings.
 */

/** The severity level of log messages */
typedef CBL_ENUM(uint8_t, CBLLogLevel) {
    kCBLLogDebug,               ///< Debug-level messages with highly detailed information, Available only in debug builds of Couchbase Lite.
    kCBLLogVerbose,             ///< Verbose messages providing detailed operational information.
    kCBLLogInfo,                ///< Info messages about normal application behavior.
    kCBLLogWarning,             ///< Warning messages indicating potential issues or unusual conditions.
    kCBLLogError,               ///< Error messages indicating a failure or problem that occurred.
    kCBLLogNone                 ///< Disables logging entirely. No messages will be logged.
};

/** Subsystems for logging messages. */
typedef CBL_ENUM(uint8_t, CBLLogDomain) {
    kCBLLogDomainDatabase,      ///< Logging domain for the database subsystem.
    kCBLLogDomainQuery,         ///< Logging domain for the query subsystem.
    kCBLLogDomainReplicator,    ///< Logging domain for the replicator subsystem.
    kCBLLogDomainNetwork,       ///< Logging domain for the network subsystem.
    kCBLLogDomainListener       ///< Logging domain for the listener subsystem.
};

/** A bitmask representing a set of logging domains.
 *
 *  Use this bitmask to specify one or more logging domains by combining the
 *  constants with the bitwise OR operator (`|`). This is helpful for enabling
 *  or filtering logs for specific domains. */
typedef CBL_OPTIONS(uint16_t, CBLLogDomainMask) {
    kCBLLogDomainMaskDatabase   = 1 << kCBLLogDomainDatabase,
    kCBLLogDomainMaskQuery      = 1 << kCBLLogDomainQuery,
    kCBLLogDomainMaskReplicator = 1 << kCBLLogDomainReplicator,
    kCBLLogDomainMaskNetwork    = 1 << kCBLLogDomainNetwork,
    kCBLLogDomainMaskListener   = 1 << kCBLLogDomainListener,
    kCBLLogDomainMaskAll        = 0xFF
};

/** A callback function for a custom log sink.
    @param domain  The domain of the message
    @param level  The severity level of the message.
    @param message  The actual formatted message. */
typedef void (*CBLLogSinkCallback)(CBLLogDomain domain, CBLLogLevel level, FLString message);

/** Console log sink configuration for logging to the cosole. */
typedef struct {
    CBLLogLevel level;                          ///< The minimum level of message to write (Required).
    CBLLogDomainMask domains;                   ///< Bitmask for enabled log domains. Use zero for all domains.
} CBLConsoleLogSink;

/** Custom log sink configuration for logging to a user-defined callback. */
typedef struct {
    CBLLogLevel level;                          ///< The minimum level of message to write (Required).
    CBLLogSinkCallback _cbl_nullable callback;  ///< Custom log callback (Required).
    CBLLogDomainMask domains;                   ///< Bitmask for enabled log domains. Use zero for all domains.
} CBLCustomLogSink;

/** File log sink configuration for logging to files. */
typedef struct {
    CBLLogLevel level;                          ///< The minimum level of message to write (Required).
    FLString directory;                         ///< The directory where log files will be created (Required).
    
    /** The maximum number of files to save per log level.
        The default is \ref kCBLDefaultFileLogSinkMaxKeptFiles. */
    uint32_t maxKeptFiles;
    
    /** The size in bytes at which a file will be rotated out (best effort).
        The default is \ref kCBLDefaultFileLogSinkMaxSize. */
    size_t maxSize;
    
    /** Whether or not to log in plaintext as opposed to binary. Plaintext logging is slower and bigger.
        The default is \ref kCBLDefaultFileLogSinkUsePlaintext. */
    bool usePlaintext;
} CBLFileLogSink;

/** Set the console log sink. To disable the console log sink, set the log level to kCBLLogNone. */
void CBLLogSinks_SetConsole(CBLConsoleLogSink sink) CBLAPI;

/** Get the current console log sink. The console log sink is enabled at the warning level for all domains by default. */
CBLConsoleLogSink CBLLogSinks_Console(void) CBLAPI;

/** Set the custom log sink. To disable the custom log sink, set the log level to kCBLLogNone. */
void CBLLogSinks_SetCustom(CBLCustomLogSink sink) CBLAPI;

/** Get the current custom log sink. The custom log sink is disabled by default. */
CBLCustomLogSink CBLLogSinks_CustomSink(void) CBLAPI;

/** Set the file log sink. To disable the file log sink, set the log level to kCBLLogNone. */
void CBLLogSinks_SetFile(CBLFileLogSink sink) CBLAPI;

/** Get the current custom log sink. The file log sink is disabled by default. */
CBLFileLogSink CBLLogSinks_File(void) CBLAPI;

CBL_CAPI_END

/** @} */
