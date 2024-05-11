//
// CBLQuery.h
//
// Copyright (c) 2018 Couchbase, Inc All rights reserved.
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

CBL_CAPI_BEGIN


/** \defgroup queries   Queries
    @{
    A CBLQuery represents a compiled database query. The query language is a large subset of
    the [N1QL](https://www.couchbase.com/products/n1ql) language from Couchbase Server, which
    you can think of as "SQL for JSON" or "SQL++".

    Queries may be given either in
    [N1QL syntax](https://docs.couchbase.com/server/6.0/n1ql/n1ql-language-reference/index.html),
    or in JSON using a
    [schema](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema)
    that resembles a parse tree of N1QL. The JSON syntax is harder for humans, but much more
    amenable to machine generation, if you need to create queries programmatically or translate
    them from some other form.
 */


/** Query languages */
typedef CBL_ENUM(uint32_t, CBLQueryLanguage) {
    kCBLJSONLanguage,       ///< [JSON query schema](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema)
    kCBLN1QLLanguage        ///< [N1QL syntax](https://docs.couchbase.com/server/6.0/n1ql/n1ql-language-reference/index.html)
};


/** \name  Query objects
    @{ */

/** Creates a new query by compiling the input string.
    This is fast, but not instantaneous. If you need to run the same query many times, keep the
    \ref CBLQuery around instead of compiling it each time. If you need to run related queries
    with only some values different, create one query with placeholder parameter(s), and substitute
    the desired value(s) with \ref CBLQuery_SetParameters each time you run the query.
    @note  You must release the \ref CBLQuery when you're finished with it.
    @param db  The database to query.
    @param language  The query language,
            [JSON](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema) or
            [N1QL](https://docs.couchbase.com/server/4.0/n1ql/n1ql-language-reference/index.html).
    @param queryString  The query string.
    @param outErrorPos  If non-NULL, then on a parse error the approximate byte offset in the
                    input expression will be stored here (or -1 if not known/applicable.)
    @param outError  On failure, the error will be written here.
    @return  The new query object. */
_cbl_warn_unused
CBLQuery* _cbl_nullable CBLDatabase_CreateQuery(const CBLDatabase* db,
                                                CBLQueryLanguage language,
                                                FLString queryString,
                                                int* _cbl_nullable outErrorPos,
                                                CBLError* _cbl_nullable outError) CBLAPI;

CBL_REFCOUNTED(CBLQuery*, Query);

/** Assigns values to the query's parameters.
    These values will be substited for those parameters whenever the query is executed,
    until they are next assigned.

    Parameters are specified in the query source as
    e.g. `$PARAM` (N1QL) or `["$PARAM"]` (JSON). In this example, the `parameters` dictionary
    to this call should have a key `PARAM` that maps to the value of the parameter.
    @param query  The query.
    @param parameters  The parameters in the form of a Fleece \ref FLDict "dictionary" whose
            keys are the parameter names. (It's easiest to construct this by using the mutable
            API, i.e. calling \ref FLMutableDict_New and adding keys/values.) */
void CBLQuery_SetParameters(CBLQuery* query,
                            FLDict parameters) CBLAPI;

/** Returns the query's current parameter bindings, if any. */
FLDict _cbl_nullable CBLQuery_Parameters(const CBLQuery* query) CBLAPI;

/** Runs the query, returning the results.
    To obtain the results you'll typically call \ref CBLResultSet_Next in a `while` loop,
    examining the values in the \ref CBLResultSet each time around.
    @note  You must release the result set when you're finished with it. */
_cbl_warn_unused
CBLResultSet* _cbl_nullable CBLQuery_Execute(CBLQuery*,
                                             CBLError* _cbl_nullable outError) CBLAPI;

/** Returns information about the query, including the translated SQLite form, and the search
    strategy. You can use this to help optimize the query: the word `SCAN` in the strategy
    indicates a linear scan of the entire database, which should be avoided by adding an index.
    The strategy will also show which index(es), if any, are used.
    @note  You are responsible for releasing the result by calling \ref FLSliceResult_Release. */
_cbl_warn_unused
FLSliceResult CBLQuery_Explain(const CBLQuery*) CBLAPI;

/** Returns the number of columns in each result. */
unsigned CBLQuery_ColumnCount(const CBLQuery*) CBLAPI;

