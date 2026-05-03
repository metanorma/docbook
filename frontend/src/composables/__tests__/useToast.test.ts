import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useToast } from '../useToast'

describe('useToast', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    // Clear shared toast state
    const { toasts } = useToast()
    toasts.value = []
  })

  it('adds a toast', () => {
    const { toasts, addToast } = useToast()
    addToast('Hello')
    expect(toasts.value).toHaveLength(1)
    expect(toasts.value[0].message).toBe('Hello')
    expect(toasts.value[0].type).toBe('info')
  })

  it('adds a success toast', () => {
    const { toasts, addToast } = useToast()
    addToast('Done!', 'success')
    expect(toasts.value[0].type).toBe('success')
  })

  it('dismisses a toast', () => {
    const { toasts, addToast, dismissToast } = useToast()
    const id = addToast('Bye')
    dismissToast(id)
    expect(toasts.value).toHaveLength(0)
  })

  it('auto-removes toast after timeout', () => {
    const { toasts, addToast } = useToast()
    addToast('Temporary')
    expect(toasts.value).toHaveLength(1)

    vi.advanceTimersByTime(2500)
    expect(toasts.value).toHaveLength(0)
  })

  it('increments IDs', () => {
    const { addToast } = useToast()
    const id1 = addToast('A')
    const id2 = addToast('B')
    expect(id2).toBeGreaterThan(id1)
  })

  it('dismissToast removes specific toast', () => {
    const { toasts, addToast, dismissToast } = useToast()
    const id = addToast('Target')
    addToast('Other')
    dismissToast(id)
    expect(toasts.value).toHaveLength(1)
    expect(toasts.value[0].message).toBe('Other')
  })
})
