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
#include "CBLLogSinks.h"

CBL_CAPI_BEGIN

/** \defgroup logging   Logging
     @{
    Managing messages that Couchbase Lite logs at runtime.
 */

/** Formats and writes a message to the log, in the given domain at the given level.
    \warning This function takes a `printf`-style format string, with extra parameters to match the format placeholders,
             and has the same security vulnerabilities as other `printf`-style functions.

    If you are logging a fixed string, call \ref CBL_LogMessage instead, otherwise any `%`
    characters in the `format` string will be misinterpreted as placeholders and the dreaded
    Undefined Behavior will result, possibly including crashes or overwriting the stack.
    @param domain  The log domain to associate this message with.
    @param level  The severity of the message. If this is lower than the current minimum level for the domain
                 (as set by \ref CBLLog_SetConsoleLevel), nothing is logged.
    @param format  A `printf`-style format string. `%` characters in this string introduce parameters,
                 and corresponding arguments must follow.
    @warning  <b>Deprecated :</b> No alternative for this function and this function will be removed in the future release. */
void CBL_Log(CBLLogDomain domain,
             CBLLogLevel level,
             const char *format, ...) CBLAPI __printflike(3, 4);

/** Writes a pre-formatted message to the log, exactly as given.
    @param domain  The log domain to associate this message with.
    @param level  The severity of the message. If this is lower than the current minimum level for the domain
                 (as set by \ref CBLLog_SetConsoleLevel), nothing is logged.
    @param message  The exact message to write to the log.
    @warning  <b>Deprecated :</b> No alternative for this function and this function will be removed in the future release.*/
void CBL_LogMessage(CBLLogDomain domain,
                    CBLLogLevel level,
                    FLSlice message) CBLAPI;

/** @} */

CBL_CAPI_END
