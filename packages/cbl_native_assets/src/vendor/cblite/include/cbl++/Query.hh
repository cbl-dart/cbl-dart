//
// Query.hh
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
#include "cbl++/Database.hh"
#include "cbl/CBLQuery.h"
#include <stdexcept>
#include <string>
#include <vector>

// VOLATILE API: Couchbase Lite C++ API is not finalized, and may change in
// future releases.

CBL_ASSUME_NONNULL_BEGIN

namespace cbl {
    class Query;
    class ResultSet;
    class ResultSetIterator;

    /** A database query. */
    class Query : private RefCounted {
    public:
        /** Creates a new query by compiling the input string.
            This is fast, but not instantaneous. If you need to run the same query many times, keep the
            \ref Query object around instead of compiling it each time. If you need to run related queries
            with only some values different, create one query with placeholder parameter(s), and substitute
            the desired value(s) with \ref Query::setParameters(fleece::Dict parameters) each time you run the query.
            @warning <b>Deprecated :</b> Use Database::createQuery(CBLQueryLanguage language, slice queryString) instead.
            @param language  The query language,
                    [JSON](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema) or
                    [N1QL](https://docs.couchbase.com/server/4.0/n1ql/n1ql-language-reference/index.html).
            @param queryString  The query string. */
        Query(const Database& db, CBLQueryLanguage language, slice queryString) {
            CBLError error;
            auto q = CBLDatabase_CreateQuery(db.ref(), language, queryString, nullptr, &error);
            check(q, error);
            _ref = (CBLRefCounted*)q;
        }

        /** Returns the column names that will appear in the query results.
            The column names are based on their expression in the `SELECT...` or `WHAT:` section of the
            query. A column that returns a property or property path will be named after that property.
            A column that returns an expression will have an automatically-generated name like `$1`.
            To give a column a custom name, use the `AS` syntax in the query.
            Every column is guaranteed to have a unique name. */
        inline std::vector<std::string> columnNames() const;

        /** Assigns values to the query's parameters.
            These values will be substited for those parameters whenever the query is executed,
            until they are next assigned.

            Parameters are specified in the query source as
            e.g. `$PARAM` (N1QL) or `["$PARAM"]` (JSON). In this example, the `parameters` dictionary
            to this call should have a key `PARAM` that maps to the value of the parameter.
            @param parameters  The parameters in the form of a Fleece \ref Dict "dictionary" whose
                    keys are the parameter names. (It's easiest to construct this by using the fleece::MutableDict) */
        void setParameters(fleece::Dict parameters) {CBLQuery_SetParameters(ref(), parameters);}
        
        /** Returns the query's current parameter bindings, if any. */
        fleece::Dict parameters() const             {return CBLQuery_Parameters(ref());}

        /** Runs the query, returning the results. */
        inline ResultSet execute();

        /** Returns information about the query, including the translated SQLite form, and the search
            strategy. You can use this to help optimize the query: the word `SCAN` in the strategy
            indicates a linear scan of the entire database, which should be avoided by adding an index.
            The strategy will also show which index(es), if any, are used. */
        std::string explain() {
            return fleece::alloc_slice(CBLQuery_Explain(ref())).asString();
        }

        // Change listener (live query):

        class ChangeListener;
        class Change;

        /** Registers a change listener callback to the query, turning it into a "live query" until
            the listener is removed (via \ref ListenerToken::remove() ).
         
            When the first change listener is added, the query will run (in the background) and notify
            the listener(s) of the results when ready. After that, it will run in the background after
            the database changes, and only notify the listeners when the result set changes.
            @param callback  The callback to be invoked.
            @return A Change Listener Token. Call \ref ListenerToken::remove() method to remove the listener. */
        [[nodiscard]] inline ChangeListener addChangeListener(ListenerToken<Change>::Callback callback);

    private:
        static void _callListener(void *context, CBLQuery*, CBLListenerToken* token);
        CBL_REFCOUNTED_BOILERPLATE(Query, RefCounted, CBLQuery)
    };


    /** A single query result; ResultSet::iterator iterates over these. */
    class Result {
    public:
        
        /** Returns the number of columns in the current result. */
        uint64_t count() const {
            return CBLQuery_ColumnCount(CBLResultSet_GetQuery(_ref));
        }
        
        /** Returns the current result as a JSON dictionary string. */
        alloc_slice toJSON() const {
            FLDict dict = CBLResultSet_ResultDict(_ref);
            return alloc_slice(FLValue_ToJSON((FLValue)dict));
        }
        
        /** Returns the value of a column of the current result, given its (zero-based) numeric index.
            This may return a NULL Value, indicating `MISSING`, if the value doesn't exist, e.g. if
            the column is a property that doesn't exist in the document. */
        fleece::Value valueAtIndex(unsigned i) const {
            return CBLResultSet_ValueAtIndex(_ref, i);
        }

        /** Returns the value of a column of the current result, given its column name.
            This may return a NULL Value, indicating `MISSING`, if the value doesn't exist, e.g. if
            the column is a property that doesn't exist in the document. (Or, of course, if the key
            is not a column name in this query.) */
        fleece::Value valueForKey(slice key) const {
            return CBLResultSet_ValueForKey(_ref, key);
        }

        /** A subscript operator that returns value of a column of the current result, given its (zero-based) numeric index.  */
        fleece::Value operator[](int i) const                           {return valueAtIndex(i);}
        
        /** A subscript operator that returns the value of a column of the current result, given its column name.  */
        fleece::Value operator[](slice key) const                       {return valueForKey(key);}

    protected:
        explicit Result(CBLResultSet* _cbl_nullable ref)                :_ref(ref) { }
        CBLResultSet* _cbl_nullable _ref;
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

    // Implementation of ResultSet::iterator
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

    class Query::ChangeListener : public ListenerToken<Change> {
    public:
        ChangeListener(): ListenerToken<Change>() { }
        
        ChangeListener(Query query, Callback cb)
        :ListenerToken<Change>(cb)
        ,_query(std::move(query))
        { }

        ResultSet results() {
            if (!_query) {
                throw std::runtime_error("Not allowed to call on uninitialized ChangeListeners");
            }
            return getResults(_query, token());
        }

    private:
        static ResultSet getResults(Query query, CBLListenerToken* token) {
            CBLError error;
            auto rs = CBLQuery_CopyCurrentResults(query.ref(), token, &error);
            check(rs, error);
            return ResultSet::adopt(rs);
        }

        Query _query;
        friend Change;
    };

    class Query::Change {
    public:
        Change(const Change& src) : _query(src._query), _token(src._token) {}

        ResultSet results() {
            return ChangeListener::getResults(_query, _token);
        }

        Query query() {
            return _query;
        }

    private:
        friend class Query;
        Change(Query q, CBLListenerToken* token) : _query(q), _token(token) {}

        Query _query;
        CBLListenerToken* _token;
    };


    inline Query::ChangeListener Query::addChangeListener(ChangeListener::Callback f) {
        auto l = ChangeListener(*this, f);
        l.setToken( CBLQuery_AddChangeListener(ref(), &_callListener, l.context()) );
        return l;
    }


    inline void Query::_callListener(void *context, CBLQuery *q, CBLListenerToken* token) {
        ChangeListener::call(context, Change{Query(q), token});
    }


    inline ResultSet::iterator ResultSet::begin()  {
        return iterator(*this);
    }

    inline ResultSet::iterator ResultSet::end() {
        return iterator();
    }

    // Query
    
    Query Database::createQuery(CBLQueryLanguage language, slice queryString) {
        return Query(*this, language, queryString);
    }
}

CBL_ASSUME_NONNULL_END
