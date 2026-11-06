//
// Collection.hh
//
// Copyright (c) 2022 Couchbase, Inc All rights reserved.
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
#include "cbl++/Base.hh"
#include "cbl++/Database.hh"
#include "cbl/CBLCollection.h"
#include "cbl/CBLScope.h"
#include "fleece/Mutable.hh"
#include <functional>
#include <string>
#include <vector>


CBL_ASSUME_NONNULL_BEGIN

namespace cbl {
    class Document;
    class MutableDocument;
    class CollectionChange;
    class DocumentChange;
    class QueryIndex;
    class VectorIndexConfiguration;

    /** Conflict handler used when saving a document. */
    using CollectionConflictHandler  = std::function<bool(MutableDocument documentBeingSaved,
                                                          Document conflictingDocument)>;
    /** Configuration for creating a value index, which indexes the values of one or more
        document properties. */
    struct ValueIndexConfiguration {
        /** The language used in the expressions (Required). */
        QueryLanguage expressionLanguage;

        /** The expressions describing each column of the index (Required).
            The expressions could be specified in a JSON Array or in N1QL syntax
            using comma delimiter, depending on expressionLanguage. */
        std::string expressions;

        /** A predicate expression defining conditions for indexing documents.
            Only documents satisfying the predicate are included, enabling partial indexes.
            The expression can be JSON or N1QL/SQL++ syntax, depending on expressionLanguage. */
        std::string where;
    };

    /** Configuration for creating a full-text index, which enables full-text search in queries. */
    struct FullTextIndexConfiguration {
        /** The language used in the expressions (Required). */
        QueryLanguage expressionLanguage;

        /** The expressions describing each coloumn of the index (Required).
            The expressions could be specified in a JSON Array or in N1QL syntax
            using comma delimiter, depending on expressionLanguage. */
        std::string expressions;

        /** Should diacritical marks (accents) be ignored?
            Defaults to  \ref kCBLDefaultFullTextIndexIgnoreAccents.
            Generally this should be left `false` for non-English text. */
        bool ignoreAccents;

        /** The dominant language. Setting this enables word stemming, i.e.
            matching different cases of the same word ("big" and "bigger", for instance) and ignoring
            common "stop-words" ("the", "a", "of", etc.)

            Can be an ISO-639 language code or a lowercase (English) language name; supported
            languages are: da/danish, nl/dutch, en/english, fi/finnish, fr/french, de/german,
            hu/hungarian, it/italian, no/norwegian, pt/portuguese, ro/romanian, ru/russian,
            es/spanish, sv/swedish, tr/turkish.

            If left null,  or set to an unrecognized language, no language-specific behaviors
            such as stemming and stop-word removal occur. */
        std::string language;

        /** A predicate expression defining conditions for indexing documents.
            Only documents satisfying the predicate are included, enabling partial indexes.
            The expression can be JSON or N1QL/SQL++ syntax, depending on expressionLanguage. */
        std::string where;
    };

    /** Array Index Configuration for indexing property values within arrays
        in documents, intended for use with the UNNEST query. */
    struct ArrayIndexConfiguration {
        /** The language used in the expressions (Required). */
        QueryLanguage expressionLanguage;

        /** Path to the array, which can be nested to be indexed (Required).
            Use "[]" to represent a property that is an array of each nested array level.
            For a single array or the last level array, the "[]" is optional. For instance,
            use "contacts[].phones" to specify an array of phones within each contact. */
        std::string path;

        /** Optional expressions representing the values within the array to be
            indexed. The expressions could be specified in a JSON Array or in N1QL syntax
            using comma delimiter, depending on expressionLanguage.
            If the array specified by the path contains scalar values, the expressions
            should be left unset or set to null. */
        std::string expressions;
    };

    /**
     A Collection is a container for documents within a database.
     A collection can be thought as a table in the relational database. Each collection belongs to
     a scope which is simply a namespce, and has a name which is unique within its scope.
     
     When a new database is created, a default collection named "_default" will be automatically
     created. The default collection is created under the default scope named "_default".
     You may decide to delete the default collection, but noted that the default collection cannot
     be re-created. The name of the default collection and scope can be referenced by using
     \ref kCBLDefaultCollectionName and \ref kCBLDefaultScopeName constant.
 
     When creating a new collection, the collection name, and the scope name are required.
     The naming rules of the collections and scopes are as follows:
     - Must be between 1 and 251 characters in length.
     - Can only contain the characters A-Z, a-z, 0-9, and the symbols _, -, and %.
     - Cannot start with _ or %.
     - Both scope and collection names are case sensitive. */
    class Collection : private RefCounted {
    public:
        // Accessors:
        
