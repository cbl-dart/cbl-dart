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
      id: 'general-concepts',
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
      items: [
        {
          type: 'doc',
          id: 'queries/query-builder',
        },
        {
          type: 'doc',
          id: 'queries/sqlplusplus-mobile',
        },
        {
          type: 'doc',
          id: 'queries/sqlplusplus-server-diff',
        },
        {
          type: 'doc',
          id: 'queries/sqlplusplus-query-builder-diff',
        },
        {
          type: 'doc',
          id: 'queries/query-result-sets',
        },
        {
          type: 'doc',
          id: 'queries/live-queries',
        },
        {
          type: 'doc',
          id: 'queries/query-troubleshooting',
        },
      ],
    },
    {
      type: 'doc',
      id: 'full-text-search',
    },
    {
      type: 'doc',
      id: 'indexing',
    },
    {
      type: 'doc',
      id: 'typed-data',
    },
    {
      type: 'doc',
      id: 'usage-examples',
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
      ],
    },
  ],
}

module.exports = sidebars
