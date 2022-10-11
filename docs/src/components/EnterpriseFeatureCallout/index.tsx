import Admonition from '@theme-original/Admonition'
import React from 'react'

export default function EnterpriseFeatureCallout() {
  return (
    <Admonition type="info" title="Important">
      <p>
        This feature is an{' '}
        <a
          href="https://www.couchbase.com/products/editions#cmobile"
          target="_blank"
          rel="noopener noreferrer"
        >
          Enterprise Edition
        </a>{' '}
        feature.
      </p>
    </Admonition>
  )
}