/** Returns the name of a column in the result.
    The column name is based on its expression in the `SELECT...` or `WHAT:` section of the
    query. A column that returns a property or property path will be named after that property.
    A column that returns an expression will have an automatically-generated name like `$1`.
    To give a column a custom name, use the `AS` syntax in the query.
    Every column is guaranteed to have a unique name. */
FLSlice CBLQuery_ColumnName(const CBLQuery*,
                            unsigned columnIndex) CBLAPI;

/** @} */



/** \name  Result sets
    @{
    A `CBLResultSet` is an iterator over the results returned by a query. It exposes one
    result at a time -- as a collection of values indexed either by position or by name --
    and can be stepped from one result to the next.

    It's important to note that the initial position of the iterator is _before_ the first
    result, so \ref CBLResultSet_Next must be called _first_. Example:

    ```
    CBLResultSet *rs = CBLQuery_Execute(query, &error);
    assert(rs);
    while (CBLResultSet_Next(rs) {
        FLValue aValue = CBLResultSet_ValueAtIndex(rs, 0);
        ...
    }
    CBLResultSet_Release(rs);
    ```
 */

/** Moves the result-set iterator to the next result.
    Returns false if there are no more results.
    @warning This must be called _before_ examining the first result. */
_cbl_warn_unused
bool CBLResultSet_Next(CBLResultSet*) CBLAPI;

/** Returns the value of a column of the current result, given its (zero-based) numeric index.
    This may return a NULL pointer, indicating `MISSING`, if the value doesn't exist, e.g. if
    the column is a property that doesn't exist in the document. */
FLValue CBLResultSet_ValueAtIndex(const CBLResultSet*,
                                  unsigned index) CBLAPI;

/** Returns the value of a column of the current result, given its name.
    This may return a NULL pointer, indicating `MISSING`, if the value doesn't exist, e.g. if
    the column is a property that doesn't exist in the document. (Or, of course, if the key
    is not a column name in this query.)
    @note  See \ref CBLQuery_ColumnName for a discussion of column names. */
FLValue CBLResultSet_ValueForKey(const CBLResultSet*,
                                 FLString key) CBLAPI;

/** Returns the current result as an array of column values.
    @warning The array reference is only valid until the result-set is advanced or released.
            If you want to keep it for longer, call \ref FLArray_Retain (and release it when done.) */
FLArray CBLResultSet_ResultArray(const CBLResultSet*) CBLAPI;

/** Returns the current result as a dictionary mapping column names to values.
    @warning The dict reference is only valid until the result-set is advanced or released.
            If you want to keep it for longer, call \ref FLDict_Retain (and release it when done.) */
FLDict CBLResultSet_ResultDict(const CBLResultSet*) CBLAPI;

/** Returns the Query that created this ResultSet. */
CBLQuery* CBLResultSet_GetQuery(const CBLResultSet *rs) CBLAPI;

CBL_REFCOUNTED(CBLResultSet*, ResultSet);

/** @} */



/** \name  Change listener
    @{
    Adding a change listener to a query turns it into a "live query". When changes are made to
    documents, the query will periodically re-run and compare its results with the prior
    results; if the new results are different, the listener callback will be called.

    @note  The result set passed to the listener is the _entire new result set_, not just the
            rows that changed.
 */

/** A callback to be invoked after the query's results have changed.
    The actual result set can be obtained by calling \ref CBLQuery_CopyCurrentResults, either during
    the callback or at any time thereafter.
    @warning  By default, this listener may be called on arbitrary threads. If your code isn't
                    prepared for that, you may want to use \ref CBLDatabase_BufferNotifications
                    so that listeners will be called in a safe context.
    @param context  The same `context` value that you passed when adding the listener.
    @param query  The query that triggered the listener.
    @param token  The token for obtaining the query results by calling \ref CBLQuery_CopyCurrentResults. */
typedef void (*CBLQueryChangeListener)(void* _cbl_nullable context,
                                       CBLQuery* query,
                                       CBLListenerToken* token);

/** Registers a change listener callback with a query, turning it into a "live query" until
    the listener is removed (via \ref CBLListener_Remove).

    When the first change listener is added, the query will run (in the background) and notify
    the listener(s) of the results when ready. After that, it will run in the background after
    the database changes, and only notify the listeners when the result set changes.
    @param query  The query to observe.
    @param listener  The callback to be invoked.
    @param context  An opaque value that will be passed to the callback.
    @return  A token to be passed to \ref CBLListener_Remove when it's time to remove the
            listener.*/
