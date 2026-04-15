import Prism from 'prismjs'

// Import language components
import 'prismjs/components/prism-ruby'
import 'prismjs/components/prism-javascript'
import 'prismjs/components/prism-typescript'
import 'prismjs/components/prism-python'
import 'prismjs/components/prism-bash'
import 'prismjs/components/prism-json'
import 'prismjs/components/prism-yaml'
import 'prismjs/components/prism-xml-doc'
import 'prismjs/components/prism-css'

// Make Prism globally available for debugging
if (typeof window !== 'undefined') {
  (window as any).Prism = Prism;
}

export function highlightCode(code: string, language: string | undefined): string {
  if (!code) return ''

  const lang = language || 'plaintext'

  // Map common language aliases
  const langMap: Record<string, string> = {
    'rb': 'ruby',
    'js': 'javascript',
    'ts': 'typescript',
    'py': 'python',
    'sh': 'bash',
    'shell': 'bash',
    'yml': 'yaml',
    'xslt': 'xslt',
  }

  const prismLang = langMap[lang.toLowerCase()] || lang

  try {
    if (Prism.languages[prismLang]) {
      return Prism.highlight(code, Prism.languages[prismLang], prismLang)
    }
  } catch (e) {
    console.warn('Highlighting failed for', prismLang, e)
  }

  // Escape HTML for plain text
  const div = document.createElement('div')
  div.textContent = code
  return div.innerHTML
}

export function escapeHtml(text: string): string {
  const div = document.createElement('div')
  div.textContent = text
  return div.innerHTML
}
