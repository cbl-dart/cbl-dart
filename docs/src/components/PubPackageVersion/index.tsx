import type { ReactNode } from 'react'
import useDocusaurusContext from '@docusaurus/useDocusaurusContext'

/**
 * Returns the latest version of a pub.dev package from site config.
 *
 * The versions are fetched at build time in `docusaurus.config.ts` and stored
 * in `customFields.pubPackageVersions`.
 */
export function usePubPackageVersion(packageName: string): string {
  const { siteConfig } = useDocusaurusContext()
  const versions = siteConfig.customFields?.pubPackageVersions as
    | Record<string, string>
    | undefined
  const version = versions?.[packageName]
  if (!version) {
    throw new Error(
      `No pub.dev version found for package "${packageName}". ` +
        `Make sure it is listed in pubPackages in docusaurus.config.ts.`,
    )
  }
  return version
}

/**
 * Renders the latest version of a pub.dev package as inline text.
 */
export default function PubPackageVersion({
  packageName,
}: {
  packageName: string
}): ReactNode {
  return <>{usePubPackageVersion(packageName)}</>
}
