import React, { Fragment } from 'react'
import { useMDXContent } from '../context'
import styles from './styles.module.css'

interface RelatedContentItem {
  name: string
  url: string
}

export default function MetaHeader() {
  const content = useMDXContent()
  const frontMatter = content.frontMatter
  const description = frontMatter.description
  const abstract = frontMatter['abstract'] as string | undefined
  const relatedContent = frontMatter['related_content'] as
    | RelatedContentItem[]
    | undefined

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
      {abstract && (
        <div>
          Abstract — <em>{abstract}</em>
        </div>
      )}
      {relatedContent && (
        <div>
          Related Content —{' '}
          {relatedContent.map(({ name, url }, index) => {
            return (
              <Fragment key={index}>
                <a href={url}>{name}</a>
                {index < relatedContent.length - 1 && ' | '}
              </Fragment>
            )
          })}
        </div>
      )}
    </div>
  )
}
