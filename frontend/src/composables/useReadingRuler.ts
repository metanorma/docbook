import { ref, onMounted, onUnmounted } from 'vue'

export function useReadingRuler() {
  const enabled = ref(false)
  const rulerY = ref(-1)

  function handleMouseMove(e: MouseEvent) {
    if (!enabled.value) return
    rulerY.value = e.clientY
  }

  function handleMouseLeave() {
    if (!enabled.value) return
    rulerY.value = -1
  }

  function toggle() {
    enabled.value = !enabled.value
    if (!enabled.value) {
      rulerY.value = -1
    }
  }

  onMounted(() => {
    document.addEventListener('mousemove', handleMouseMove)
    document.addEventListener('mouseleave', handleMouseLeave)
  })

  onUnmounted(() => {
    document.removeEventListener('mousemove', handleMouseMove)
    document.removeEventListener('mouseleave', handleMouseLeave)
  })

  return {
    enabled,
    rulerY,
    toggle,
  }
}
