import TabItem from '@theme/TabItem'
import Tabs from '@theme/Tabs'
import React, { PropsWithChildren } from 'react'

export interface APITabsProps extends PropsWithChildren {
  api: 'Async' | 'Sync'
}

export function APITab(props: APITabsProps) {
  return <>{props.children}</>
}

export interface APITabsProps extends PropsWithChildren {
  children: readonly React.ReactElement<APITabsProps>[]
}

export function APITabs(props: APITabsProps) {
  return (
    <Tabs groupId="async-sync-api">
      {React.Children.map(props.children, (child) => {
        if (!isValidAPITab(child)) {
          throw new Error(
            'Every APITab must have an api property set to "Async" or "Sync".'
          )
        }

        return (
          <TabItem
            value={child.props.api.toLowerCase()}
            label={child.props.api}
            children={child.props.children}
          ></TabItem>
        )
      })}
    </Tabs>
  )
}

function isValidAPITab(child: React.ReactElement) {
  return !!child.props.api
}
