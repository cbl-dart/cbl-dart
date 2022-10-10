// @ts-check

const pubDevDocsLink = (packageName) =>
  /** @type any */ ({
    type: 'link',
    label: `${packageName} API`,
    href: `https://pub.dev/documentation/${packageName}/latest/${packageName}/${packageName}-library.html`,
  })

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  sidebar: [
    {
      type: 'doc',
      id: 'overview',
    },
    {
      type: 'doc',
      id: 'install',
    },
    {
      type: 'doc',
      id: 'key-concepts',
    },
    {
      type: 'doc',
      id: 'databases',
    },
    {
      type: 'doc',
      id: 'prebuilt-database',
    },
    {
      type: 'doc',
      id: 'documents',
    },
    {
      type: 'doc',
      id: 'blobs',
    },
    {
      type: 'category',
      label: 'Queries',
      items:[
        {
          type: 'doc',
          id: 'querybuilder'
        },
        {
          type: 'doc',
          id:'sqlplusplus-mobile'
        },
        {
          type: 'doc',
          id:'sqlplusplus-server-differences'
        },
        {
          type: 'doc',
          id:'sqlplusplus-querybuilder-differences'
        },
        {
          type: 'doc',
          id:'query-resultsets'
        },
        {
          type: 'doc',
          id:'live-queries'
        },
        {
          type: 'doc',
          id:'query-troubleshooting'
        },
      ]
    },
    {
      type: 'doc',
      id: 'usage-examples',
    },
    {
      type: 'doc',
      id: 'typed-data',
    },
    {
      type: 'doc',
      id: 'instrumentation',
    },
    {
      type: 'doc',
      id: 'supported-platforms',
    },
    {
      type: 'category',
      label: 'References',
      collapsible: false,
      items: [
        pubDevDocsLink('cbl'),
        pubDevDocsLink('cbl_dart'),
        pubDevDocsLink('cbl_flutter'),
        pubDevDocsLink('cbl_sentry'),
        {
          type: 'link',
          label: 'Couchbase Lite for Swift Docs',
          href: 'https://docs.couchbase.com/couchbase-lite/current/swift/quickstart.html',
        },
      ],
    },
  ],
}

module.exports = sidebars
