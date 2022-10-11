import React, { PropsWithChildren, ReactNode } from 'react'
import FigureBase from '../FigureBase'

export interface FigureProps extends PropsWithChildren {
  id: number
  title?: string
  richTitle?: ReactNode
}

export default function Figure(props: FigureProps) {
  return <FigureBase type="figure" {...props}></FigureBase>
}
