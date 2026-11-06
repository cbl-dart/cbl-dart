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
#include "cbl++/Base.hh"
#include "cbl++/Document.hh"
#include "cbl/CBLBlob.h"
#include "cbl/CBLDatabase.h"
#include "fleece/Mutable.hh"
#include <optional>
#include <string>
#include <string_view>


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
        Blob(std::optional<std::string_view> contentType, slice contents) {
            slice ctype;
            if ( contentType ) ctype = slice(*contentType);
            _ref = (CBLRefCounted*) CBLBlob_CreateWithData(ctype, contents);
        }

        /** Creates a new blob from the data written to a \ref CBLBlobWriteStream.
            @param contentType  The MIME type (optional).
            @param writer  The blob-writing stream the data was written to. */
        inline Blob(std::optional<std::string_view> contentType, BlobWriteStream& writer);

        /** Creates a Blob instance on an existing blob reference in a document or query result.
            @note If the dict argument is not actually a blob reference, this Blob object will be
            invalid; you can check that by calling its `valid` method or testing it with its
            `operator bool`. */
        Blob(fleece::Dict d) 
        :RefCounted((CBLRefCounted*) FLDict_GetBlob(d))
        { }

        /** Compares whether this blob and another are equal based on their content. */
        bool blobEquals(const Blob& other) const    {return CBLBlob_Equals(ref(), other.ref());}

        /** Returns the length in bytes of a blob's content (from its `length` property). */
        uint64_t length() const                     {return CBLBlob_Length(ref());}
        
        /** Returns a blob's MIME type, if its metadata has a `content_type` property. */
        std::string contentType() const             {return internal::asString(CBLBlob_ContentType(ref()));}
        
        /** Returns the cryptographic digest of a blob's content (from its `digest` property). */
        std::string digest() const                  {return internal::asString(CBLBlob_Digest(ref()));}
        
        /** Returns a blob's metadata. This includes the `digest`, `length`, `content_type`,
            and `@type` properties, as well as any custom ones that may have been added. */
        fleece::Dict properties() const             {return CBLBlob_Properties(ref());}

        /** Returns the JSON representation of the blob's metadata dictionary. */
        std::string createJSON() const              {return alloc_slice(CBLBlob_CreateJSON(ref())).asString();}

        /** Implicit conversion to the blob's underlying Fleece dictionary.
            This lets a Blob be assigned to a mutable Dict/Array item, e.g. `dict["foo"] = blob`. */
        operator fleece::Dict() const               {return properties();}

        /** Reads the blob's content into memory and returns it.
            @note  This loads the whole blob at once. For large blobs, prefer
                   \ref openContentStream to read the content incrementally.
            @return  The blob's content as an \ref alloc_slice that owns the loaded bytes.
            @throws cbl::Error  If the content cannot be read (for example, the blob's
                    data is not available in the database). */
        alloc_slice loadContent() {
            CBLError error;
            fleece::alloc_slice content = CBLBlob_Content(ref(), &error);
            internal::check(content.buf, error);
            return content;
        }

        /** Opens a stream for reading a blob's content.
            @note  The caller takes ownership of the returned stream and must `delete` it
                   (e.g. wrap it in a `std::unique_ptr<BlobReadStream>`).
            @return  A new \ref BlobReadStream positioned at the start of the blob's content. */
        inline BlobReadStream* openContentStream();

    protected:

        CBL_REFCOUNTED_BOILERPLATE(Blob, RefCounted, CBLBlob)

    private:
        friend class Database;
        struct adopt_t {};
        inline static constexpr adopt_t adopt{};

        Blob(CBLBlob* _cbl_nullable cObj, adopt_t) { _ref = (CBLRefCounted*)cObj; }
    };

    /** A stream for reading a blob's content from the database. */
    class BlobReadStream {
    public:
        /** Alias for the C \ref CBLSeekBase enum describing the reference point used by \ref seek. */
        using SeekBase = CBLSeekBase;

        /** Opens a stream for reading a blob's content.
            @param blob  The blob whose content will be read. */
        BlobReadStream(Blob *blob) {
            CBLError error;
            _stream = CBLBlob_OpenContentStream(blob->ref(), &error);
            internal::check(_stream, error);
        }

        /** Closes the underlying read stream. */
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
            internal::check(bytesRead >= 0, error);
            return size_t(bytesRead);
        }

        /** Sets the position of a CBLBlobReadStream.
            @param offset  The byte offset in the stream (relative to the `mode`).
            @param base    The base position from which the offset is calculated.
            @return  The new absolute position, or throw on failure. */
        int64_t seek(int64_t offset, SeekBase base) {
            CBLError error{};
            int64_t ret = CBLBlobReader_Seek(_stream, offset, base, &error);
            internal::check(ret >= 0, error);
            return ret;
        }

        /** Returns the current position of a CBLBlobReadStream. */
        uint64_t position() {
            return CBLBlobReader_Position(_stream);
        }

    private:
        CBLBlobReadStream* _cbl_nullable _stream {nullptr};
    };

    inline BlobReadStream* Blob::openContentStream() {
        return new BlobReadStream(this);
    }

    /** A stream for writing a new blob to the database. */
    class BlobWriteStream {
    public:
        /** Create a stream to write a new blob to the database. */
        BlobWriteStream(Database db) {
            CBLError error;
            _writer = CBLBlobWriter_Create(db.ref(), &error);
            internal::check(_writer, error);
        }

        /** Closes the blob-writing stream if it has not been handed off to a \ref Blob
            constructor. Safe to call after the stream has been consumed by a Blob. */
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
                internal::check(false, error);
        }

    private:
        friend class Blob;
        CBLBlobWriteStream* _cbl_nullable _writer {nullptr};
    };

    inline Blob::Blob(std::optional<std::string_view> contentType, BlobWriteStream& writer) {
        slice ctype;
        if ( contentType ) ctype = slice(*contentType);
        _ref = (CBLRefCounted*) CBLBlob_CreateWithStream(ctype, writer._writer);
        writer._writer = nullptr;
    }

    inline Blob Database::getBlob(fleece::Dict properties) const {
        CBLError error{};
        const CBLBlob* blob = CBLDatabase_GetBlob(this->ref(), properties, &error);
        // Per the C API: null with error.code==0 is a legitimate "not found";
        // null with a populated error is a real failure -> throw.
        internal::check(blob != nullptr || error.code == 0, error);
        return {const_cast<CBLBlob*>(blob), Blob::adopt};
    }

    inline void Database::saveBlob(const Blob& blob) {
        CBLError error{};
        internal::check(CBLDatabase_SaveBlob(this->ref(), blob.ref(), &error), error);
    }
}

CBL_ASSUME_NONNULL_END
