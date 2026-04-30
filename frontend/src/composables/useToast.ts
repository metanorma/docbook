import { ref } from 'vue'

export interface Toast {
  id: number
  message: string
  type: 'success' | 'info'
}

const toasts = ref<Toast[]>([])
let nextId = 0

export function useToast() {
  function addToast(message: string, type: Toast['type'] = 'info') {
    const id = nextId++
    toasts.value.push({ id, message, type })
    setTimeout(() => {
      toasts.value = toasts.value.filter(t => t.id !== id)
    }, 2500)
    return id
  }

  function dismissToast(id: number) {
    toasts.value = toasts.value.filter(t => t.id !== id)
  }

  return { toasts, addToast, dismissToast }
}
