//
// Blob.hh
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
#include "cbl++/Document.hh"
#include "cbl/CBLBlob.h"
#include "fleece/Mutable.hh"
#include <string>

// VOLATILE API: Couchbase Lite C++ API is not finalized, and may change in
// future releases.

CBL_ASSUME_NONNULL_BEGIN

namespace cbl {
    class BlobReadStream;
    class BlobWriteStream;

    /** A reference to a binary data blob associated with a document.
        A blob's persistent form is a special dictionary in the document properties.
        To work with a blob, you construct a Blob object with that dictionary. */
    class Blob : protected RefCounted {
    public:
        /** Returns true if a dictionary in a document is a blob reference.
            @note This method tests whether the dictionary has a `@type` property,
                    whose value is `"blob"`. */
        static bool isBlob(fleece::Dict d)  {return FLDict_IsBlob(d);}

        /** Creates a new blob, given its contents as a single block of data.
            @note  The memory pointed to by `contents` is no longer needed after this call completes
                    (it will have been written to the database.)
            @param contentType  The MIME type (optional).
            @param contents  The data's address and length. */
        Blob(slice contentType, slice contents) {
            _ref = (CBLRefCounted*) CBLBlob_CreateWithData(contentType, contents);
        }

        /** Creates a new blob from the data written to a \ref CBLBlobWriteStream.
            @param contentType  The MIME type (optional).
            @param writer  The blob-writing stream the data was written to. */
        inline Blob(slice contentType, BlobWriteStream& writer);

        /** Creates a Blob instance on an existing blob reference in a document or query result.
            @note If the dict argument is not actually a blob reference, this Blob object will be
            invalid; you can check that by calling its `valid` method or testing it with its
            `operator bool`. */
        Blob(fleece::Dict d) 
        :RefCounted((CBLRefCounted*) FLDict_GetBlob(d))
        { }

        /** Returns the length in bytes of a blob's content (from its `length` property). */
        uint64_t length() const                     {return CBLBlob_Length(ref());}
        
        /** Returns a blob's MIME type, if its metadata has a `content_type` property. */
        std::string contentType() const             {return asString(CBLBlob_ContentType(ref()));}
        
        /** Returns the cryptographic digest of a blob's content (from its `digest` property). */
        std::string digest() const                  {return asString(CBLBlob_Digest(ref()));}
        
        /** Returns a blob's metadata. This includes the `digest`, `length`, `content_type`,
            and `@type` properties, as well as any custom ones that may have been added. */
        fleece::Dict properties() const             {return CBLBlob_Properties(ref());}

        // Allows Blob to be assigned to mutable Dict/Array item, e.g. `dict["foo"] = blob`
        operator fleece::Dict() const               {return properties();}

        /** Reads the blob's content into memory and returns them. */
        alloc_slice loadContent() {
            CBLError error;
            fleece::alloc_slice content = CBLBlob_Content(ref(), &error);
            check(content.buf, error);
            return content;
        }

        /** Opens a stream for reading a blob's content. */
        inline BlobReadStream* openContentStream();

    protected:
        Blob(CBLRefCounted* r)                      :RefCounted(r) { }

        CBL_REFCOUNTED_BOILERPLATE(Blob, RefCounted, CBLBlob)
    };

    /** A stream for writing a new blob to the database. */
    class BlobReadStream {
    public:
        /** Opens a stream for reading a blob's content. */
        BlobReadStream(Blob *blob) {
            CBLError error;
            _stream = CBLBlob_OpenContentStream(blob->ref(), &error);
            if (!_stream) throw error;
        }
        
        ~BlobReadStream() {
            CBLBlobReader_Close(_stream);
        }

        /** Reads data from a blob.
            @param dst  The address to copy the read data to.
            @param maxLength  The maximum number of bytes to read.
            @return The actual number of bytes read; 0 if at EOF. */
        size_t read(void *dst, size_t maxLength) {
            CBLError error;
            int bytesRead = CBLBlobReader_Read(_stream, dst, maxLength, &error);
            if (bytesRead < 0)
                throw error;
            return size_t(bytesRead);
        }

    private:
        CBLBlobReadStream* _cbl_nullable _stream {nullptr};
    };

    BlobReadStream* Blob::openContentStream() {
        return new BlobReadStream(this);
    }

    /** A stream for writing a new blob to the database. */
    class BlobWriteStream {
    public:
        /** Create a stream to write a new blob to the database. */
        BlobWriteStream(Database db) {
            CBLError error;
            _writer = CBLBlobWriter_Create(db.ref(), &error);
            if (!_writer) throw error;
        }

        ~BlobWriteStream() {
            CBLBlobWriter_Close(_writer);
        }

        /** Writes data to a new blob.
            @param data  The data to write. */
        void write(fleece::slice data) {
            write(data.buf, data.size);
        }

        /** Writes data to a new blob.
            @param src  The address of the data to write.
            @param length  The length of the data to write. */
        void write(const void *src, size_t length) {
            CBLError error;
            if (!CBLBlobWriter_Write(_writer, src, length, &error))
                throw error;
        }

    private:
        friend class Blob;
        CBLBlobWriteStream* _cbl_nullable _writer {nullptr};
    };

    inline Blob::Blob(slice contentType, BlobWriteStream& writer) {
        _ref = (CBLRefCounted*) CBLBlob_CreateWithStream(contentType, writer._writer);
        writer._writer = nullptr;
    }
}

CBL_ASSUME_NONNULL_END