_cbl_warn_unused
CBLListenerToken* CBLQuery_AddChangeListener(CBLQuery* query,
                                             CBLQueryChangeListener listener,
                                             void* _cbl_nullable context) CBLAPI;

/** Returns the query's _entire_ current result set, after it's been announced via a call to the
    listener's callback.
    @note  You must release the result set when you're finished with it.
    @param query  The query being listened to.
    @param listener  The query listener that was notified.
    @param outError  If the query failed to run, the error will be stored here.
    @return  A new object containing the query's current results, or NULL if the query failed to run. */
_cbl_warn_unused
CBLResultSet* _cbl_nullable CBLQuery_CopyCurrentResults(const CBLQuery* query,
                                                        CBLListenerToken *listener,
                                                        CBLError* _cbl_nullable outError) CBLAPI;

/** @} */



/** \name  Database Indexes
    @{
    Indexes are used to speed up queries by allowing fast -- O(log n) -- lookup of documents
    that have specific values or ranges of values. The values may be properties, or expressions
    based on properties.

    An index will speed up queries that use the expression it indexes, but it takes up space in
    the database file, and it slows down document saves slightly because it needs to be kept up
    to date when documents change.

    Tuning a database with indexes can be a tricky task. Fortunately, a lot has been written about
    it in the relational-database (SQL) realm, and much of that advice holds for Couchbase Lite.
    You may find SQLite's documentation particularly helpful since Couchbase Lite's querying is
    based on SQLite.

    Two types of indexes are currently supported:
        * Value indexes speed up queries by making it possible to look up property (or expression)
          values without scanning every document. They're just like regular indexes in SQL or N1QL.
          Multiple expressions are supported; the first is the primary key, second is secondary.
          Expressions must evaluate to scalar types (boolean, number, string).
        * Full-Text Search (FTS) indexes enable fast search of natural-language words or phrases
          by using the `MATCH` operator in a query. A FTS index is **required** for full-text
          search: a query with a `MATCH` operator will fail to compile unless there is already a
          FTS index for the property/expression being matched. Only a single expression is
          currently allowed, and it must evaluate to a string. */

/** Value Index Configuration. */
typedef struct {
    /** The language used in the expressions. */
    CBLQueryLanguage expressionLanguage;
    
    /** The expressions describing each coloumn of the index. The expressions could be specified
        in a JSON Array or in N1QL syntax using comma delimiter. */
    FLString expressions;
} CBLValueIndexConfiguration;

/** Creates a value index.
    Indexes are persistent.
    If an identical index with that name already exists, nothing happens (and no error is returned.)
    If a non-identical index with that name already exists, it is deleted and re-created.
    @warning  <b>Deprecated :</b> Use CBLCollection_CreateValueIndex on the default collection instead. */
bool CBLDatabase_CreateValueIndex(CBLDatabase *db,
                                  FLString name,
                                  CBLValueIndexConfiguration config,
                                  CBLError* _cbl_nullable outError) CBLAPI;


/** Full-Text Index Configuration. */
typedef struct {
    /** The language used in the expressions (Required). */
    CBLQueryLanguage expressionLanguage;
    
    /** The expressions describing each coloumn of the index. The expressions could be specified
        in a JSON Array or in N1QL syntax using comma delimiter. (Required) */
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
} CBLFullTextIndexConfiguration;

/** Creates a full-text index.
    Indexes are persistent.
    If an identical index with that name already exists, nothing happens (and no error is returned.)
    If a non-identical index with that name already exists, it is deleted and re-created.
    @warning  <b>Deprecated :</b> Use CBLCollection_CreateFullTextIndex on the default collection instead. */
bool CBLDatabase_CreateFullTextIndex(CBLDatabase *db,
                                     FLString name,
                                     CBLFullTextIndexConfiguration config,
                                     CBLError* _cbl_nullable outError) CBLAPI;

/** Deletes an index given its name.
    @warning  <b>Deprecated :</b> Use CBLCollection_DeleteIndex on the default collection instead. */
bool CBLDatabase_DeleteIndex(CBLDatabase *db,
                             FLString name,
                             CBLError* _cbl_nullable outError) CBLAPI;

/** Returns the names of the indexes on this database, as a Fleece array of strings.
    @note  You are responsible for releasing the returned Fleece array.
    @warning  <b>Deprecated :</b> Use CBLCollection_GetIndexNames on the default collection instead. */
_cbl_warn_unused
FLArray CBLDatabase_GetIndexNames(CBLDatabase *db) CBLAPI;

/** @} */
/** @} */

CBL_CAPI_END
