import React, { PropsWithChildren, ReactNode } from 'react'
import FigureBase from '../FigureBase'

export interface TableProps extends PropsWithChildren {
  id: number
  title?: string
  richTitle?: ReactNode
}

export default function Table(props: TableProps) {
  return <FigureBase type="table" {...props}></FigureBase>
}