        /** The collection's name. */
        std::string name() const                        {return internal::asString(CBLCollection_Name(ref()));}
        
        /** The collection's fully qualified name in the '<scope-name>.<collection-name>' format. */
        std::string fullName() const                    {return internal::asString(CBLCollection_FullName(ref()));}
        
        /** The scope's name. */
        std::string scopeName() const {
            auto scope = CBLCollection_Scope(ref());
            auto scopeName = internal::asString(CBLScope_Name(scope));
            CBLScope_Release(scope);
            return scopeName;
        }
        
        /** The collection's database.  */
        Database database() const                       {return Database(CBLCollection_Database(ref()));}
        
        /** The number of documents in the collection. */
        uint64_t count() const                          {return CBLCollection_Count(ref());}
        
        // Documents:
        
        /** Reads a document from the collection in an immutable form.
            @note If you are reading the document in order to make changes to it, call \ref Collection::getMutableDocument() instead.
            @param docID  The ID of the document.
            @return A new \ref Document instance, or a falsy Document if the doc doesn't exist.
            @throws cbl::Error  On a database error. Note a non-existent document is not an
                    error — that returns a falsy Document rather than throwing. */
        inline Document getDocument(std::string_view docID) const;
        
        /** Reads a document from the collection in mutable form that can be updated and saved.
            (This function is otherwise identical to \ref Collection::getDocument.)
            @param docID  The ID of the document.
            @return A new \ref Document instance, or a falsy Document if the doc doesn't exist.
            @throws cbl::Error  On a database error. Note a non-existent document is not an
                    error — that returns a falsy Document rather than throwing. */
        inline MutableDocument getMutableDocument(std::string_view docID) const;

        /** Saves a (mutable) document to the collection.
            @warning If a newer revision has been saved since \p doc was loaded, it will be overwritten by
                    this one. This can lead to data loss! To avoid this, call
                    \ref Collection::saveDocument(MutableDocument &doc, CBLConcurrencyControl concurrency)
                    \ref Collection::saveDocument(MutableDocument &doc, ConflictHandler handler) instead.
            @param doc  The mutable document to save. */
        inline void saveDocument(MutableDocument &doc);

        /** Saves a (mutable) document to the collection.
            If a conflicting revision has been saved since \p doc was loaded, the \p concurrency
            parameter specifies whether the save should fail, or the conflicting revision should
            be overwritten with the revision being saved.
            If you need finer-grained control, call \ref Collection::saveDocument(MutableDocument &doc, ConflictHandler handler) instead.
            @param doc  The mutable document to save.
            @param concurrency  Conflict-handling strategy (fail or overwrite).
            @return True on success, false on failure. */
        _cbl_warn_unused
        inline bool saveDocument(MutableDocument &doc, CBLConcurrencyControl concurrency);

        /** Saves a (mutable) document to the collection, allowing for custom conflict handling in the event
            that the document has been updated since \p doc was loaded.
            @param doc  The mutable document to save.
            @param handler  The callback to be invoked if there is a conflict.
            @return True on success, false on failure. */
        _cbl_warn_unused
        inline bool saveDocument(MutableDocument &doc, CollectionConflictHandler handler);

        /** Deletes a document from the collection. Deletions are replicated.
            @param doc  The document to delete. */
        inline void deleteDocument(Document &doc);

        /** Deletes a document from the collection. Deletions are replicated.
            @param doc  The document to delete.
            @param concurrency  Conflict-handling strategy.
            @return True on success, false on failure. */
        _cbl_warn_unused
        inline bool deleteDocument(Document &doc, CBLConcurrencyControl concurrency);

        /** Purges a document from the collection. This removes all traces of the document.
            Purges are _not_ replicated. If the document is changed on a server, it will be re-created
            when pulled.
            @note If you don't have the document in memory already, \ref purgeDocument(std::string_view docID) is a simpler shortcut.
            @param doc  The document to purge. */
        inline void purgeDocument(Document &doc);

        /** Purges a document by its ID from the collection.
            @param docID  The document ID to purge.
            @return True if the document was purged, false if it doesn't exist. */
        bool purgeDocument(std::string_view docID) {
            CBLError error;
            bool purged = CBLCollection_PurgeDocumentByID(ref(), slice(docID), &error);
            if ( !purged && !(error.domain == kCBLDomain && error.code == kCBLErrorNotFound) )
                internal::check(false, error);
            return purged;
        }
        
