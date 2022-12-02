"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[86],{3905:(e,t,n)=>{n.d(t,{Zo:()=>p,kt:()=>c});var r=n(7294);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function o(e,t){if(null==e)return{};var n,r,a=function(e,t){if(null==e)return{};var n,r,a={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var d=r.createContext({}),u=function(e){var t=r.useContext(d),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},p=function(e){var t=u(e.components);return r.createElement(d.Provider,{value:t},e.children)},s={inlineCode:"code",wrapper:function(e){var t=e.children;return r.createElement(r.Fragment,{},t)}},m=r.forwardRef((function(e,t){var n=e.components,a=e.mdxType,i=e.originalType,d=e.parentName,p=o(e,["components","mdxType","originalType","parentName"]),m=u(n),c=a,f=m["".concat(d,".").concat(c)]||m[c]||s[c]||i;return n?r.createElement(f,l(l({ref:t},p),{},{components:n})):r.createElement(f,l({ref:t},p))}));function c(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var i=n.length,l=new Array(i);l[0]=m;var o={};for(var d in t)hasOwnProperty.call(t,d)&&(o[d]=t[d]);o.originalType=e,o.mdxType="string"==typeof e?e:a,l[1]=o;for(var u=2;u<i;u++)l[u]=n[u];return r.createElement.apply(null,l)}return r.createElement.apply(null,n)}m.displayName="MDXCreateElement"},7715:(e,t,n)=>{n.r(t),n.d(t,{assets:()=>d,contentTitle:()=>l,default:()=>c,frontMatter:()=>i,metadata:()=>o,toc:()=>u});var r=n(7462),a=(n(7294),n(3905));const i={description:"Differences between Couchbase Lite's QueryBuilder and SQL++ for Mobile",related_content:[{name:"SQL++ for Mobile",url:"/queries/sqlplusplus-mobile"},{name:"QueryBuilder",url:"/queries/query-builder"},{name:"Indexes",url:"/indexing"}]},l="SQL++ and QueryBuilder Differences",o={unversionedId:"queries/sqlplusplus-query-builder-diff",id:"queries/sqlplusplus-query-builder-diff",title:"SQL++ and QueryBuilder Differences",description:"Differences between Couchbase Lite's QueryBuilder and SQL++ for Mobile",source:"@site/docs/queries/sqlplusplus-query-builder-diff.mdx",sourceDirName:"queries",slug:"/queries/sqlplusplus-query-builder-diff",permalink:"/queries/sqlplusplus-query-builder-diff",draft:!1,editUrl:"https://github.com/cbl-dart/cbl-dart/tree/main/docs/docs/queries/sqlplusplus-query-builder-diff.mdx",tags:[],version:"current",frontMatter:{description:"Differences between Couchbase Lite's QueryBuilder and SQL++ for Mobile",related_content:[{name:"SQL++ for Mobile",url:"/queries/sqlplusplus-mobile"},{name:"QueryBuilder",url:"/queries/query-builder"},{name:"Indexes",url:"/indexing"}]},sidebar:"sidebar",previous:{title:"SQL++ for Mobile and Server Differences",permalink:"/queries/sqlplusplus-server-diff"},next:{title:"Query Result Sets",permalink:"/queries/query-result-sets"}},d={},u=[],p=(s="Table",function(e){return console.warn("Component "+s+" was not imported, exported, or provided by MDXProvider as global scope"),(0,a.kt)("div",e)});var s;const m={toc:u};function c(e){let{components:t,...n}=e;return(0,a.kt)("wrapper",(0,r.Z)({},m,n,{components:t,mdxType:"MDXLayout"}),(0,a.kt)("h1",{id:"sql-and-querybuilder-differences"},"SQL++ and QueryBuilder Differences"),(0,a.kt)("metaheader",null),(0,a.kt)("admonition",{type:"important"},(0,a.kt)("p",{parentName:"admonition"},"N1QL is Couchbase's implementation of the developing SQL++ standard. As such the\nterms N1QL and SQL++ are used interchangeably in all Couchbase documentation\nunless explicitly stated otherwise.")),(0,a.kt)("p",null,"Couchbase Lite's SQL++ for Mobile supports all QueryBuilder features. See\n",(0,a.kt)("a",{parentName:"p",href:"#table-1"},"Table 1")," for the features supported by SQL++ but not by QueryBuilder."),(0,a.kt)(p,{id:1,title:"QueryBuilder Differences",mdxType:"Table"},(0,a.kt)("table",null,(0,a.kt)("thead",{parentName:"table"},(0,a.kt)("tr",{parentName:"thead"},(0,a.kt)("th",{parentName:"tr",align:null},"Category"),(0,a.kt)("th",{parentName:"tr",align:null},"Components"))),(0,a.kt)("tbody",{parentName:"table"},(0,a.kt)("tr",{parentName:"tbody"},(0,a.kt)("td",{parentName:"tr",align:null},"Conditional Operator"),(0,a.kt)("td",{parentName:"tr",align:null},(0,a.kt)("inlineCode",{parentName:"td"},"CASE(WHEN \u2026\u200b THEN \u2026\u200b ELSE ..)"))),(0,a.kt)("tr",{parentName:"tbody"},(0,a.kt)("td",{parentName:"tr",align:null},"Array Functions"),(0,a.kt)("td",{parentName:"tr",align:null},(0,a.kt)("inlineCode",{parentName:"td"},"ARRAY_AGG"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ARRAY_AVG"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ARRAY_COUNT"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ARRAY_IFNULL"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ARRAY_MAX"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ARRAY_MIN"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ARRAY_SUM"))),(0,a.kt)("tr",{parentName:"tbody"},(0,a.kt)("td",{parentName:"tr",align:null},"Conditional Functions"),(0,a.kt)("td",{parentName:"tr",align:null},(0,a.kt)("inlineCode",{parentName:"td"},"IFMISSING"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"IFMISSINGORNULL"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"IFNULL"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"MISSINGIF"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"NULLIF"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"Match Functions"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"DIV"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"IDIV"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ROUND_EVEN"))),(0,a.kt)("tr",{parentName:"tbody"},(0,a.kt)("td",{parentName:"tr",align:null},"Pattern Matching Functions"),(0,a.kt)("td",{parentName:"tr",align:null},(0,a.kt)("inlineCode",{parentName:"td"},"REGEXP_CONTAINS"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"REGEXP_LIKE"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"REGEXP_POSITION"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"REGEXP_REPLACE"))),(0,a.kt)("tr",{parentName:"tbody"},(0,a.kt)("td",{parentName:"tr",align:null},"Type Checking Functions"),(0,a.kt)("td",{parentName:"tr",align:null},(0,a.kt)("inlineCode",{parentName:"td"},"ISARRAY"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ISATOM"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ISBOOLEAN"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ISNUMBER"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ISOBJECT"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"ISSTRING"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"TYPE"))),(0,a.kt)("tr",{parentName:"tbody"},(0,a.kt)("td",{parentName:"tr",align:null},"Type Conversion Functions"),(0,a.kt)("td",{parentName:"tr",align:null},(0,a.kt)("inlineCode",{parentName:"td"},"TOARRAY"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"TOATOM"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"TOBOOLEAN"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"TONUMBER"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"TOOBJECT"),", ",(0,a.kt)("inlineCode",{parentName:"td"},"TOSTRING")))))))}c.isMDXComponent=!0}}]);