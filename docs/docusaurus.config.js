// @ts-check

require('ts-node').register()

const lightCodeTheme = require('prism-react-renderer/themes/github')
const darkCodeTheme = require('prism-react-renderer/themes/dracula')
const { figureLinks } = require('./src/remark/figure-links')
const { metaHeader } = require('./src/remark/meta-header')
const { codeLinks } = require('./src/remark/code-links')

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Couchbase Lite for Dart',
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
    }),
}

module.exports = config
