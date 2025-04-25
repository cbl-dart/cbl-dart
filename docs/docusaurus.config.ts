import type * as Preset from '@docusaurus/preset-classic'
import type { Config } from '@docusaurus/types'
import { themes as prismThemes } from 'prism-react-renderer'
import { codeLinks } from './src/remark/code-links'
import { figureLinks } from './src/remark/figure-links'
import { metaHeader } from './src/remark/meta-header'

export default {
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

  markdown: {
    mdx1Compat: {
      comments: false,
      admonitions: false,
      headingIds: false,
    },
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/',
          editUrl: 'https://github.com/cbl-dart/cbl-dart/tree/main/docs/',
          remarkPlugins: [figureLinks, metaHeader, codeLinks],
        },
        theme: {
          customCss: './src/css/custom.css',
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
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
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
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'diff', 'json', 'dart'],
    },
    algolia: {
      appId: 'T2JGR5IO20',
      apiKey: 'af3e6f09aef0030c6ae7fc5c602e4cfa',
      indexName: 'cbl-dart',
    },
  } satisfies Preset.ThemeConfig,
} satisfies Config
