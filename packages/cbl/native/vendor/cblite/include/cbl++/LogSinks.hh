//
// LogSinks.hh
//
// Copyright (c) 2025 Couchbase, Inc All rights reserved.
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
#include "cbl/CBLLogSinks.h"
#include "cbl++/Base.hh"
#include "cbl/CBLDefaults.h"

CBL_ASSUME_NONNULL_BEGIN

namespace cbl {

    using LogDomainMask   = CBLLogDomainMask;
    using LogSinkCallback = CBLLogSinkCallback;
    using LogLevel        = CBLLogLevel;
    using LogDomain       = CBLLogDomain;

    /** Console log sink configuration for logging to the console. */
    struct ConsoleLogSink {
        LogLevel level = kCBLLogNone;           ///< The minimum level of message to write (Required).
        LogDomainMask domains;                  ///< Bitmask for enabled log domains. Use zero for all domains.

        operator CBLConsoleLogSink() const {
            return {(CBLLogLevel)(uint8_t)level, domains};
        }
    };

    /** Custom log sink configuration for logging to a user-defined callback. */
    struct CustomLogSink {
        LogLevel level = kCBLLogNone;            ///< The minimum level of message to write (Required).
        LogSinkCallback _cbl_nullable callback;  ///< Custom log callback.
        LogDomainMask domains;                   ///< Bitmask for enabled log domains. Use zero for all domains.

        operator CBLCustomLogSink() const {
            return {level, callback, domains};
        }
    };

    /** File log sink configuration for logging to files. */
    struct FileLogSink {
        LogLevel level = kCBLLogNone;            ///< The minimum level of message to write (Required).
        std::string directory;                   ///< The directory where log files will be created (Required).

        /** The maximum number of files to save per log level.
            The default is \ref kCBLDefaultFileLogSinkMaxKeptFiles. */
        uint32_t maxKeptFiles = kCBLDefaultFileLogSinkMaxKeptFiles;

        /** The size in bytes at which a file will be rotated out (best effort).
            The default is \ref kCBLDefaultFileLogSinkMaxSize. */
        size_t maxSize = kCBLDefaultFileLogSinkMaxSize;

        /** Whether or not to log in plaintext as opposed to binary. Plaintext logging is slower and bigger.
            The default is \ref kCBLDefaultFileLogSinkUsePlaintext. */
        bool usePlaintext = kCBLDefaultFileLogSinkUsePlaintext;
    };

    /** Controls where Couchbase Lite writes its log messages. There are three independent
        sinks — console, custom (a user callback), and file — each configured separately.
        Disable a sink by setting its log level to \ref kCBLLogNone. */
    class LogSinks {
    public:
        /** Sets the console log sink. To disable it, set the sink's log level to \ref kCBLLogNone.
            @param sink  The console log sink configuration. */
        static void setConsole(const ConsoleLogSink& sink) {
            CBLLogSinks_SetConsole(sink);
        }

        /** Returns the current console log sink. It is enabled at the warning level for all
            domains by default. */
        static ConsoleLogSink console() {
            return fromCConfiguration(CBLLogSinks_Console());
        }

        /** Sets the custom log sink, whose callback receives each log message. To disable it,
            set the sink's log level to \ref kCBLLogNone.
            @param sink  The custom log sink configuration. */
        static void setCustom(const CustomLogSink& sink) {
            CBLLogSinks_SetCustom(sink);
        }

        /** Returns the current custom log sink. It is disabled by default. */
        static CustomLogSink custom() {
            return fromCConfiguration(CBLLogSinks_CustomSink());
        }

        /** Sets the file log sink, which writes log messages to files in a directory. To disable
            it, set the sink's log level to \ref kCBLLogNone.
            @param sink  The file log sink configuration. */
        static void setFile(FileLogSink sink) {
            CBLLogSinks_SetFile({
                (CBLLogLevel)(uint8_t)sink.level,
                slice(sink.directory),
                sink.maxKeptFiles,
                sink.maxSize,
                sink.usePlaintext
            });
        }

        /** Returns the current file log sink. It is disabled by default. */
        static FileLogSink file() {
            return fromCConfiguration(CBLLogSinks_File());
        }

    private:
        static ConsoleLogSink fromCConfiguration(const CBLConsoleLogSink& cSink) {
            return { cSink.level, cSink.domains};
        }

        static CustomLogSink fromCConfiguration(const CBLCustomLogSink& cSink) {
            return { cSink.level, cSink.callback, cSink.domains};
        }

        static FileLogSink fromCConfiguration(const CBLFileLogSink& cSink) {
            return {
                cSink.level,
                std::string(cSink.directory),
                cSink.maxKeptFiles,
                cSink.maxSize,
                cSink.usePlaintext
            };
        }
    };
}

CBL_ASSUME_NONNULL_END
