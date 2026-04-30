import type { Component } from 'vue'
import ParagraphBlock from './ParagraphBlock.vue'
import CodeBlock from './CodeBlock.vue'
import AdmonitionBlock from './AdmonitionBlock.vue'
import TableBlock from './TableBlock.vue'
import ImageBlock from './ImageBlock.vue'
import CalloutListBlock from './CalloutListBlock.vue'
import QandABlock from './QandABlock.vue'
import BlockquoteBlock from './BlockquoteBlock.vue'
import ListBlocks from './ListBlocks.vue'
import SidebarBlock from './SidebarBlock.vue'
import EquationBlock from './EquationBlock.vue'
import FootnotesBlock from './FootnotesBlock.vue'
import AnnotationBlock from './AnnotationBlock.vue'
import GlossaryBlocks from './GlossaryBlocks.vue'
import BiblioBlock from './BiblioBlock.vue'
import IndexBlock from './IndexBlock.vue'
import StepBlock from './StepBlock.vue'
import RefSectionBlock from './RefSectionBlock.vue'
import SynopsisBlock from './SynopsisBlock.vue'
import FallbackBlock from './FallbackBlock.vue'

const BLOCK_COMPONENTS: Record<string, Component> = {
  paragraph: ParagraphBlock,
  code_block: CodeBlock,
  admonition: AdmonitionBlock,
  table: TableBlock,
  image: ImageBlock,
  calloutlist: CalloutListBlock,
  callout: CalloutListBlock,
  qandaset: QandABlock,
  qandaentry: QandABlock,
  question: QandABlock,
  answer: QandABlock,
  blockquote: BlockquoteBlock,
  ordered_list: ListBlocks,
  bullet_list: ListBlocks,
  dl: ListBlocks,
  sidebar: SidebarBlock,
  equation: EquationBlock,
  footnotes: FootnotesBlock,
  annotation: AnnotationBlock,
  gloss_entry: GlossaryBlocks,
  gloss_term: GlossaryBlocks,
  gloss_def: GlossaryBlocks,
  gloss_see: GlossaryBlocks,
  gloss_see_also: GlossaryBlocks,
  biblio_entry: BiblioBlock,
  index_div: IndexBlock,
  index_entry: IndexBlock,
  step: StepBlock,
  substeps: StepBlock,
  refsection: RefSectionBlock,
  synopsis: SynopsisBlock,
}

export function getBlockComponent(type: string): Component {
  return BLOCK_COMPONENTS[type] ?? FallbackBlock
}
