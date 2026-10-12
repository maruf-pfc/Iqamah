import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import './assets/main.css'
import { recoverRestore } from './services/restore'

try {
  recoverRestore()
  const app = createApp(App)

  app.use(createPinia())
  app.use(router)

  app.mount('#app')
} catch {
  const root = document.getElementById('app')
  if (root) root.textContent = 'ডেটা পুনরুদ্ধার সম্পন্ন হয়নি। অ্যাপের ডেটা মুছবেন না; স্টোরেজ খালি করে আবার খুলুন। / Data recovery could not finish. Do not clear app data. Free device storage and reopen the app.'
}
