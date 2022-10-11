import { APITab, APITabs } from '@site/src/components/APITabs'
import CodeExample from '@site/src/components/CodeExample'
import { EmbedderTab, EmbedderTabs } from '@site/src/components/EmbedderTabs'
import EnterpriseFeatureCallout from '@site/src/components/EnterpriseFeatureCallout'
import Figure from '@site/src/components/Figure'
import MetaHeader from '@site/src/components/MetaHeader'
import MDXComponents from '@theme-original/MDXComponents'

export default {
  ...MDXComponents,
  CodeExample: CodeExample,
  Figure: Figure,
  metaheader: MetaHeader,
  EnterpriseFeatureCallout: EnterpriseFeatureCallout,
  APITab: APITab,
  APITabs: APITabs,
  EmbedderTab: EmbedderTab,
  EmbedderTabs: EmbedderTabs,
}
