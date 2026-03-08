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

// VOLATILE API: Couchbase Lite C++ API is not finalized, and may change in
// future releases.

#pragma once
#include "cbl/CBLLogSinks.h"

CBL_ASSUME_NONNULL_BEGIN

namespace cbl {
    class LogSinks {
    public:
        static void setConsole(const CBLConsoleLogSink& sink) {
            CBLLogSinks_SetConsole(sink);
        }
        
        static CBLConsoleLogSink console() {
            return CBLLogSinks_Console();
        }
        
        static void setCustom(const CBLCustomLogSink& sink) {
            CBLLogSinks_SetCustom(sink);
        }
                
        static CBLCustomLogSink custom() {
            return CBLLogSinks_CustomSink();
        }
                
        static void setFile(const CBLFileLogSink& sink) {
            CBLLogSinks_SetFile(sink);
        }
                
        static CBLFileLogSink file() {
            return CBLLogSinks_File();
        }
    };
}

CBL_ASSUME_NONNULL_END
