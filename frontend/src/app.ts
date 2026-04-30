import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import './styles.css'

const pinia = createPinia()

const app = createApp(App)
app.use(pinia)

app.config.errorHandler = (err, _instance, info) => {
  console.error(`[DocBook] ${info}:`, err)
  const el = document.getElementById('docbook-error')
  if (el) {
    el.style.display = 'flex'
    const msg = el.querySelector('.error-message')
    if (msg) msg.textContent = err instanceof Error ? err.message : String(err)
  }
}

app.mount('#docbook-app')

// Register service worker for dist/chunked formats (offline reading)
if ('serviceWorker' in navigator) {
  const format = (window as any).DOCBOOK_FORMAT
  if (format === 'dist' || format === 'chunked') {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('/docbook-sw.js').catch(() => {})
    })
  }
}
