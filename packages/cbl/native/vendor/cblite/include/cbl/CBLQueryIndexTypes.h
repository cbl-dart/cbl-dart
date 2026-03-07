//
//  CBLQueryIndexTypes.h
//
// Copyright (c) 2024 Couchbase, Inc All rights reserved.
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
#include "CBLQueryTypes.h"

CBL_CAPI_BEGIN

/** \defgroup index  Index 
    @{ */

/** \name Index Configuration
    @{ */

/** Value Index Configuration. */
typedef struct {
    /** The language used in the expressions (Required). */
    CBLQueryLanguage expressionLanguage;
    
    /** The expressions describing each coloumn of the index (Required).
        The expressions could be specified in a JSON Array or in N1QL syntax
        using comma delimiter, depending on expressionLanguage. */
    FLString expressions;
    
    /** A predicate expression defining conditions for indexing documents.
        Only documents satisfying the predicate are included, enabling partial indexes.
        The expression can be JSON or N1QL/SQL++ syntax, depending on expressionLanguage. */
    FLString where;
} CBLValueIndexConfiguration;

/** Full-Text Index Configuration. */
typedef struct {
    /** The language used in the expressions (Required). */
    CBLQueryLanguage expressionLanguage;
    
    /** The expressions describing each coloumn of the index (Required).
        The expressions could be specified in a JSON Array or in N1QL syntax
        using comma delimiter, depending on expressionLanguage. */
    FLString expressions;
    
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
    FLString language;
    
    /** A predicate expression defining conditions for indexing documents.
        Only documents satisfying the predicate are included, enabling partial indexes.
        The expression can be JSON or N1QL/SQL++ syntax, depending on expressionLanguage. */
    FLString where;
} CBLFullTextIndexConfiguration;

/** Array Index Configuration for indexing property values within arrays
    in documents, intended for use with the UNNEST query. */
typedef struct {
    /** The language used in the expressions (Required). */
    CBLQueryLanguage expressionLanguage;
    
    /** Path to the array, which can be nested to be indexed (Required).
        Use "[]" to represent a property that is an array of each nested array level.
        For a single array or the last level array, the "[]" is optional. For instance,
        use "contacts[].phones" to specify an array of phones within each contact. */
    FLString path;
    
    /** Optional expressions representing the values within the array to be
        indexed. The expressions could be specified in a JSON Array or in N1QL syntax
        using comma delimiter, depending on expressionLanguage.
        If the array specified by the path contains scalar values, the expressions
        should be left unset or set to null. */
    FLString expressions;
} CBLArrayIndexConfiguration;

#ifdef COUCHBASE_ENTERPRISE

/** An opaque object representing vector encoding type to use in CBLVectorIndexConfiguration. */
typedef struct CBLVectorEncoding CBLVectorEncoding;

/** Creates a no-encoding type to use in CBLVectorIndexConfiguration; 4 bytes per dimension, no data loss.  
    @return A None encoding object. */
_cbl_warn_unused
CBLVectorEncoding* CBLVectorEncoding_CreateNone(void) CBLAPI;

/** Scalar Quantizer encoding type */
typedef CBL_ENUM(uint32_t, CBLScalarQuantizerType) {
    kCBLSQ4 = 4,                            ///< 4 bits per dimension
    kCBLSQ6 = 6,                            ///< 6 bits per dimension
    kCBLSQ8 = 8                             ///< 8 bits per dimension
};

/** Creates a Scalar Quantizer encoding to use in CBLVectorIndexConfiguration.
    @param type Scalar Quantizer Type.
    @return A Scalar Quantizer encoding object. */
_cbl_warn_unused
CBLVectorEncoding* CBLVectorEncoding_CreateScalarQuantizer(CBLScalarQuantizerType type) CBLAPI;

/** Creates a Product Quantizer encoding to use in CBLVectorIndexConfiguration.
    @param subquantizers Number of subquantizers. Must be > 1 and a factor of vector dimensions.
    @param bits Number of bits. Must be >= 4 and <= 12. 
    @return A Product Quantizer encoding object. */
