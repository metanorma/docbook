// Lazy-loaded PrismJS syntax highlighter.
// Prism and language grammars are loaded only when the first code block renders,
// keeping the initial bundle free of parsing cost.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
let Prism: any = null
const loadedLanguages = new Set<string>()

async function ensurePrism(): Promise<void> {
  if (Prism) return
  const mod = await import('prismjs')
  Prism = mod.default ?? mod
  // Make globally available for debugging
  ;(window as any).Prism = Prism
}

async function loadLanguage(lang: string): Promise<void> {
  if (loadedLanguages.has(lang)) return
  loadedLanguages.add(lang)

  const langMap: Record<string, () => Promise<unknown>> = {
    ruby:       () => import('prismjs/components/prism-ruby'),
    javascript: () => import('prismjs/components/prism-javascript'),
    typescript: () => import('prismjs/components/prism-typescript'),
    python:     () => import('prismjs/components/prism-python'),
    bash:       () => import('prismjs/components/prism-bash'),
    json:       () => import('prismjs/components/prism-json'),
    yaml:       () => import('prismjs/components/prism-yaml'),
    'xml-doc':  () => import('prismjs/components/prism-xml-doc'),
    css:        () => import('prismjs/components/prism-css'),
  }

  const loader = langMap[lang]
  if (loader) {
    await loader()
  }
}

const ALIASES: Record<string, string> = {
  rb: 'ruby', js: 'javascript', ts: 'typescript',
  py: 'python', sh: 'bash', shell: 'bash',
  yml: 'yaml', xslt: 'xslt',
}

export async function highlightCode(code: string, language: string | undefined): Promise<string> {
  if (!code) return ''

  const lang = ALIASES[language?.toLowerCase() ?? ''] ?? language ?? 'plaintext'

  await ensurePrism()
  await loadLanguage(lang)

  try {
    if (Prism.languages[lang]) {
      return Prism.highlight(code, Prism.languages[lang], lang)
    }
  } catch (e) {
    console.warn('Highlighting failed for', lang, e)
  }

  // Escape HTML for plain text
  const div = document.createElement('div')
  div.textContent = code
  return div.innerHTML
}

// Synchronous fallback for when async highlighting isn't needed yet
export function highlightCodeSync(code: string, language: string | undefined): string {
  if (!code) return ''
  const lang = ALIASES[language?.toLowerCase() ?? ''] ?? language ?? 'plaintext'

  if (Prism?.languages?.[lang]) {
    try {
      return Prism.highlight(code, Prism.languages[lang], lang)
    } catch {}
  }

  const div = document.createElement('div')
  div.textContent = code
  return div.innerHTML
}

export function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}
