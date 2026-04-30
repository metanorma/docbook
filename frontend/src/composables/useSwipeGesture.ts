// Lightweight edge-swipe gesture detection for mobile.
// Detects swipe-from-left-edge to open, and swipe-left-on-overlay to close.

import { onMounted, onUnmounted } from 'vue'

interface SwipeGestureOptions {
  onSwipeRight?: () => void
  onSwipeLeft?: () => void
  edgeWidth?: number
  minDistance?: number
}

export function useSwipeGesture(options: SwipeGestureOptions = {}) {
  const {
    onSwipeRight,
    onSwipeLeft,
    edgeWidth = 30,
    minDistance = 60,
  } = options

  let touchStartX = 0
  let touchStartY = 0
  let tracking = false

  function onTouchStart(e: TouchEvent) {
    const touch = e.touches[0]
    touchStartX = touch.clientX
    touchStartY = touch.clientY
    // Only track swipes starting from the left edge
    tracking = touchStartX <= edgeWidth
  }

  function onTouchEnd(e: TouchEvent) {
    if (!tracking) return
    tracking = false

    const touch = e.changedTouches[0]
    const dx = touch.clientX - touchStartX
    const dy = Math.abs(touch.clientY - touchStartY)

    // Ignore if the swipe was more vertical than horizontal
    if (dy > Math.abs(dx)) return

    if (dx >= minDistance) {
      onSwipeRight?.()
    } else if (dx <= -minDistance) {
      onSwipeLeft?.()
    }
  }

  onMounted(() => {
    document.addEventListener('touchstart', onTouchStart, { passive: true })
    document.addEventListener('touchend', onTouchEnd, { passive: true })
  })

  onUnmounted(() => {
    document.removeEventListener('touchstart', onTouchStart)
    document.removeEventListener('touchend', onTouchEnd)
  })
}
