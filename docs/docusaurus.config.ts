import type * as Preset from '@docusaurus/preset-classic'
import type { Config } from '@docusaurus/types'
import { themes as prismThemes } from 'prism-react-renderer'
import { codeLinks } from './src/remark/code-links'
import { figureLinks } from './src/remark/figure-links'
import { metaHeader } from './src/remark/meta-header'

/**
 * Packages for which to fetch the latest version (including pre-releases)
 * from pub.dev at build time. The versions are made available via
 * `siteConfig.customFields.pubPackageVersions`.
 */
const pubPackages = ['cbl', 'cbl_generator']

async function fetchLatestPubVersions(
  packages: string[],
): Promise<Record<string, string>> {
  const versions: Record<string, string> = {}
  await Promise.all(
    packages.map(async (pkg) => {
      const res = await fetch(`https://pub.dev/api/packages/${pkg}`)
      const data = await res.json()
      // data.versions is ordered chronologically — last entry is the newest.
      const allVersions: { version: string }[] = data.versions
      versions[pkg] = allVersions[allVersions.length - 1].version
    }),
  )
  return versions
}

export default async function createConfigAsync(): Promise<Config> {
  const pubPackageVersions = await fetchLatestPubVersions(pubPackages)

  return {
    title: 'Couchbase Lite for Dart & Flutter',
    tagline: 'Couchbase Lite for Dart & Flutter',
    url: 'https://cbl-dart.dev',
    baseUrl: '/',
    onBrokenLinks: 'throw',
    trailingSlash: true,
    favicon: 'img/logo.png',

    organizationName: 'cbl-dart',
    projectName: 'cbl-dart',

    customFields: {
      pubPackageVersions,
    },

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
      hooks: {
        onBrokenMarkdownLinks: 'warn',
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
      announcementBar: {
        id: 'v4_release',
        content:
          '🎉 <b>Couchbase Lite for Dart v4 is here!</b> If you\'re upgrading from v3, check out the <a href="/migration-v3-to-v4/">migration guide</a>.',
        backgroundColor: '#e6f2ff',
        textColor: '#003d75',
        isCloseable: true,
      },
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
  }
}
