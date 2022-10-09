import React, { PropsWithChildren, ReactNode } from 'react'
import styles from './styles.module.css'

export interface CodeExampleProps extends PropsWithChildren {
  id: number
  title?: string
  richTitle?: ReactNode
}

export default function CodeExample(props: CodeExampleProps) {
  return (
    <figure className={styles.codeExample} id={`example-${props.id}`}>
      <figcaption className={styles.caption}>
        Example {props.id}. {props.title ?? props.richTitle}
      </figcaption>
      {props.children}
    </figure>
  )
}
