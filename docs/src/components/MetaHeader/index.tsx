import React from 'react'
import { useMDXContent } from '../context'
import styles from './styles.module.css'

export default function MetaHeader() {
  const content = useMDXContent()
  const frontMatter = content.frontMatter
  const description = frontMatter.description
  const relatedContent = frontMatter.related_content

  if (!description && !relatedContent) {
    return <></>
  }

  return (
    <div className={styles.metaHeader}>
      {description && (
        <div>
          Description — <em>{description}</em>
        </div>
      )}
      {relatedContent && (
        <div>
          Related Content —{' '}
          {relatedContent.map(({ name, url }, index) => {
            return (
              <>
                <a href={url}>{name}</a>
                {index < relatedContent.length - 1 && ' | '}
              </>
            )
          })}
        </div>
      )}
    </div>
  )
}
