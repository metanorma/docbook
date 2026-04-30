import { onMounted, onUnmounted, type Ref } from 'vue'

/**
 * Traps keyboard focus within a container element.
 * Tab/Shift+Tab cycle through focusable elements inside the container.
 * Escape triggers the optional onEscape callback.
 */
export function useFocusTrap(
  containerRef: Ref<HTMLElement | null>,
  options: { onEscape?: () => void } = {}
) {
  let previouslyFocused: HTMLElement | null = null

  const FOCUSABLE = [
    'a[href]', 'button:not([disabled])', 'input:not([disabled])',
    'select:not([disabled])', 'textarea:not([disabled])',
    '[tabindex]:not([tabindex="-1"])',
  ].join(', ')

  function getFocusableElements(): HTMLElement[] {
    if (!containerRef.value) return []
    return Array.from(containerRef.value.querySelectorAll(FOCUSABLE))
  }

  function trap(e: KeyboardEvent) {
    if (e.key === 'Escape') {
      options.onEscape?.()
      return
    }

    if (e.key !== 'Tab') return

    const focusable = getFocusableElements()
    if (focusable.length === 0) return

    const first = focusable[0]
    const last = focusable[focusable.length - 1]

    if (e.shiftKey) {
      if (document.activeElement === first) {
        e.preventDefault()
        last.focus()
      }
    } else {
      if (document.activeElement === last) {
        e.preventDefault()
        first.focus()
      }
    }
  }

  function activate() {
    previouslyFocused = document.activeElement as HTMLElement
    document.addEventListener('keydown', trap)
    // Focus the first focusable element
    const focusable = getFocusableElements()
    if (focusable.length > 0) {
      // Prefer the input if present (for search), otherwise first focusable
      const input = containerRef.value?.querySelector('input') as HTMLElement | null
      if (input) {
        input.focus()
      } else {
        focusable[0].focus()
      }
    }
  }

  function deactivate() {
    document.removeEventListener('keydown', trap)
    if (previouslyFocused && previouslyFocused.focus) {
      previouslyFocused.focus()
    }
    previouslyFocused = null
  }

  return { activate, deactivate }
}