        /** Returns the time, if any, at which a given document in the collection will expire and be purged.
            Documents don't normally expire; you have to call \ref Collection::setDocumentExpiration(std::string_view docID, time_t expiration)
            to set a document's expiration time.
            @param docID  The ID of the document.
            @return The expiration time as a CBLTimestamp (milliseconds since Unix epoch),
                  or 0 if the document does not have an expiration. */
        time_t getDocumentExpiration(std::string_view docID) const {
            CBLError error;
            time_t exp = CBLCollection_GetDocumentExpiration(ref(), slice(docID), &error);
            internal::check(exp >= 0, error);
            return exp;
        }

        /** Sets or clears the expiration time of a document in the collection.
            @param docID  The ID of the document.
            @param expiration  The expiration time as a CBLTimestamp (milliseconds since Unix epoch),
                              or 0 if the document should never expire. */
        void setDocumentExpiration(std::string_view docID, time_t expiration) {
            CBLError error;
            internal::check(CBLCollection_SetDocumentExpiration(ref(), slice(docID), expiration, &error), error);
        }

        // Indexes:

        /** Creates a value index in the collection.
            Indexes are persistent.
            If an identical index with that name already exists, nothing happens (and no error is returned.)
            If a non-identical index with that name already exists, it is deleted and re-created.
            @param name  The index name.
            @param config  The value index config. */
        void createValueIndex(std::string_view name, ValueIndexConfiguration config) {
            CBLError error;
            internal::check(CBLCollection_CreateValueIndex(ref(), slice(name), {
                config.expressionLanguage,
                slice(config.expressions),
                slice(config.where)
            }, &error), error);
        }
        
        /** Creates a full-text index in the collection.
            Indexes are persistent.
            If an identical index with that name already exists, nothing happens (and no error is returned.)
            If a non-identical index with that name already exists, it is deleted and re-created.
            @param name  The index name.
            @param config  The full-text index config. */
        void createFullTextIndex(std::string_view name, FullTextIndexConfiguration config) {
            CBLError error;
            internal::check(CBLCollection_CreateFullTextIndex(ref(), slice(name), {
                config.expressionLanguage,
                slice(config.expressions),
                config.ignoreAccents,
                slice(config.language),
                slice(config.where)
            }, &error), error);
        }

        /** Creates an array index for use with UNNEST queries in the collection.
            Indexes are persistent.
            If an identical index with that name already exists, nothing happens (and no error is returned.)
            If a non-identical index with that name already exists, it is deleted and re-created.
            @param name  The index name.
            @param config  The array index config. */
        void createArrayIndex(std::string_view name, ArrayIndexConfiguration config) {
            CBLError error;
            internal::check(CBLCollection_CreateArrayIndex(ref(), slice(name), {
                config.expressionLanguage,
                slice(config.path),
                slice(config.expressions)
            }, &error), error);
        }

#ifdef COUCHBASE_ENTERPRISE
        /** Creates a vector index in the collection.
            If an identical index with that name already exists, nothing happens (and no error is returned.)
            If a non-identical index with that name already exists, it is deleted and re-created.
            \note ENTERPRISE EDITION ONLY
            @param name  The index name.
            @param config  The vector index config. */
        inline void createVectorIndex(std::string_view name, VectorIndexConfiguration config);
#endif

        /** Deletes an index given its name from the collection. */
        void deleteIndex(std::string_view name) {
            CBLError error;
            internal::check(CBLCollection_DeleteIndex(ref(), slice(name), &error), error);
        }

        /** Returns the names of the indexes in the collection, as a Fleece array of strings. */
        fleece::RetainedArray getIndexNames() {
            CBLError error{};
            FLMutableArray flNames = CBLCollection_GetIndexNames(ref(), &error);
            internal::check(error.code == 0, error);
            fleece::RetainedArray names(flNames);
            FLArray_Release(flNames);
            return names;
        }
        
        /** Get an index by name. If the index doesn't exist, a falsy QueryIndex object will be returned. */
        inline QueryIndex getIndex(std::string_view name);
        
        // Listeners:
        
        /** Collection Change Listener Token */
        using CollectionChangeListener = cbl::ListenerToken<CollectionChange*>;

        /** Registers a collection change listener callback. It will be called after one or more
            documents in the collection are changed on disk.
            @param callback  The callback to be invoked.
            @return A Change Listener Token. Call \ref ListenerToken::remove() method to remove the listener. */
        [[nodiscard]] CollectionChangeListener addChangeListener(CollectionChangeListener::Callback callback) {
            auto l = CollectionChangeListener(callback);
            l.setToken( CBLCollection_AddChangeListener(ref(), &_callListener, l.context()) );
            return l;
        }

