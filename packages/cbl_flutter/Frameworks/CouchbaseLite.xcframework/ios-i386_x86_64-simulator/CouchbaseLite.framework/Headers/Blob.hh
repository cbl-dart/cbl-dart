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
#include "Document.hh"
#include "CBLBlob.h"
#include "fleece/Mutable.hh"

// PLEASE NOTE: This C++ wrapper API is provided as a convenience only.
// It is not considered part of the official Couchbase Lite API.

namespace cbl {
    class BlobReadStream;
    class BlobWriteStream;


    /** A reference to a binary data blob associated with a document.
        A blob's persistent form is a special dictionary in the document properties.
        To work with a blob, you construct a Blob object with that dictionary. */
    class Blob : protected RefCounted {
    public:
        static bool isBlob(fleece::Dict d)          {return CBL_IsBlob(d);}

        /* Creates a new blobgiven its contents as a single block of data.
            @note  The memory pointed to by `contents` is no longer needed after this call completes
                    (it will have been written to the database.)
            @param contentType  The MIME type (optional).
            @param contents  The data's address and length. */
        Blob(const char *contentType,
             fleece::slice contents)
        {
            _ref = (CBLRefCounted*) CBLBlob_CreateWithData(contentType, contents);
        }

        /** Creates a new blob from the data written to a \ref CBLBlobWriteStream.
            @param contentType  The MIME type (optional).
            @param writer  The blob-writing stream the data was written to. */
        inline Blob(const char *contentType,
                    BlobWriteStream& writer);

        /** Constructs a Blob instance on an existing blob reference in a document. */
        Blob(fleece::Dict d)
        :RefCounted((CBLRefCounted*) CBLBlob_Get(d))
        { }

        uint64_t length() const                     {return CBLBlob_Length(ref()); }
        const char* contentType() const             {return CBLBlob_ContentType(ref()); }
        const char* digest() const                  {return CBLBlob_Digest(ref()); }
        fleece::Dict properties() const             {return CBLBlob_Properties(ref()); }

        fleece::alloc_slice loadContent() {
            CBLError error;
            fleece::alloc_slice content = CBLBlob_LoadContent(ref(), &error);
            check(content.buf, error);
            return content;
        }

        inline BlobReadStream* openContentStream();

    protected:
        Blob(CBLRefCounted* r)                      :RefCounted(r) { }

        CBL_REFCOUNTED_BOILERPLATE(Blob, RefCounted, CBLBlob)
    };


    /** A stream for writing a new blob to the database. */
    class BlobReadStream {
    public:
        BlobReadStream(Blob *blob) {
            CBLError error;
            _stream = CBLBlob_OpenContentStream(blob->ref(), &error);
            if (!_stream) throw error;
        }

        ~BlobReadStream() {
            CBLBlobReader_Close(_stream);
        }

        size_t read(void *dst _cbl_nonnull, size_t maxLength) {
            CBLError error;
            int bytesRead = CBLBlobReader_Read(_stream, dst, maxLength, &error);
            if (bytesRead < 0)
                throw error;
            return size_t(bytesRead);
        }

    private:
        CBLBlobReadStream* _stream {nullptr};
    };


    BlobReadStream* Blob::openContentStream() {
        return new BlobReadStream(this);
    }


    /** A stream for writing a new blob to the database. */
    class BlobWriteStream {
    public:
        BlobWriteStream(Database db) {
            CBLError error;
            _writer = CBLBlobWriter_New(db.ref(), &error);
            if (!_writer) throw error;
        }

        ~BlobWriteStream() {
            CBLBlobWriter_Close(_writer);
        }

        void write(fleece::slice data) {
            CBLError error;
            if (!CBLBlobWriter_Write(_writer, data.buf, data.size, &error))
                throw error;
        }

    private:
        friend class Blob;
        CBLBlobWriteStream* _writer {nullptr};
    };


    inline Blob::Blob(const char *contentType, BlobWriteStream& writer) {
        _ref = (CBLRefCounted*) CBLBlob_CreateWithStream(contentType, writer._writer);
        writer._writer = nullptr;
    }

}
