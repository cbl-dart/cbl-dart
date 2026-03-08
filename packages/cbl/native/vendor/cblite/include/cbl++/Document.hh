//
// Document.hh
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
#include "cbl++/Collection.hh"
#include "cbl++/Database.hh"
#include "cbl/CBLDocument.h"
#include "fleece/Mutable.hh"
#include <string>

// VOLATILE API: Couchbase Lite C++ API is not finalized, and may change in
// future releases.

CBL_ASSUME_NONNULL_BEGIN

namespace cbl {
    class MutableDocument;

    /** Immutable Document. */
    class Document : protected RefCounted {
    public:
        // Metadata:

        /** A document's ID */
        std::string id() const                     {return asString(CBLDocument_ID(ref()));}

        /** A document's revision ID, which is a short opaque string that's guaranteed to be unique to every change made to
            the document. If the document doesn't exist yet, this function returns an empty string.  */
        std::string revisionID() const             {return asString(CBLDocument_RevisionID(ref()));}

        /** A document's current sequence in the local database.
            This number increases every time the document is saved, and a more recently saved document
            will have a greater sequence number than one saved earlier, so sequences may be used as an
            abstract 'clock' to tell relative modification times. */
        uint64_t sequence() const                  {return CBLDocument_Sequence(ref());}
        
        /** A document's collection or NULL for the new document that hasn't been saved. */
        Collection collection() const              {return Collection(CBLDocument_Collection(ref()));}

        // Properties:

        /** A document's properties as an immutable dictionary. */
        fleece::Dict properties() const            {return CBLDocument_Properties(ref());}

        /** A document's properties as JSON. */
        alloc_slice propertiesAsJSON() const       {return alloc_slice(CBLDocument_CreateJSON(ref()));}

        /** A subscript operator to access a document's property value by key. */
        fleece::Value operator[] (slice key) const {return properties()[key];}

        // Operations:
        
        /** Creates a new mutable Document instance that refers to the same document as the original.
            If the original document has unsaved changes, the new one will also start out with the same
            changes; but mutating one document thereafter will not affect the other. */
        inline MutableDocument mutableCopy() const;

    protected:
        friend class Collection;
        friend class Database;
        friend class Replicator;
        
        Document(CBLRefCounted* r)                  :RefCounted(r) { }

        static Document adopt(const CBLDocument* _cbl_nullable d, CBLError *error) {
            if (!d && error->code != 0)
                throw *error;
            Document doc;
            doc._ref = (CBLRefCounted*)d;
            return doc;
        }

        static bool checkSave(bool saveResult, CBLError &error) {
            if (saveResult)
                return true;
            else if (error.code == kCBLErrorConflict && error.domain == kCBLDomain)
                return false;
            else
                throw error;
        }
        
        CBL_REFCOUNTED_BOILERPLATE(Document, RefCounted, const CBLDocument)
    };


    /** Mutable Document. */
    class MutableDocument : public Document {
    public:
        /** Creates a new, empty document in memory, with a randomly-generated unique ID.
            It will not be added to a database until saved. */
        explicit MutableDocument(nullptr_t)             {_ref = (CBLRefCounted*)CBLDocument_CreateWithID(fleece::nullslice);}
        
        /** Creates a new, empty document in memory, with the given ID.
            It will not be added to a database until saved.
            @note If the given ID conflicts with a document already in the database, that will not
                  be apparent until this document is saved. At that time, the result depends on the
                  conflict handling mode used when saving; see the save functions for details.
            @param docID  The ID of the new document, or NULL to assign a new unique ID. */
        explicit MutableDocument(slice docID)           {_ref = (CBLRefCounted*)CBLDocument_CreateWithID(docID);}

        /** Returns a mutable document's properties as a mutable dictionary.
            You may modify this dictionary and then call \ref Collection::saveDocument(MutableDocument &doc) to persist the changes.
            @note  When accessing nested collections inside the properties as a mutable collection
                   for modification, use \ref MutableDict::getMutableDict() or \ref MutableDict::getMutableArray() */
        fleece::MutableDict properties()                {return CBLDocument_MutableProperties(ref());}

        /** Sets a property key and value.
            Call \ref Collection::saveDocument(MutableDocument &doc) to persist the changes. */
        template <typename V>
        void set(slice key, const V &val)               {properties().set(key, val);}
        
        /** Sets a property key and value.
            Call \ref Collection::saveDocument(MutableDocument &doc) to persist the changes. */
        template <typename K, typename V>
        void set(const K &key, const V &val)            {properties().set(key, val);}

        /** A subscript operator to access a document's property value by key for either getting or setting the value.
            Call \ref Collection::saveDocument(MutableDocument &doc) to persist the changes. */
        fleece::keyref<fleece::MutableDict,fleece::slice> operator[] (slice key)
                                                        {return properties()[key];}

        /** Sets a mutable document's properties.
            Call \ref Collection::saveDocument(MutableDocument &doc) to persist the changes.
            @param properties  The document properties. */
        void setProperties(fleece::MutableDict properties) {
            CBLDocument_SetProperties(ref(), properties);
        }

        /** Sets a mutable document's properties.
            Call \ref Collection::saveDocument(MutableDocument &doc) to persist the changes.
            @param properties  The document properties. */
        void setProperties(fleece::Dict properties) {
            CBLDocument_SetProperties(ref(), properties.mutableCopy());
        }

