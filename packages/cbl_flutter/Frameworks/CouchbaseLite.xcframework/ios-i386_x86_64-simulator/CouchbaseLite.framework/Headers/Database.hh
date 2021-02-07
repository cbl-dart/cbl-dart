//
// Database.hh
//
// Copyright (c) 2019 Couchbase, Inc All rights reserved.
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
#include "Base.hh"
#include "CBLDatabase.h"
#include "CBLDocument.h"
#include "CBLLog.h"
#include "CBLQuery.h"
#include "fleece/Mutable.hh"
#include <functional>
#include <string>
#include <vector>

// PLEASE NOTE: This C++ wrapper API is provided as a convenience only.
// It is not considered part of the official Couchbase Lite API.

namespace cbl {
    class Document;
    class MutableDocument;


    using SaveConflictHandler = std::function<bool(MutableDocument documentBeingSaved,
                                                   Document conflictingDocument)>;


    class Database : private RefCounted {
    public:
        // Static database-file operations:

        static bool exists(const std::string &name,
                           const std::string &inDirectory)
        {
            return CBL_DatabaseExists(name.c_str(), inDirectory.c_str());
        }

        static void copyDatabase(const std::string &fromPath,
                                 const std::string &toName)
        {
            CBLError error;
            check( CBL_CopyDatabase(fromPath.c_str(), toName.c_str(), nullptr, &error), error );
        }

        static void copyDatabase(const std::string &fromPath,
                                 const std::string &toName,
                                 const CBLDatabaseConfiguration& config)
        {
            CBLError error;
            check( CBL_CopyDatabase(fromPath.c_str(), toName.c_str(), &config, &error), error );
        }

        static void deleteDatabase(const std::string &name,
                                   const std::string &inDirectory)
        {
            CBLError error;
            if (!CBL_DeleteDatabase(name.c_str(),
                                    inDirectory.empty() ? nullptr : inDirectory.c_str(),
                                    &error) && error.code != 0)
                check(false, error);
        }

        // Lifecycle:

        Database(const std::string &name) {
            CBLError error;
            _ref = (CBLRefCounted*) CBLDatabase_Open(name.c_str(), nullptr, &error);
            check(_ref != nullptr, error);
        }

        Database(const std::string &name,
                 const CBLDatabaseConfiguration& config)
        {
            CBLError error;
            _ref = (CBLRefCounted*) CBLDatabase_Open(name.c_str(), &config, &error);
            check(_ref != nullptr, error);
        }

        void close() {
            CBLError error;
            check(CBLDatabase_Close(ref(), &error), error);
        }

        void deleteDatabase() {
            CBLError error;
            check(CBLDatabase_Delete(ref(), &error), error);
        }

        void compact()  {
            CBLError error;
            check(CBLDatabase_Compact(ref(), &error), error);
        }

        // Accessors:

        const char* name() const _cbl_nonnull               {return CBLDatabase_Name(ref());}
        const char* path() const _cbl_nonnull               {return CBLDatabase_Path(ref());}
        uint64_t count() const                              {return CBLDatabase_Count(ref());}
        CBLDatabaseConfiguration config() const             {return CBLDatabase_Config(ref());}

        // Documents:

        inline Document getDocument(const std::string &id) const;
        inline MutableDocument getMutableDocument(const std::string &id) const;

        inline Document saveDocument(MutableDocument &doc,
                                     CBLConcurrencyControl c = kCBLConcurrencyControlFailOnConflict);

        inline Document saveDocument(MutableDocument &doc, SaveConflictHandler conflictandler);

        time_t getDocumentExpiration(const std::string &docID) const {
            CBLError error;
            time_t exp = CBLDatabase_GetDocumentExpiration(ref(), docID.c_str(), &error);
            check(exp >= 0, error);
            return exp;
        }

        void setDocumentExpiration(const std::string &docID, time_t expiration) {
            CBLError error;
            check(CBLDatabase_SetDocumentExpiration(ref(), docID.c_str(), expiration, &error), error);
        }

