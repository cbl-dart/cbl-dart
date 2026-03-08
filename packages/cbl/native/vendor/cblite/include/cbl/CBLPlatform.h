//
// CBLPlatform.h
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

#ifdef __ANDROID__

/** \defgroup android  Android
     @{ */

/** Application context information required for Android application to initialize before using
    CouchbaseLite library. */
typedef struct {
    /** The directory where the opened database will be stored when a specific database
        directory is not specified in \ref CBLDatabaseConfiguration.
        @note Recommend to simply use the directory returned by the Android Context's
              getFilesDir() API or a custom subdirectory under.
        @note The specified fileDir directory must exist, otherwise an error will be returend
              when calling \r CBL_Init(). */
    const char* filesDir;
    
    /** The directory where the SQLite stores its temporary files.
        @note Recommend to create and use a temp directory under the directory returned by
              the Android Context's getFilesDir() API.
        @note The specified tempDir must exist otherwise an error will be returend
              when calling \r CBL_Init(). */
    const char* tempDir;
} CBLInitContext;

/** Initialize application context information for Android application. This function is required
    to be called the first time before using the CouchbaseLite library otherwise an error will be
    returned when calling CBLDatabase_Open to open a database. Call \r CBL_Init more than once will
    return an error.
    @param context  The application context information.
    @param outError  On failure, the error will be written here. */
bool CBL_Init(CBLInitContext context, CBLError* _cbl_nullable outError) CBLAPI;

/** @} */

#endif

CBL_CAPI_END
