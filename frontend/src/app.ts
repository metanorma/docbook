import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import LibraryApp from './components/library/LibraryApp.vue'
import './styles.css'

const pinia = createPinia()

// Check if this is a collection or single document
if ((window as any).DOCBOOK_COLLECTION) {
  const app = createApp(LibraryApp)
  app.use(pinia)
  app.mount('#docbook-app')
} else {
  const app = createApp(App)
  app.use(pinia)
  app.mount('#docbook-app')
}