        void purgeDocumentByID(const std::string &docID) {
            CBLError error;
            check(CBLDatabase_PurgeDocumentByID(ref(), docID.c_str(), &error), error);
        }

        // Indexes:

        void createIndex(const char *name _cbl_nonnull, CBLIndexSpec spec) {
            CBLError error;
            check(CBLDatabase_CreateIndex(ref(), name, spec, &error), error);
        }

        void deleteIndex(const char *name _cbl_nonnull) {
            CBLError error;
            check(CBLDatabase_DeleteIndex(ref(), name, &error), error);
        }

        fleece::MutableArray indexNames() {
            FLMutableArray flNames = CBLDatabase_IndexNames(ref());
            fleece::MutableArray names(flNames);
            FLMutableArray_Release(flNames);
            return names;
        }

        // Listeners:

        using Listener = cbl::ListenerToken<Database,const std::vector<const char*>&>;

        [[nodiscard]] Listener addListener(Listener::Callback f) {
            auto l = Listener(f);
            l.setToken( CBLDatabase_AddChangeListener(ref(), &_callListener, l.context()) );
            return l;
        }


        using DocumentListener = cbl::ListenerToken<Database,const char*>;

        [[nodiscard]] DocumentListener addDocumentListener(const std::string &docID,
                                                           DocumentListener::Callback f)
        {
            auto l = DocumentListener(f);
            l.setToken( CBLDatabase_AddDocumentChangeListener(ref(), docID.c_str(), &_callDocListener, l.context()) );
            return l;
        }

        // Notifications:

        using NotificationsReadyCallback = std::function<void(Database)>;

        void bufferNotifications(NotificationsReadyCallback callback) {
            auto callbackPtr = new NotificationsReadyCallback(callback);    //FIX: This is leaked
            CBLDatabase_BufferNotifications(ref(),
                                       [](void *context, CBLDatabase *db) {
                                           (*(NotificationsReadyCallback*)context)(Database(db));
                                       },
                                       callbackPtr);
        }

        void sendNotifications()                            {CBLDatabase_SendNotifications(ref());}

    private:
        static void _callListener(void *context, const CBLDatabase *db,
                                  unsigned nDocs, const char **docIDs)
        {
            std::vector<const char*> vec(&docIDs[0], &docIDs[nDocs]);
            Listener::call(context, Database((CBLDatabase*)db), vec);
        }

        static void _callDocListener(void *context, const CBLDatabase *db, const char *docID) {
            DocumentListener::call(context, Database((CBLDatabase*)db), docID);
        }

        CBL_REFCOUNTED_BOILERPLATE(Database, RefCounted, CBLDatabase)
    };


    /** A helper object used to begin and end batch operations on a Database.
        Multiple writes in a batch are more efficient than if done separately.
        A Batch object should be declared as a local (auto) variable; the batch will end
        when the object goes out of scope. */
    class Batch {
    public:
        /** Begins a batch operation on the database that will end when the Batch instance
            goes out of scope. */
        explicit Batch(Database db) {
            CBLError error;
            RefCounted::check(CBLDatabase_BeginBatch(db.ref(), &error), error);
            _db = db;
        }

        /** Ends a batch immediately. The Batch object's destructor will then do nothing. */
        void end() {
            Database db = std::move(_db);  // clears _db
            if (db) {
                CBLError error;
                if (!CBLDatabase_EndBatch(db.ref(), &error)) {
                    // If an exception is thrown while a Batch is in scope, its destructor will
                    // call end(). If I'm in this situation I cannot throw another exception or
                    // the C++ runtime will abort the process. Detect this and just warn instead.
                    if (std::current_exception())
                        CBL_Log(kCBLLogDomainDatabase, CBLLogWarning,
                                "Batch::end failed, while handling an exception");
                    else
                        RefCounted::check(false, error);
                }
            }
        }

        ~Batch() {
            end();
        }

    private:
        Database _db;
    };

}