        /** Sets a mutable document's properties from a JSON Dictionary string.
            Call \ref Collection::saveDocument(MutableDocument &doc) to persist the changes.
            @param json  A JSON Dictionaryt string */
        void setPropertiesAsJSON(slice json) {
            CBLError error;
            if (!CBLDocument_SetJSON(ref(), json, &error))
                throw error;
        }

    protected:
        static MutableDocument adopt(CBLDocument* _cbl_nullable d, CBLError *error) {
            if (!d && error->code != 0)
                throw *error;            
            MutableDocument doc;
            doc._ref = (CBLRefCounted*)d;
            return doc;
        }

        friend class Collection;
        friend class Database;
        friend class Document;
        CBL_REFCOUNTED_BOILERPLATE(MutableDocument, Document, CBLDocument)
    };
    
    // Document method bodies:

    inline MutableDocument Document::mutableCopy() const {
        MutableDocument doc;
        doc._ref = (CBLRefCounted*) CBLDocument_MutableCopy(ref());
        return doc;
    }

    // Collection method bodies:

    inline Document Collection::getDocument(slice id) const {
        CBLError error;
        return Document::adopt(CBLCollection_GetDocument(ref(), id, &error), &error);
    }

    inline MutableDocument Collection::getMutableDocument(slice id) const {
        CBLError error;
        return MutableDocument::adopt(CBLCollection_GetMutableDocument(ref(), id, &error), &error);
    }

    inline void Collection::saveDocument(MutableDocument &doc) {
        (void) saveDocument(doc, kCBLConcurrencyControlLastWriteWins);
    }

    inline bool Collection::saveDocument(MutableDocument &doc, CBLConcurrencyControl c) {
        CBLError error;
        return Document::checkSave(
            CBLCollection_SaveDocumentWithConcurrencyControl(ref(), doc.ref(), c, &error), error);
    }

    inline bool Collection::saveDocument(MutableDocument &doc, CollectionConflictHandler conflictHandler) {
        CBLConflictHandler cHandler = [](void *context, CBLDocument *myDoc,
                                         const CBLDocument *otherDoc) -> bool {
            return (*(CollectionConflictHandler*)context)(MutableDocument(myDoc),
                                                Document(otherDoc));
        };
        CBLError error;
        return Document::checkSave(
            CBLCollection_SaveDocumentWithConflictHandler(ref(), doc.ref(), cHandler,
                                                          &conflictHandler, &error), error);
    }

    inline void Collection::deleteDocument(Document &doc) {
        (void) deleteDocument(doc, kCBLConcurrencyControlLastWriteWins);
    }

    inline bool Collection::deleteDocument(Document &doc, CBLConcurrencyControl cc) {
        CBLError error;
        return Document::checkSave(
            CBLCollection_DeleteDocumentWithConcurrencyControl(ref(), doc.ref(), cc, &error), error);
    }

    inline void Collection::purgeDocument(Document &doc) {
        CBLError error;
        check(CBLCollection_PurgeDocument(ref(), doc.ref(), &error), error);
    }

    // Database method bodies:

    inline Document Database::getDocument(slice id) const {
        CBLError error;
        return Document::adopt(CBLDatabase_GetDocument(ref(), id, &error), &error);
    }

    inline MutableDocument Database::getMutableDocument(slice id) const {
        CBLError error;
        return MutableDocument::adopt(CBLDatabase_GetMutableDocument(ref(), id, &error), &error);
    }

    inline void Database::saveDocument(MutableDocument &doc) {
        (void) saveDocument(doc, kCBLConcurrencyControlLastWriteWins);
    }

    inline bool Database::saveDocument(MutableDocument &doc, CBLConcurrencyControl c) {
        CBLError error;
        return Document::checkSave(
            CBLDatabase_SaveDocumentWithConcurrencyControl(ref(), doc.ref(), c, &error),
            error);
    }

    inline bool Database::saveDocument(MutableDocument &doc,
                                       ConflictHandler conflictHandler)
    {
        CBLConflictHandler cHandler = [](void *context, CBLDocument *myDoc,
                                             const CBLDocument *otherDoc) -> bool {
            return (*(ConflictHandler*)context)(MutableDocument(myDoc),
                                                    Document(otherDoc));
        };
        CBLError error;
        return Document::checkSave(
            CBLDatabase_SaveDocumentWithConflictHandler(ref(), doc.ref(), cHandler, &conflictHandler, &error),
            error);
    }

    inline void Database::deleteDocument(Document &doc) {
        (void) deleteDocument(doc, kCBLConcurrencyControlLastWriteWins);
    }

    inline bool Database::deleteDocument(Document &doc, CBLConcurrencyControl cc) {
        CBLError error;
        return Document::checkSave(CBLDatabase_DeleteDocumentWithConcurrencyControl(
                                                                    ref(), doc.ref(), cc, &error),
                                   error);
    }

    inline void Database::purgeDocument(Document &doc) {
        CBLError error;
        check(CBLDatabase_PurgeDocument(ref(), doc.ref(), &error), error);
    }
}

CBL_ASSUME_NONNULL_END
