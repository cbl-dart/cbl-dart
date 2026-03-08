//
// Prediction.hh
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
#include "cbl/CBLPrediction.h"
#include <memory>
#include <unordered_map>

// VOLATILE API: Couchbase Lite C++ API is not finalized, and may change in
// future releases.

CBL_ASSUME_NONNULL_BEGIN

namespace cbl {
    /** ENTERPRISE EDITION ONLY
     
        The PredictiveModel  that allows to integrate machine learning model
        into queries via invoking query's PREDICTION() function.
     
        @note The predictive index feature is not supported by Couchbase Lite for C.
              The Predictive Model is currently for creating vector indexes using the PREDICTION() function,
              which will call the specified predictive model for computing the vectors. */
    class PredictiveModel {
    public:
        /** Predicts and returns a mutable dictionary based on the input dictionary.
            Override this function  for the implementation.
            @param input The input dictionary corresponding to the input dictionary expression given in the query's PREDICTION() function
            @return The output dictionary.
                    - To create a new dictionary for returning, use fleece::MutableDict::newDict().
                    - To create a null result to evaluate as MISSING, use fleece::MutableDict(). */
        virtual fleece::MutableDict prediction(fleece::Dict input) noexcept = 0;
        
        virtual ~PredictiveModel() = default;
    };

    static std::unordered_map<slice, std::unique_ptr<PredictiveModel>> _sPredictiveModels;

    /** Predictive Model Registation 
        This class provides static methods to register and unregister predictive models. */
    class Prediction {
    public:
        /** Registers a predictive model with the given name. */
        static void registerModel(slice name, std::unique_ptr<PredictiveModel> model) {
            auto prediction = [](void* context, FLDict input) {
                auto m = (PredictiveModel*)context;
                return FLMutableDict_Retain((FLMutableDict) m->prediction(input));
            };
            
            CBLPredictiveModel config { };
            config.context = model.get();
            config.prediction = prediction;
            CBL_RegisterPredictiveModel(name, config);
            
            _sPredictiveModels[name] = std::move(model);
        }
        
        /** Unregisters the predictive model with the given name. */
        static void unregisterModel(slice name) {
            CBL_UnregisterPredictiveModel(name);
            _sPredictiveModels.erase(name);
        }
    };
}

CBL_ASSUME_NONNULL_END
    
#endif