        /** Document Change Listener Token */
        using CollectionDocumentChangeListener = cbl::ListenerToken<DocumentChange*>;

        /** Registers a document change listener callback. It will be called after a specific document in the collection
            is changed on disk.
            @param docID  The ID of the document to observe.
            @param callback  The callback to be invoked.
            @return A Change Listener Token. Call \ref ListenerToken::remove() method to remove the listener. */
        [[nodiscard]] CollectionDocumentChangeListener addDocumentChangeListener(std::string_view docID,
                                                                                 CollectionDocumentChangeListener::Callback callback)
        {
            auto l = CollectionDocumentChangeListener(callback);
            l.setToken( CBLCollection_AddDocumentChangeListener(ref(), slice(docID), &_callDocListener, l.context()) );
            return l;
        }
        
    protected:

        static Collection adopt(const CBLCollection* _cbl_nullable d, CBLError *error) {
            internal::check(d != nullptr || error->code == 0, *error);
            Collection col;
            col._ref = (CBLRefCounted*)d;
            return col;
        }
        
        friend class Database;
        friend class Document;
        friend class QueryIndex;
        
        CBL_REFCOUNTED_BOILERPLATE(Collection, RefCounted, CBLCollection);
    
    private:
        
        static void _callListener(void* _cbl_nullable context, const CBLCollectionChange* change);

        static void _callDocListener(void* _cbl_nullable context, const CBLDocumentChange* change);
    };

    /** Collection change info notified to the collection change listener's callback. */
    class CollectionChange {
    public:
        /** The collection. */
        Collection& collection()                    {return _collection;}
        
        /** The IDs of the changed documents. */
        std::vector<slice>& docIDs()                {return _docIDs;}
        
        /** Internal API. */
        CollectionChange(Collection collection, std::vector<slice> docIDs)
        :_collection(std::move(collection))
        ,_docIDs(std::move(docIDs))
        { }

    private:
        
        Collection _collection;
        std::vector<slice> _docIDs;
    };

    /** Document change info notified to the document change listener's callback. */
    class DocumentChange {
    public:
        /** The collection. */
        Collection& collection()                    {return _collection;}
        
        /** The ID of the changed document. */
        slice& docID()                              {return _docID;}

        /** Internal API. */
        DocumentChange(Collection collection, std::string_view docID)
        :_collection(std::move(collection))
        ,_docID(slice(docID))
        { }
        
    private:
        
        Collection _collection;
        slice _docID;
    };

    // Database method bodies:

    inline Collection Database::getCollection(std::string_view collectionName, std::optional<std::string_view> optScopeName) const {
        CBLError error {};
        slice scopeName = optScopeName.value_or(slice(kCBLDefaultScopeName));
        return Collection::adopt(CBLDatabase_Collection(ref(), slice(collectionName), slice(scopeName), &error), &error) ;
    }

    inline Collection Database::createCollection(std::string_view collectionName, std::optional<std::string_view> optScopeName) {
        CBLError error {};
        slice scopeName = optScopeName.value_or(slice(kCBLDefaultScopeName));
        return Collection::adopt(CBLDatabase_CreateCollection(ref(), slice(collectionName), scopeName, &error), &error) ;
    }

    inline Collection Database::getDefaultCollection() const {
        CBLError error {};
        return Collection::adopt(CBLDatabase_DefaultCollection(ref(), &error), &error) ;
    }

    // Collection method bodies:

    inline void Collection::_callListener(void* _cbl_nullable context, const CBLCollectionChange* change) {
        Collection col = Collection((CBLCollection*)change->collection);
        std::vector<slice> docIDs((slice*)&change->docIDs[0], (slice*)&change->docIDs[change->numDocs]);
        auto ch = std::make_unique<CollectionChange>(col, docIDs);
        CollectionChangeListener::call(context, ch.get());
    }

    inline void Collection::_callDocListener(void* _cbl_nullable context, const CBLDocumentChange* change) {
        Collection col = Collection((CBLCollection*)change->collection);
        slice docID = change->docID;
        auto ch = std::make_unique<DocumentChange>(col, docID);
        CollectionDocumentChangeListener::call(context, ch.get());
    }
}

/** Hash function for Collection. */
template<> struct std::hash<cbl::Collection> {
    std::size_t operator() (cbl::Collection const& col) const {
        auto name = CBLCollection_Name(col.ref());
        auto scope = CBLCollection_Scope(col.ref());
        std::size_t hash = fleece::slice(name).hash() ^ fleece::slice(CBLScope_Name(scope)).hash();
        CBLScope_Release(scope);
        return hash;
    }
};

CBL_ASSUME_NONNULL_END
