//
// VectorIndex.hh
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

// VOLATILE API: Couchbase Lite C++ API is not finalized, and may change in
// future releases.

#ifdef COUCHBASE_ENTERPRISE

#pragma once
#include "cbl++/Base.hh"
#include "cbl++/Collection.hh"
#include "cbl/CBLQueryIndexTypes.h"

CBL_ASSUME_NONNULL_BEGIN

namespace cbl {
    /** ENTERPRISE EDITION ONLY
     
        Vector Encoding  Type*/
    class VectorEncoding {
    public:
        /** Creates a no-encoding type to use in VectorIndexConfiguration; 4 bytes per dimension, no data loss.
            @return A None encoding object. */
        static VectorEncoding none() {
            return VectorEncoding(CBLVectorEncoding_CreateNone());
        }
        
        /** Creates a Scalar Quantizer encoding type to use in VectorIndexConfiguration. 
            @param type Scalar Quantizer Type.
            @return A Scalar Quantizer encoding object. */
        static VectorEncoding scalarQuantizer(CBLScalarQuantizerType type) {
            return VectorEncoding(CBLVectorEncoding_CreateScalarQuantizer(type));
        }
        
        /** Creates a Product Quantizer encoding type to use in VectorIndexConfiguration.
            @param subquantizers Number of subquantizers. Must be > 1 and a factor of vector dimensions.
            @param bits Number of bits. Must be >= 4 and <= 12.
            @return A Product Quantizer encoding object. */
        static VectorEncoding productQuantizer(unsigned int subquantizers, unsigned int bits) {
            return VectorEncoding(CBLVectorEncoding_CreateProductQuantizer(subquantizers, bits));
        }
        
        VectorEncoding() = delete;
        
    protected:
        friend class VectorIndexConfiguration;
        
        CBLVectorEncoding* ref() const {return _ref.get();}
    
    private:
        VectorEncoding(CBLVectorEncoding* ref) {
            _ref = std::shared_ptr<CBLVectorEncoding>(ref, [](auto r) {
                CBLVectorEncoding_Free(r);
            });
        }
        
        std::shared_ptr<CBLVectorEncoding> _ref;
    };

    /** ENTERPRISE EDITION ONLY
     
        Vector Index Configuration. */
    class VectorIndexConfiguration {
    public:
        /** Creates the VectorIndexConfiguration. 
            @param expressionLanguage  The language used in the expressions.
            @param expression The expression could be specified in a JSON Array or in N1QL syntax depending on
                              the expressionLanguage.
                              - For non-lazy indexes, an expression returning either a vector, which is an array of 32-bit
                               floating-point numbers, or a Base64 string representing an array of 32-bit floating-point
                               numbers in little-endian order.
                              - For lazy indexex, an expression returning a value for computing a vector lazily when using
                               \ref IndexUpdater to add or update the vector into the index.
            @param dimensions  The number of vector dimensions.
                              @note The maximum number of vector dimensions supported is 4096.
            @param centroids    The number of centroids which is the number buckets to partition the vectors in the index.
                              @note The recommended number of centroids is the square root of the number of vectors to be indexed,
                              and the maximum number of centroids supported is 64,000. */
        VectorIndexConfiguration(CBLQueryLanguage expressionLanguage, slice expression,
                                 unsigned dimensions, unsigned centroids)
        :_exprLang(expressionLanguage)
        ,_expr(expression)
        ,_dimensions(dimensions)
        ,_centroids(centroids)
        { }
        
        //-- Accessors:
        
        /** The language used in the expressions.  */
        CBLQueryLanguage expressionLanguage() const         {return _exprLang;}
        
        /** The expression. */
        slice expression() const                            {return _expr;}
        
        /** The number of vector dimensions. */
        unsigned dimensions() const                         {return _dimensions;}
        
        /** The number of centroids. */
        unsigned centroids() const                          {return _centroids;}
        
        /** The boolean flag indicating that index is lazy or not. The default value is false.
         
            If the index is lazy, it will not be automatically updated when the documents in the collection are changed,
            except when the documents are deleted or purged.
         
            When configuring the index to be lazy, the expression set to the config is the expression that returns
            a value used for computing the vector.
         
            To update the lazy index, use a CBLIndexUpdater object, which can be obtained
            from a \ref QueryIndex object. To get a \ref QueryIndex object, call \ref Collection::getIndex. */
        bool isLazy = false;
        
        /** Vector encoding type. The default value is 8-bits Scalar Quantizer.  */
        VectorEncoding encoding = VectorEncoding::scalarQuantizer(kCBLSQ8);
        
        /** Distance Metric type. The default value is squared euclidean distance.  */
        CBLDistanceMetric metric = kCBLDistanceMetricEuclideanSquared;
        
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
        unsigned minTrainingSize = 0;
        
        /** The maximum number of vectors used for training the index.
            The default value is zero, meaning that the maxTrainingSize will be determined based on
            the number of centroids, encoding types, and encoding parameters.  */
        unsigned maxTrainingSize = 0;
        
        /** The number of centroids that will be scanned during a query.
            The default value is zero, meaning that the numProbes will be determined based on
            the number of centroids. */
        unsigned numProbes = 0;
        
    protected:
        friend Collection;
        
        /** To  CBLVectorIndexConfiguration */
        operator CBLVectorIndexConfiguration() const {
            CBLVectorIndexConfiguration config { _exprLang, _expr, _dimensions, _centroids };
            config.isLazy = isLazy;
            config.encoding = encoding.ref();
            config.metric = metric;
            config.minTrainingSize = minTrainingSize;
            config.maxTrainingSize = maxTrainingSize;
            config.numProbes = numProbes;
            return config;
        }
            
    private:
        CBLQueryLanguage _exprLang;
        slice _expr;
        unsigned _dimensions;
        unsigned _centroids;
    };

    void Collection::createVectorIndex(slice name, const VectorIndexConfiguration &config) {
        CBLError error {};
        check(CBLCollection_CreateVectorIndex(ref(), name, config, &error), error);
    }
}

CBL_ASSUME_NONNULL_END

#endif
