<script setup lang="ts">
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import { computed, ref, watch } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useAuthStore } from '@/stores/auth'
import { useLocaleStore } from '@/stores/locale'
import { readPreference } from '@/services/preferences'

const route = useRoute()
const router = useRouter()
const store = usePrayerStore()
const auth = useAuthStore()
const locale = useLocaleStore()
const isDark = ref(readPreference('iqamah_theme') !== 'light')
const themeError = ref(false)
const navigation = [
  { to: '/', icon: 'home', key: 'dashboard' },
  { to: '/qaza', icon: 'history', key: 'qaza' },
  { to: '/analytics', icon: 'insights', key: 'analytics' },
  { to: '/settings', icon: 'settings', key: 'settings' },
] as const
const showNavigation = computed(() => auth.isAuthenticated && route.name !== 'onboarding')
const openLog = () => {
  if (route.path === '/') window.dispatchEvent(new Event('iqamah-open-log'))
  else router.push({ path: '/', query: { log: '1' } })
}
const toggleTheme = () => {
  try {
    localStorage.setItem('iqamah_theme', isDark.value ? 'light' : 'dark')
    isDark.value = !isDark.value
  } catch { themeError.value = true }
}
watch(() => locale.currentLocale, value => { document.documentElement.lang = value }, { immediate: true })
watch([() => route.fullPath, () => auth.isAuthenticated], async () => {
  if (!auth.isAuthenticated) return
  try { await store.fetchPendingQazas() } catch { /* A screen-level error remains available in the prayer store. */ }
}, { immediate: true })
</script>

<template>
  <div :class="{ dark: isDark }" class="iq-app">
    <div class="iq-shell">
      <header class="iq-app-header">
        <RouterLink to="/" class="iq-brand">Iqamah <span lang="ar" class="font-arabic">إقامة</span></RouterLink>
        <button class="iq-button iq-button-secondary" @click="toggleTheme" :aria-label="locale.t('toggle_theme')" :aria-pressed="isDark">
          <span class="material-symbols-rounded" aria-hidden="true">{{ isDark ? 'light_mode' : 'dark_mode' }}</span>
        </button>
      </header>
      <p v-if="themeError" role="alert" class="px-6">{{ locale.t('settings_error') }}</p>
      <main class="iq-main">
        <RouterView v-slot="{ Component }">
          <component :is="Component" :key="route.fullPath" @toggle-theme="toggleTheme" :is-dark="isDark" />
        </RouterView>
      </main>
      <nav v-if="showNavigation" class="iq-navigation" :aria-label="locale.t('navigation')">
        <RouterLink v-for="item in navigation" :key="item.to" :to="item.to" class="iq-nav-item" exact-active-class="iq-nav-active">
          <span class="material-symbols-rounded" aria-hidden="true">{{ item.icon }}</span>
          <span>{{ locale.t(item.key) }}</span>
          <span v-if="item.key === 'qaza' && store.pendingQazas.length" class="iq-nav-count">{{ store.pendingQazas.length }}</span>
        </RouterLink>
        <button class="iq-button iq-nav-log" @click="openLog">{{ locale.t('log') }}</button>
      </nav>
      <button v-if="showNavigation" class="iq-button iq-floating-log" @click="openLog">{{ locale.t('log') }}</button>
    </div>
  </div>
</template>
