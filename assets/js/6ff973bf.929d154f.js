"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[892],{3905:(e,n,t)=>{t.d(n,{Zo:()=>p,kt:()=>x});var r=t(7294);function a(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function i(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),t.push.apply(t,r)}return t}function o(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{};n%2?i(Object(t),!0).forEach((function(n){a(e,n,t[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):i(Object(t)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(t,n))}))}return e}function l(e,n){if(null==e)return{};var t,r,a=function(e,n){if(null==e)return{};var t,r,a={},i=Object.keys(e);for(r=0;r<i.length;r++)t=i[r],n.indexOf(t)>=0||(a[t]=e[t]);return a}(e,n);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)t=i[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(a[t]=e[t])}return a}var d=r.createContext({}),s=function(e){var n=r.useContext(d),t=n;return e&&(t="function"==typeof e?e(n):o(o({},n),e)),t},p=function(e){var n=s(e.components);return r.createElement(d.Provider,{value:n},e.children)},u="mdxType",c={inlineCode:"code",wrapper:function(e){var n=e.children;return r.createElement(r.Fragment,{},n)}},m=r.forwardRef((function(e,n){var t=e.components,a=e.mdxType,i=e.originalType,d=e.parentName,p=l(e,["components","mdxType","originalType","parentName"]),u=s(t),m=a,x=u["".concat(d,".").concat(m)]||u[m]||c[m]||i;return t?r.createElement(x,o(o({ref:n},p),{},{components:t})):r.createElement(x,o({ref:n},p))}));function x(e,n){var t=arguments,a=n&&n.mdxType;if("string"==typeof e||a){var i=t.length,o=new Array(i);o[0]=m;var l={};for(var d in n)hasOwnProperty.call(n,d)&&(l[d]=n[d]);l.originalType=e,l[u]="string"==typeof e?e:a,o[1]=l;for(var s=2;s<i;s++)o[s]=t[s];return r.createElement.apply(null,o)}return r.createElement.apply(null,t)}m.displayName="MDXCreateElement"},24:(e,n,t)=>{t.r(n),t.d(n,{assets:()=>d,contentTitle:()=>o,default:()=>x,frontMatter:()=>i,metadata:()=>l,toc:()=>s});var r=t(7462),a=(t(7294),t(3905));const i={description:"Couchbase mobile database indexes and indexing concepts",related_content:[{name:"Databases",url:"/databases"},{name:"Documents",url:"/documents"},{name:"Indexing",url:"/indexing"}]},o="Indexes",l={unversionedId:"indexing",id:"indexing",title:"Indexes",description:"Couchbase mobile database indexes and indexing concepts",source:"@site/docs/indexing.mdx",sourceDirName:".",slug:"/indexing",permalink:"/indexing",draft:!1,editUrl:"https://github.com/cbl-dart/cbl-dart/tree/main/docs/docs/indexing.mdx",tags:[],version:"current",frontMatter:{description:"Couchbase mobile database indexes and indexing concepts",related_content:[{name:"Databases",url:"/databases"},{name:"Documents",url:"/documents"},{name:"Indexing",url:"/indexing"}]},sidebar:"sidebar",previous:{title:"Using Full-Text Search",permalink:"/full-text-search"},next:{title:"Typed Data",permalink:"/typed-data"}},d={},s=[{value:"Introduction",id:"introduction",level:2},{value:"Creating a new index",id:"creating-a-new-index",level:2},{value:"SQL++",id:"sql",level:3},{value:"QueryBuilder",id:"querybuilder",level:3},{value:"Summary",id:"summary",level:2}],p=(u="CodeExample",function(e){return console.warn("Component "+u+" was not imported, exported, or provided by MDXProvider as global scope"),(0,a.kt)("div",e)});var u;const c={toc:s},m="wrapper";function x(e){let{components:n,...t}=e;return(0,a.kt)(m,(0,r.Z)({},c,t,{components:n,mdxType:"MDXLayout"}),(0,a.kt)("h1",{id:"indexes"},"Indexes"),(0,a.kt)("metaheader",null),(0,a.kt)("h2",{id:"introduction"},"Introduction"),(0,a.kt)("p",null,"Before we begin querying documents, let's briefly mention the importance of\nhaving an appropriate and balanced approach to indexes."),(0,a.kt)("p",null,"Creating indexes can speed up the performance of queries. A query will typically\nreturn results more quickly if it can take advantage of an existing database\nindex to search, narrowing down the set of documents to be examined."),(0,a.kt)("admonition",{title:"Constraints",type:"note"},(0,a.kt)("p",{parentName:"admonition"},"Couchbase Lite does not currently support partial value indexes; indexes with\nnon-property expressions. You should only index with properties that you plan to\nuse in the query.")),(0,a.kt)("h2",{id:"creating-a-new-index"},"Creating a new index"),(0,a.kt)("p",null,"You can use SQL++ or QueryBuilder syntaxes to create an index."),(0,a.kt)("p",null,(0,a.kt)("a",{parentName:"p",href:"#example-2"},"Example 2")," creates a new index for the ",(0,a.kt)("inlineCode",{parentName:"p"},"type")," and ",(0,a.kt)("inlineCode",{parentName:"p"},"name")," properties, shown\nin this data model:"),(0,a.kt)(p,{id:1,title:"Data Model",mdxType:"CodeExample"},(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-json"},'{\n  "_id": "hotel123",\n  "type": "hotel",\n  "name": "The Michigander",\n  "overview": "Ideally situated for exploration of the Motor City and the wider state of Michigan. Tripadvisor rated the hotel ...",\n  "state": "Michigan"\n}\n'))),(0,a.kt)("h3",{id:"sql"},"SQL++"),(0,a.kt)("p",null,"The code to create the index will look something like this:"),(0,a.kt)(p,{id:2,title:"Create index with SQL++",mdxType:"CodeExample"},(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-dart"},"final config = ValueIndexConfiguration(['type', 'name']);\nawait collection.createIndex('TypeNameIndex', config);\n"))),(0,a.kt)("h3",{id:"querybuilder"},"QueryBuilder"),(0,a.kt)("p",null,"The code to create the index will look something like this:"),(0,a.kt)(p,{id:3,title:"Create index QueryBuilder",mdxType:"CodeExample"},(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-dart"},"final typeExpression = Expression.property('type');\nfinal nameExpression = Expression.property('name');\nfinal valueIndexItems = {\n    ValueIndexItem.expression(typeExpression),\n    ValueIndexItem.expression(nameExpression),\n};\nfinal index = IndexBuilder.valueIndex(valueIndexItems);\nawait collection.createIndex('TypeNameIndex', index);\n"))),(0,a.kt)("h2",{id:"summary"},"Summary"),(0,a.kt)("p",null,"When planning the indexes you need for your database, remember that while\nindexes make queries faster, they may also:"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Make writes slightly slower, because each index must be updated whenever a\ndocument is updated."),(0,a.kt)("li",{parentName:"ul"},"Make your Couchbase Lite database slightly larger.")),(0,a.kt)("p",null,"So too many indexes may hurt performance. Optimal performance depends on\ndesigning and creating the ",(0,a.kt)("em",{parentName:"p"},"right")," indexes to go along with your queries."))}x.isMDXComponent=!0}}]);