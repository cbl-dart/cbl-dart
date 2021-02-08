//
//  Query.hh
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
#include "Database.hh"
#include "CBLQuery.h"
#include <stdexcept>
#include <string>
#include <vector>

// PLEASE NOTE: This C++ wrapper API is provided as a convenience only.
// It is not considered part of the official Couchbase Lite API.

namespace cbl {
    class Query;
    class ResultSet;
    class ResultSetIterator;

    /** A database query. */
    class Query : private RefCounted {
    public:
        Query(const Database& db, CBLQueryLanguage language, const char *queryString _cbl_nonnull) {
            CBLError error;
            auto q = CBLQuery_New(db.ref(), language, queryString, nullptr, &error);
            check(q, error);
            _ref = (CBLRefCounted*)q;
        }

        inline std::vector<std::string> columnNames() const;

        void setParameters(fleece::Dict parameters) {CBLQuery_SetParameters(ref(), parameters);}
        fleece::Dict parameters() const             {return CBLQuery_Parameters(ref());}

        inline ResultSet execute();

        std::string explain()   {return fleece::alloc_slice(CBLQuery_Explain(ref())).asString();}

        // Change listener (live query):

        class ChangeListener;

        [[nodiscard]] inline ChangeListener addChangeListener(ListenerToken<Query>::Callback);

    private:
        static void _callListener(void *context, CBLQuery*);
        CBL_REFCOUNTED_BOILERPLATE(Query, RefCounted, CBLQuery)
    };


    /** A single query result; ResultSet::iterator iterates over these. */
    class Result {
    public:
        fleece::Value valueAtIndex(unsigned i) const {
            return CBLResultSet_ValueAtIndex(_ref, i);
        }

        fleece::Value valueForKey(const char *key _cbl_nonnull) const {
            return CBLResultSet_ValueForKey(_ref, key);
        }

        fleece::Value operator[](int i) const                         {return valueAtIndex(i);}
        fleece::Value operator[](const char *key _cbl_nonnull) const  {return valueForKey(key);}

    protected:
        explicit Result(CBLResultSet *ref)                      :_ref(ref) { }
        CBLResultSet* _ref;
        friend class ResultSetIterator;
    };


    /** The results of a query. The only access to the individual Results is to iterate them. */
    class ResultSet : private RefCounted {
    public:
        using iterator = ResultSetIterator;
        inline iterator begin();
        inline iterator end();

    private:
        static ResultSet adopt(const CBLResultSet *d) {
            ResultSet rs;
            rs._ref = (CBLRefCounted*)d;
            return rs;
        }

        friend class Query;
        CBL_REFCOUNTED_BOILERPLATE(ResultSet, RefCounted, CBLResultSet)
    };


    // implementation of ResultSet::iterator
    class ResultSetIterator {
    public:
        const Result& operator*()  const {return _result;}
        const Result& operator->() const {return _result;}

        bool operator== (const ResultSetIterator &i) const {return _rs == i._rs;}
        bool operator!= (const ResultSetIterator &i) const {return _rs != i._rs;}

        ResultSetIterator& operator++() {
            if (!CBLResultSet_Next(_rs.ref()))
                _rs = ResultSet{};
            return *this;
        }
    protected:
        ResultSetIterator()                                 :_rs(), _result(nullptr) { }
        explicit ResultSetIterator(ResultSet rs)
        :_rs(rs), _result(_rs.ref())
        {
            ++*this;         // CBLResultSet_Next() has to be called first
        }

        ResultSet _rs;
        Result _result;
        friend class ResultSet;
    };


    // Method implementations:


    inline std::vector<std::string> Query::columnNames() const {
        unsigned n = CBLQuery_ColumnCount(ref());
        std::vector<std::string> cols;
        cols.reserve(n);
        for (unsigned i = 0; i < n ; ++i) {
            fleece::slice name = CBLQuery_ColumnName(ref(), i);
            cols.push_back(name.asString());
        }
        return cols;
    }


    inline ResultSet Query::execute() {
        CBLError error;
        auto rs = CBLQuery_Execute(ref(), &error);
        check(rs, error);
        return ResultSet::adopt(rs);
    }


    class Query::ChangeListener : public ListenerToken<Query> {
    public:
        ChangeListener(Query query, Callback cb)
        :ListenerToken<Query>(cb)
        ,_query(std::move(query))
        { }

        ResultSet results() {
            CBLError error;
            auto rs = CBLQuery_CopyCurrentResults(_query.ref(), token(), &error);
            check(rs, error);
            return ResultSet::adopt(rs);
        }

    private:
        Query _query;
    };


    inline Query::ChangeListener Query::addChangeListener(ChangeListener::Callback f) {
        auto l = ChangeListener(*this, f);
        l.setToken( CBLQuery_AddChangeListener(ref(), &_callListener, l.context()) );
        return l;
    }


    inline void Query::_callListener(void *context, CBLQuery *q) {
        ChangeListener::call(context, Query(q));
    }


    inline ResultSet::iterator ResultSet::begin()  {
        return iterator(*this);
    }

    inline ResultSet::iterator ResultSet::end() {
        return iterator();
    }

}
