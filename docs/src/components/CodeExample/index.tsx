import React, { PropsWithChildren, ReactNode } from 'react'
import FigureBase from '../FigureBase'

export interface CodeExampleProps extends PropsWithChildren {
  id: number
  title?: string
  richTitle?: ReactNode
}

export default function CodeExample(props: CodeExampleProps) {
  return <FigureBase type="example" {...props}></FigureBase>
}
