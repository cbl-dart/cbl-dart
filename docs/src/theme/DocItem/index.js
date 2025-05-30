import DocItem from '@theme-original/DocItem'

import { MDXContent } from '@site/src/components/context'

export default function DocItemWrapper(props) {
  return (
    <MDXContent.Provider value={props.content}>
      <DocItem {...props} />
    </MDXContent.Provider>
  )
}
