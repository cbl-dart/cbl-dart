// @ts-check

require('ts-node').register()

const lightCodeTheme = require('prism-react-renderer/themes/github')
const darkCodeTheme = require('prism-react-renderer/themes/dracula')
const { figureLinks } = require('./src/remark/figure-links')
const { metaHeader } = require('./src/remark/meta-header')
const { codeLinks } = require('./src/remark/code-links')

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Couchbase Lite for Dart & Flutter',
  tagline: 'Couchbase Lite for Dart & Flutter',
  url: 'https://cbl-dart.dev',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  trailingSlash: true,
  favicon: 'img/logo.png',

  organizationName: 'cbl-dart',
  projectName: 'cbl-dart',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          routeBasePath: '/',
          editUrl: 'https://github.com/cbl-dart/cbl-dart/tree/main/docs/',
          remarkPlugins: [figureLinks, metaHeader, codeLinks],
        },
        blog: false,
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
        sitemap: {
          changefreq: 'hourly',
        },
        gtag: {
          trackingID: 'G-MX69D45K0L',
          anonymizeIP: true,
        },
        googleTagManager: {
          containerId: 'GTM-KNLPFXH',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      colorMode: {
        respectPrefersColorScheme: true,
      },
      navbar: {
        title: 'Couchbase Lite for Dart',
        logo: {
          src: '/img/logo.png',
          alt: 'Couchbase Logo',
        },
        items: [
          {
            href: 'https://github.com/cbl-dart/cbl-dart',
            label: 'GitHub',
            position: 'right',
          },
        ],
        hideOnScroll: true,
      },
      docs: {
        sidebar: {
          autoCollapseCategories: false,
        },
      },
      footer: {
        style: 'dark',
        copyright: `Copyright © ${new Date().getFullYear()} Couchbase Lite for Dart`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
        additionalLanguages: ['dart'],
      },
      algolia: {
        appId: 'T2JGR5IO20',
        apiKey: 'af3e6f09aef0030c6ae7fc5c602e4cfa',
        indexName: 'cbl-dart',
      },
    }),
}

module.exports = config
