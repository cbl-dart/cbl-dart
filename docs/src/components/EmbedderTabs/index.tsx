import TabItem from '@theme/TabItem'
import Tabs from '@theme/Tabs'
import React, { PropsWithChildren } from 'react'

export interface EmbedderTabsProps extends PropsWithChildren {
  embedder: 'Dart' | 'Flutter'
}

export function EmbedderTab(props: EmbedderTabsProps) {
  return <>{props.children}</>
}

export interface EmbedderTabsProps extends PropsWithChildren {
  children: readonly React.ReactElement<EmbedderTabsProps>[]
}

export function EmbedderTabs(props: EmbedderTabsProps) {
  return (
    <Tabs groupId="embedder">
      {React.Children.map(props.children, function (child) {
        if (!isValidEmbedderTab(child)) {
          throw new Error(
            'Every EmbedderTab must have an embedder property set to "Dart" or "Flutter".'
          )
        }

        return (
          <TabItem
            value={child.props.embedder.toLowerCase()}
            label={child.props.embedder}
            children={child.props.children}
          ></TabItem>
        )
      })}
    </Tabs>
  )
}

function isValidEmbedderTab(child: React.ReactElement) {
  return !!child.props.embedder
}
