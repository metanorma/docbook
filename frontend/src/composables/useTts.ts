import { ref, computed } from 'vue'

export function useTts() {
  const speaking = ref(false)
  const paused = ref(false)
  const currentWord = ref('')
  const currentWordIndex = ref(-1)

  let utterance: SpeechSynthesisUtterance | null = null
  let textChunks: string[] = []
  let currentChunkIndex = 0

  function getVisibleText(): string {
    const main = document.getElementById('main-content')
    if (!main) return ''
    return main.textContent || ''
  }

  function speak() {
    if (!('speechSynthesis' in window)) {
      console.warn('Speech synthesis not supported')
      return
    }

    if (speaking.value && !paused.value) {
      pause()
      return
    }

    if (paused.value) {
      window.speechSynthesis.resume()
      paused.value = false
      speaking.value = true
      return
    }

    const text = getVisibleText()
    if (!text.trim()) return

    // Split into chunks for boundary events (SpeechSynthesis has limits)
    textChunks = text.match(/.{1,200}(\s|$)/g) || [text]
    currentChunkIndex = 0

    speakChunk()
  }

  function speakChunk() {
    if (currentChunkIndex >= textChunks.length) {
      stop()
      return
    }

    window.speechSynthesis.cancel()

    utterance = new SpeechSynthesisUtterance(textChunks[currentChunkIndex])
    utterance.rate = 1.0
    utterance.pitch = 1.0

    utterance.onboundary = (event) => {
      if (event.name === 'word') {
        const chunk = textChunks[currentChunkIndex]
        currentWord.value = chunk.substring(event.charIndex, event.charIndex + event.charLength)
        currentWordIndex.value = event.charIndex
      }
    }

    utterance.onend = () => {
      currentChunkIndex++
      if (currentChunkIndex < textChunks.length) {
        speakChunk()
      } else {
        stop()
      }
    }

    utterance.onerror = () => {
      stop()
    }

    speaking.value = true
    paused.value = false
    window.speechSynthesis.speak(utterance)
  }

  function pause() {
    if (speaking.value && !paused.value) {
      window.speechSynthesis.pause()
      paused.value = true
    }
  }

  function stop() {
    window.speechSynthesis.cancel()
    speaking.value = false
    paused.value = false
    currentWord.value = ''
    currentWordIndex.value = -1
    currentChunkIndex = 0
  }

  const isSupported = computed(() => 'speechSynthesis' in window)

  return {
    speaking,
    paused,
    currentWord,
    currentWordIndex,
    isSupported,
    speak,
    pause,
    stop,
  }
}
