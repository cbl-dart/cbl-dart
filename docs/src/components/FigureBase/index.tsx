import React, { PropsWithChildren, ReactNode } from 'react'
import styles from './styles.module.css'

export interface FigureBaseProps extends PropsWithChildren {
  id: number
  type: 'example' | 'figure'
  title?: string
  richTitle?: ReactNode
}

export default function FigureBase(props: FigureBaseProps) {
  let typeDisplay = props.type === 'example' ? 'Example' : 'Figure'

  return (
    <figure className={styles.figure} id={`${props.type}-${props.id}`}>
      <figcaption className={styles.caption}>
        {typeDisplay} {props.id}. {props.title ?? props.richTitle}
      </figcaption>
      {props.children}
    </figure>
  )
}
