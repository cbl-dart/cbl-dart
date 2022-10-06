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
          label: 'Couchbase Lite Swift Docs',
          href: 'https://docs.couchbase.com/couchbase-lite/current/swift/quickstart.html',
        },
      ],
    },
  ],
}

module.exports = sidebars
