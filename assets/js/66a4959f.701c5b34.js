"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[506],{3905:(e,t,n)=>{n.d(t,{Zo:()=>m,kt:()=>k});var a=n(7294);function r(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function l(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);t&&(a=a.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,a)}return n}function i(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?l(Object(n),!0).forEach((function(t){r(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):l(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function d(e,t){if(null==e)return{};var n,a,r=function(e,t){if(null==e)return{};var n,a,r={},l=Object.keys(e);for(a=0;a<l.length;a++)n=l[a],t.indexOf(n)>=0||(r[n]=e[n]);return r}(e,t);if(Object.getOwnPropertySymbols){var l=Object.getOwnPropertySymbols(e);for(a=0;a<l.length;a++)n=l[a],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(r[n]=e[n])}return r}var o=a.createContext({}),p=function(e){var t=a.useContext(o),n=t;return e&&(n="function"==typeof e?e(t):i(i({},t),e)),n},m=function(e){var t=p(e.components);return a.createElement(o.Provider,{value:t},e.children)},N={inlineCode:"code",wrapper:function(e){var t=e.children;return a.createElement(a.Fragment,{},t)}},u=a.forwardRef((function(e,t){var n=e.components,r=e.mdxType,l=e.originalType,o=e.parentName,m=d(e,["components","mdxType","originalType","parentName"]),u=p(n),k=r,s=u["".concat(o,".").concat(k)]||u[k]||N[k]||l;return n?a.createElement(s,i(i({ref:t},m),{},{components:n})):a.createElement(s,i({ref:t},m))}));function k(e,t){var n=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var l=n.length,i=new Array(l);i[0]=u;var d={};for(var o in t)hasOwnProperty.call(t,o)&&(d[o]=t[o]);d.originalType=e,d.mdxType="string"==typeof e?e:r,i[1]=d;for(var p=2;p<l;p++)i[p]=n[p];return a.createElement.apply(null,i)}return a.createElement.apply(null,n)}u.displayName="MDXCreateElement"},3192:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>o,contentTitle:()=>i,default:()=>k,frontMatter:()=>l,metadata:()=>d,toc:()=>p});var a=n(7462),r=(n(7294),n(3905));const l={description:"Differences between SQL++ for Mobile and SQL++ for Server",related_content:[{name:"SQL++ for Mobile",url:"/queries/sqlplusplus-mobile"},{name:"Indexes",url:"/indexing"}]},i="SQL++ for Mobile and Server Differences",d={unversionedId:"queries/sqlplusplus-server-diff",id:"queries/sqlplusplus-server-diff",title:"SQL++ for Mobile and Server Differences",description:"Differences between SQL++ for Mobile and SQL++ for Server",source:"@site/docs/queries/sqlplusplus-server-diff.mdx",sourceDirName:"queries",slug:"/queries/sqlplusplus-server-diff",permalink:"/queries/sqlplusplus-server-diff",draft:!1,editUrl:"https://github.com/cbl-dart/cbl-dart/tree/main/docs/docs/queries/sqlplusplus-server-diff.mdx",tags:[],version:"current",frontMatter:{description:"Differences between SQL++ for Mobile and SQL++ for Server",related_content:[{name:"SQL++ for Mobile",url:"/queries/sqlplusplus-mobile"},{name:"Indexes",url:"/indexing"}]},sidebar:"sidebar",previous:{title:"SQL++ for Mobile",permalink:"/queries/sqlplusplus-mobile"},next:{title:"SQL++ and QueryBuilder Differences",permalink:"/queries/sqlplusplus-query-builder-diff"}},o={},p=[{value:"Boolean Logic Rules",id:"boolean-logic-rules",level:2},{value:"SQL++ for Server",id:"sql-for-server",level:3},{value:"SQL++ for Mobile",id:"sql-for-mobile",level:3},{value:"Logical Operations",id:"logical-operations",level:3},{value:"CRUD Operations",id:"crud-operations",level:2},{value:"Functions",id:"functions",level:2},{value:"Division Operator",id:"division-operator",level:3},{value:"Round Function",id:"round-function",level:3}],m=(N="Table",function(e){return console.warn("Component "+N+" was not imported, exported, or provided by MDXProvider as global scope"),(0,r.kt)("div",e)});var N;const u={toc:p};function k(e){let{components:t,...n}=e;return(0,r.kt)("wrapper",(0,a.Z)({},u,n,{components:t,mdxType:"MDXLayout"}),(0,r.kt)("h1",{id:"sql-for-mobile-and-server-differences"},"SQL++ for Mobile and Server Differences"),(0,r.kt)("metaheader",null),(0,r.kt)("admonition",{type:"important"},(0,r.kt)("p",{parentName:"admonition"},"N1QL is Couchbase's implementation of the developing SQL++ standard. As such the\nterms N1QL and SQL++ are used interchangeably in all Couchbase documentation\nunless explicitly stated otherwise.")),(0,r.kt)("p",null,"There are several minor but notable behavior differences between SQL++ for\nMobile queries and SQL++ for Server, as shown in ",(0,r.kt)("a",{parentName:"p",href:"#table-1"},"Table 1"),"."),(0,r.kt)("p",null,"In some instances, if required, you can force SQL++ for Mobile to work in the\nsame way as SQL++ for Server. These instances are noted in the content below."),(0,r.kt)(m,{id:1,title:"SQL++ Query Comparison",mdxType:"Table"},(0,r.kt)("table",null,(0,r.kt)("thead",{parentName:"table"},(0,r.kt)("tr",{parentName:"thead"},(0,r.kt)("th",{parentName:"tr",align:null},"Feature"),(0,r.kt)("th",{parentName:"tr",align:null},"SQL++ for Server"),(0,r.kt)("th",{parentName:"tr",align:null},"SQL++ for Mobile"))),(0,r.kt)("tbody",{parentName:"table"},(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"USE KEYS")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"SELECT fname, email FROM tutorial USE KEYS ('dave', 'ian');")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"SELECT fname, email FROM tutorial WHERE Meta().id IN ('dave', 'ian');"))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"ON KEYS")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"SELECT * FROM user u JOIN orders o ON KEYS ARRAY s.order_id FOR s IN u.order_history END;")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"SELECT * FROM user u, u.order_history s JOIN orders o ON s.order_id = Meta(o).id;"))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"USE KEY")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"SELECT * FROM user u JOIN orders o ON KEY o.user_id FOR u;")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"SELECT * FROM user u JOIN orders o ON Meta(u).id = o.user_id;"))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NEST")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"SELECT * FROM user u NEST orders orders ON KEYS ARRAY s.order_id FOR s IN u.order_history END;")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NEST"),"/",(0,r.kt)("inlineCode",{parentName:"td"},"UNNEST")," not supported")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"LEFT OUTER NEST")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"SELECT * FROM user u LEFT OUTER NEST orders orders ON KEYS ARRAY s.order_id FOR s IN u.order_history END;")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NEST"),"/",(0,r.kt)("inlineCode",{parentName:"td"},"UNNEST")," not supported")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"ARRAY")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"ARRAY i FOR i IN [1, 2] END")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"(SELECT VALUE i FROM [1, 2] AS i)"))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"ARRAY FIRST")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"ARRAY FIRST arr")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"arr[0]"))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"LIMIT l OFFSET o")),(0,r.kt)("td",{parentName:"tr",align:null},"Allows ",(0,r.kt)("inlineCode",{parentName:"td"},"OFFSET")," without ",(0,r.kt)("inlineCode",{parentName:"td"},"LIMIT")),(0,r.kt)("td",{parentName:"tr",align:null},"Allows ",(0,r.kt)("inlineCode",{parentName:"td"},"OFFSET")," without ",(0,r.kt)("inlineCode",{parentName:"td"},"LIMIT"))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"UNION"),", ",(0,r.kt)("inlineCode",{parentName:"td"},"INTERSECT"),", ",(0,r.kt)("inlineCode",{parentName:"td"},"EXCEPT")),(0,r.kt)("td",{parentName:"tr",align:null},"All three are supported (with ",(0,r.kt)("inlineCode",{parentName:"td"},"ALL")," and ",(0,r.kt)("inlineCode",{parentName:"td"},"DISTINCT")," variants)."),(0,r.kt)("td",{parentName:"tr",align:null},"Not supported")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"OUTER JOIN")),(0,r.kt)("td",{parentName:"tr",align:null},"Both ",(0,r.kt)("inlineCode",{parentName:"td"},"LEFT")," and ",(0,r.kt)("inlineCode",{parentName:"td"},"RIGHT OUTER JOIN")," are supported."),(0,r.kt)("td",{parentName:"tr",align:null},"Only ",(0,r.kt)("inlineCode",{parentName:"td"},"LEFT OUTER JOIN")," supported (and necessary for query expressability).")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"<"),", ",(0,r.kt)("inlineCode",{parentName:"td"},"<="),", ",(0,r.kt)("inlineCode",{parentName:"td"},"="),", etc. operators"),(0,r.kt)("td",{parentName:"tr",align:null},"Can compare either complex values or scalar values."),(0,r.kt)("td",{parentName:"tr",align:null},"Only scalar values may be compared.")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"ORDER BY")),(0,r.kt)("td",{parentName:"tr",align:null},"Result sequencing is based on specific rules described in ",(0,r.kt)("a",{parentName:"td",href:"https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/orderby.html"},"SQL++ for Server ",(0,r.kt)("inlineCode",{parentName:"a"},"ORDER BY")," clause"),"."),(0,r.kt)("td",{parentName:"tr",align:null},"Result sequencing is based on the SQLite ordering described in ",(0,r.kt)("a",{parentName:"td",href:"https://sqlite.org/lang_select.html"},"SQLite select overview"),".",(0,r.kt)("br",null),(0,r.kt)("br",null)," The ordering of Dictionary and Array objects is based on binary ordering.")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"SELECT DISTINGCT")),(0,r.kt)("td",{parentName:"tr",align:null},"Supported"),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"SELECT DISTINCT VALUE")," is supported when the returned values are scalars.")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"CREATE INDEX")),(0,r.kt)("td",{parentName:"tr",align:null},"Supported"),(0,r.kt)("td",{parentName:"tr",align:null},"Not Supported")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"INSERT"),", ",(0,r.kt)("inlineCode",{parentName:"td"},"UPSERT"),", ",(0,r.kt)("inlineCode",{parentName:"td"},"DELETE")),(0,r.kt)("td",{parentName:"tr",align:null},"Supported"),(0,r.kt)("td",{parentName:"tr",align:null},"Not Supported"))))),(0,r.kt)("h2",{id:"boolean-logic-rules"},"Boolean Logic Rules"),(0,r.kt)("h3",{id:"sql-for-server"},"SQL++ for Server"),(0,r.kt)("p",null,"Couchbase Server operates in the same way as Couchbase Lite, except:"),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"MISSING"),", ",(0,r.kt)("inlineCode",{parentName:"li"},"NULL")," and ",(0,r.kt)("inlineCode",{parentName:"li"},"FALSE")," are ",(0,r.kt)("inlineCode",{parentName:"li"},"FALSE")),(0,r.kt)("li",{parentName:"ul"},"Numbers ",(0,r.kt)("inlineCode",{parentName:"li"},"0")," is ",(0,r.kt)("inlineCode",{parentName:"li"},"FALSE")),(0,r.kt)("li",{parentName:"ul"},"Empty strings, arrays, and objects are ",(0,r.kt)("inlineCode",{parentName:"li"},"FALSE")),(0,r.kt)("li",{parentName:"ul"},"All other values are ",(0,r.kt)("inlineCode",{parentName:"li"},"TRUE"))),(0,r.kt)("p",null,"You can choose to use Couchbase Server's SQL++ rules by using the\n",(0,r.kt)("inlineCode",{parentName:"p"},"TOBOOLEAN(expr)")," function to convert a value to its boolean value."),(0,r.kt)("h3",{id:"sql-for-mobile"},"SQL++ for Mobile"),(0,r.kt)("p",null,"SQL++ for Mobile's boolean logic rules are based on SQLite's, so:"),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"TRUE")," is ",(0,r.kt)("inlineCode",{parentName:"li"},"TRUE"),", and ",(0,r.kt)("inlineCode",{parentName:"li"},"FALSE")," is ",(0,r.kt)("inlineCode",{parentName:"li"},"FALSE")),(0,r.kt)("li",{parentName:"ul"},"Numbers ",(0,r.kt)("inlineCode",{parentName:"li"},"0")," or ",(0,r.kt)("inlineCode",{parentName:"li"},"0.0")," are ",(0,r.kt)("inlineCode",{parentName:"li"},"FALSE")),(0,r.kt)("li",{parentName:"ul"},"Arrays and dictionaries are ",(0,r.kt)("inlineCode",{parentName:"li"},"FALSE")),(0,r.kt)("li",{parentName:"ul"},"String and Blob are ",(0,r.kt)("inlineCode",{parentName:"li"},"TRUE")," if the values are casted as a non-zero or ",(0,r.kt)("inlineCode",{parentName:"li"},"FALSE"),"\nif the values are casted as ",(0,r.kt)("inlineCode",{parentName:"li"},"0")," or ",(0,r.kt)("inlineCode",{parentName:"li"},"0.0")," \u2014\u2009see:\n",(0,r.kt)("a",{parentName:"li",href:"https://sqlite.org/lang_expr.html"},"SQLITE's CAST and Boolean expressions")," for\nmore details."),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"NULL")," is ",(0,r.kt)("inlineCode",{parentName:"li"},"FALSE")),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"MISSING")," is ",(0,r.kt)("inlineCode",{parentName:"li"},"MISSING"))),(0,r.kt)("h3",{id:"logical-operations"},"Logical Operations"),(0,r.kt)("p",null,"In SQL++ for Mobile logical operations will return one of three possible values;\n",(0,r.kt)("inlineCode",{parentName:"p"},"TRUE"),", ",(0,r.kt)("inlineCode",{parentName:"p"},"FALSE"),", or ",(0,r.kt)("inlineCode",{parentName:"p"},"MISSING"),"."),(0,r.kt)("p",null,"Logical operations with the ",(0,r.kt)("inlineCode",{parentName:"p"},"MISSING")," value could result in ",(0,r.kt)("inlineCode",{parentName:"p"},"TRUE")," or ",(0,r.kt)("inlineCode",{parentName:"p"},"FALSE")," if\nthe result can be determined regardless of the missing value, otherwise the\nresult will be ",(0,r.kt)("inlineCode",{parentName:"p"},"MISSING"),"."),(0,r.kt)("p",null,"In SQL++ for Mobile \u2014\u2009unlike SQL++ for Server \u2014 ",(0,r.kt)("inlineCode",{parentName:"p"},"NULL")," is implicitly converted\nto ",(0,r.kt)("inlineCode",{parentName:"p"},"FALSE")," before evaluating logical operations. ",(0,r.kt)("a",{parentName:"p",href:"#table-2"},"Table 2")," summarizes the\nresult of logical operations with different operand values and also shows where\nthe Couchbase Server behavior differs."),(0,r.kt)(m,{id:2,title:"Logical Operations Comparison",mdxType:"Table"},(0,r.kt)("table",null,(0,r.kt)("thead",{parentName:"table"},(0,r.kt)("tr",{parentName:"thead"},(0,r.kt)("th",{parentName:"tr",align:null},"Operand",(0,r.kt)("br",null),"a"),(0,r.kt)("th",{parentName:"tr",align:null},"Operand",(0,r.kt)("br",null),"b"),(0,r.kt)("th",{parentName:"tr",align:null},"SQL ++ for Mobile ",(0,r.kt)("br",null),"a AND b"),(0,r.kt)("th",{parentName:"tr",align:null},"SQL ++ for Mobile ",(0,r.kt)("br",null),"a OR b"),(0,r.kt)("th",{parentName:"tr",align:null},"SQL ++ for Server",(0,r.kt)("br",null),"a AND b"),(0,r.kt)("th",{parentName:"tr",align:null},"SQL ++ for Server",(0,r.kt)("br",null),"a OR b"))),(0,r.kt)("tbody",{parentName:"table"},(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},"-"),(0,r.kt)("td",{parentName:"tr",align:null},"-")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},"-"),(0,r.kt)("td",{parentName:"tr",align:null},"-")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL")),(0,r.kt)("td",{parentName:"tr",align:null},"-")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},"-"),(0,r.kt)("td",{parentName:"tr",align:null},"-")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},"-"),(0,r.kt)("td",{parentName:"tr",align:null},"-")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},"-"),(0,r.kt)("td",{parentName:"tr",align:null},"-")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},"-"),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL"))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},"-"),(0,r.kt)("td",{parentName:"tr",align:null},"-")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL")),(0,r.kt)("td",{parentName:"tr",align:null},"-")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},"-"),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL"))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL"))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL"))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"TRUE")),(0,r.kt)("td",{parentName:"tr",align:null},"-"),(0,r.kt)("td",{parentName:"tr",align:null},"-")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},"-"),(0,r.kt)("td",{parentName:"tr",align:null},"-")),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"FALSE")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"NULL"))),(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null}),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},(0,r.kt)("inlineCode",{parentName:"td"},"MISSING")),(0,r.kt)("td",{parentName:"tr",align:null},"-"),(0,r.kt)("td",{parentName:"tr",align:null},"-"))))),(0,r.kt)("h2",{id:"crud-operations"},"CRUD Operations"),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},"SQL++ for Mobile only supports Read or Query operations."),(0,r.kt)("li",{parentName:"ul"},"SQL++ for Server fully supports CRUD operation.")),(0,r.kt)("h2",{id:"functions"},"Functions"),(0,r.kt)("h3",{id:"division-operator"},"Division Operator"),(0,r.kt)("table",null,(0,r.kt)("thead",{parentName:"table"},(0,r.kt)("tr",{parentName:"thead"},(0,r.kt)("th",{parentName:"tr",align:null},"SQL ++ for Server"),(0,r.kt)("th",{parentName:"tr",align:null},"SQL++ for Mobile"))),(0,r.kt)("tbody",{parentName:"table"},(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},"SQL++ for Server always performs float division regardless of the types of the operands.",(0,r.kt)("br",null),(0,r.kt)("br",null),"You can force this behavior in SQL++ for Mobile by using the ",(0,r.kt)("inlineCode",{parentName:"td"},"DIV(x, y)")," function."),(0,r.kt)("td",{parentName:"tr",align:null},"The operand types determine the division operation performed.",(0,r.kt)("br",null),(0,r.kt)("br",null),"If both are integers, integer division is used.",(0,r.kt)("br",null),(0,r.kt)("br",null)," If one is a floating number, then float division is used.")))),(0,r.kt)("h3",{id:"round-function"},"Round Function"),(0,r.kt)("table",null,(0,r.kt)("thead",{parentName:"table"},(0,r.kt)("tr",{parentName:"thead"},(0,r.kt)("th",{parentName:"tr",align:null},"SQL ++ for Server"),(0,r.kt)("th",{parentName:"tr",align:null},"SQL++ for Mobile"))),(0,r.kt)("tbody",{parentName:"table"},(0,r.kt)("tr",{parentName:"tbody"},(0,r.kt)("td",{parentName:"tr",align:null},"SQL++ for Server ",(0,r.kt)("inlineCode",{parentName:"td"},"ROUND()")," uses the Rounding to Nearest Even convention (for example, ",(0,r.kt)("inlineCode",{parentName:"td"},"ROUND(1.85)")," returns ",(0,r.kt)("inlineCode",{parentName:"td"},"1.8"),").",(0,r.kt)("br",null),(0,r.kt)("br",null),"You can force this behavior in Couchbase Lite by using the ",(0,r.kt)("inlineCode",{parentName:"td"},"ROUND_EVEN()")," function."),(0,r.kt)("td",{parentName:"tr",align:null},"The ",(0,r.kt)("inlineCode",{parentName:"td"},"ROUND()")," function returns a value to the given number of integer digits to the right of the decimal point (left if digits is negative).",(0,r.kt)("br",null),(0,r.kt)("br",null),"Digits are ",(0,r.kt)("inlineCode",{parentName:"td"},"0")," if not given.",(0,r.kt)("br",null),(0,r.kt)("br",null),"Midpoint values are handled using the Rounding Away From Zero convention, which rounds them to the next number away from zero (for example, ",(0,r.kt)("inlineCode",{parentName:"td"},"ROUND(1.85)")," returns ",(0,r.kt)("inlineCode",{parentName:"td"},"1.9"),").")))))}k.isMDXComponent=!0}}]);