_cbl_warn_unused
CBLVectorEncoding* CBLVectorEncoding_CreateProductQuantizer(unsigned subquantizers, unsigned bits) CBLAPI;

/** Frees a CBLVectorEncoding object. The encoding object can be freed after the index is created. */
void CBLVectorEncoding_Free(CBLVectorEncoding* _cbl_nullable) CBLAPI;

/** Distance metric to use in CBLVectorIndexConfiguration. */
typedef CBL_ENUM(uint32_t, CBLDistanceMetric) {
    kCBLDistanceMetricEuclideanSquared = 1,         ///< Squared Euclidean distance (AKA Squared L2)
    kCBLDistanceMetricCosine,                       ///< Cosine distance (1.0 - Cosine Similarity)
    kCBLDistanceMetricEuclidean,                    ///< Euclidean distance (AKA L2)
    kCBLDistanceMetricDot                           ///< Dot-product distance (Negative of dot-product)
};

/** ENTERPRISE EDITION ONLY
    
    Vector Index Configuration. */
typedef struct {
    /** The language used in the expressions (Required). */
    CBLQueryLanguage expressionLanguage;
    
    /** The expression could be specified in a JSON Array or in N1QL syntax depending on 
        the expressionLanguage. (Required)
     
        For non-lazy indexes, an expression returning either a vector, which is an array of 32-bit
        floating-point numbers, or a Base64 string representing an array of 32-bit floating-point
        numbers in little-endian order.
     
        For lazy indexex, an expression returning a value for computing a vector lazily when using
        \ref CBLIndexUpdater to add or update the vector into the index. */
    FLString expression;
    
    /** The number of vector dimensions. (Required) 
        @note The maximum number of vector dimensions supported is 4096. */
    unsigned dimensions;
    
    /** The number of centroids which is the number buckets to partition the vectors in the index. (Required) 
        @note The recommended number of centroids is the square root of the number of vectors to be indexed,
              and the maximum number of centroids supported is 64,000.*/
    unsigned centroids;
    
    /** The boolean flag indicating that index is lazy or not. The default value is false.
     
        If the index is lazy, it will not be automatically updated when the documents in the collection are changed,
        except when the documents are deleted or purged.
     
        When configuring the index to be lazy, the expression set to the config is the expression that returns
        a value used for computing the vector.
     
        To update the lazy index, use a CBLIndexUpdater object, which can be obtained
        from a CBLQueryIndex object. To get a CBLQueryIndex object, call CBLCollection_GetIndex. */
    bool isLazy;
    
    /** Vector encoding type. The default value is 8-bits Scalar Quantizer. */
    CBLVectorEncoding* encoding;
    
    /** Distance Metric type. The default value is euclidean distance. */
    CBLDistanceMetric metric;
    
    /** The minimum number of vectors for training the index. 
        The default value is zero, meaning that minTrainingSize will be determined based on
        the number of centroids, encoding types, and the encoding parameters.
     
        @note The training will occur at or before the APPROX_VECTOR_DISANCE query is
        executed, provided there is enough data at that time, and consequently, if
        training is triggered during a query, the query may take longer to return
        results.
     
        @note If a query is executed against the index before it is trained, a full
        scan of the vectors will be performed. If there are insufficient vectors
        in the database for training, a warning message will be logged,
        indicating the required number of vectors. */
    unsigned minTrainingSize;
    
    /** The maximum number of vectors used for training the index.
        The default value is zero, meaning that the maxTrainingSize will be determined based on
        the number of centroids, encoding types, and encoding parameters. */
    unsigned maxTrainingSize;
    
    /** The number of centroids that will be scanned during a query.
        The default value is zero, meaning that the numProbes will be determined based on
        the number of centroids. */
    unsigned numProbes;
} CBLVectorIndexConfiguration;

#endif

/** @} */

/** @} */

CBL_CAPI_END
