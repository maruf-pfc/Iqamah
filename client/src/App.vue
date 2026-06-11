<script setup lang="ts">
import { RouterLink, RouterView, useRouter } from 'vue-router'
import { onMounted, onUnmounted } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useAuthStore } from '@/stores/auth'
import { useLocaleStore } from '@/stores/locale'

const router = useRouter()
const store = usePrayerStore()
const authStore = useAuthStore()
const localeStore = useLocaleStore()

// Poll/Load Qaza count for global badge
const loadQazaCount = async () => {
  if (!authStore.isAuthenticated) return
  try {
    await store.fetchPendingQazas()
  } catch {
    // Silent fail
  }
}

let pollInterval: ReturnType<typeof setInterval> | null = null

onMounted(() => {
  if (authStore.isAuthenticated) {
    loadQazaCount()
    pollInterval = setInterval(loadQazaCount, 15000)
  }
})

// Listen for auth changes to set/clear intervals
authStore.$subscribe((mutation, state) => {
  if (state.token) {
    loadQazaCount()
    if (!pollInterval) {
      pollInterval = setInterval(loadQazaCount, 15000)
    }
  } else {
    if (pollInterval) {
      clearInterval(pollInterval)
      pollInterval = null
    }
  }
})

onUnmounted(() => {
  if (pollInterval) {
    clearInterval(pollInterval)
  }
})

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}
</script>

<template>
  <div
    class="min-h-screen bg-slate-950 text-slate-100 flex flex-col selection:bg-emerald-500 selection:text-slate-950 font-sans antialiased"
  >
    <!-- Navbar (Only visible if authenticated) -->
    <header
      v-if="authStore.isAuthenticated"
      class="sticky top-0 z-40 bg-slate-950/80 backdrop-blur-md border-b border-slate-900 shadow-md"
    >
      <div class="max-w-4xl mx-auto px-4 h-16 flex items-center justify-between">
        <!-- Brand logo -->
        <RouterLink to="/" class="flex items-center gap-2.5 group">
          <div
            class="w-8 h-8 rounded-lg bg-emerald-500 flex items-center justify-center font-black text-slate-950 shadow-md shadow-emerald-500/20 group-hover:scale-105 transition-transform duration-300"
          >
            إ
          </div>
          <span
            class="font-extrabold text-lg tracking-tight bg-gradient-to-r from-slate-100 to-slate-300 bg-clip-text text-transparent group-hover:text-emerald-400 transition-colors duration-300"
          >
            Iqamah
          </span>
        </RouterLink>

        <!-- Navigation Links -->
        <div class="flex items-center gap-3">
          <nav class="flex items-center gap-1">
            <RouterLink
              to="/"
              class="text-xs sm:text-sm font-semibold px-3 py-1.5 rounded-xl transition-all duration-300 flex items-center gap-2 hover:bg-slate-900"
              active-class="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-bold"
            >
              {{ localeStore.t('dashboard') }}
            </RouterLink>

            <RouterLink
              to="/qaza"
              class="text-xs sm:text-sm font-semibold px-3 py-1.5 rounded-xl transition-all duration-300 flex items-center gap-2 hover:bg-slate-900 relative"
              active-class="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-bold"
            >
              {{ localeStore.t('qaza') }}
              <!-- Badge count -->
              <span
                v-if="store.pendingQazas.length > 0"
                class="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-rose-500 text-[8px] font-black text-slate-950 border border-slate-950 animate-pulse"
              >
                {{ store.pendingQazas.length }}
              </span>
            </RouterLink>

            <RouterLink
              to="/analytics"
              class="text-xs sm:text-sm font-semibold px-3 py-1.5 rounded-xl transition-all duration-300 flex items-center gap-2 hover:bg-slate-900"
              active-class="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-bold"
            >
              {{ localeStore.t('analytics') }}
            </RouterLink>

            <RouterLink
              to="/guide"
              class="text-xs sm:text-sm font-semibold px-3 py-1.5 rounded-xl transition-all duration-300 flex items-center gap-2 hover:bg-slate-900"
              active-class="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-bold"
            >
              {{ localeStore.t('guide') }}
            </RouterLink>
          </nav>

          <!-- User Display & Logout -->
          <div class="flex items-center gap-2 border-l border-slate-900 pl-3">
            <button
              @click="localeStore.toggleLocale"
              class="flex items-center justify-center h-8 px-2 rounded-lg bg-slate-900 hover:bg-slate-800 border border-slate-800 text-[10px] sm:text-xs font-black text-slate-300 transition-all duration-200 cursor-pointer"
              title="Switch Language / ভাষা পরিবর্তন করুন"
            >
              🌐 {{ localeStore.currentLocale === 'en' ? 'EN' : 'বাং' }}
            </button>
            <span class="hidden md:inline text-xs font-bold text-slate-400">
              {{ authStore.user?.username }}
            </span>
            <button
              @click="handleLogout"
              class="bg-slate-900 hover:bg-rose-500/25 hover:text-rose-400 border border-slate-800 text-slate-400 font-bold text-[10px] uppercase tracking-wider px-2.5 py-1.5 rounded-lg transition-all duration-200 cursor-pointer"
            >
              {{ localeStore.t('logout') }}
            </button>
          </div>
        </div>
      </div>
    </header>

    <!-- Main View Wrapper -->
    <main class="flex-grow flex flex-col justify-stretch">
      <RouterView v-slot="{ Component }">
        <transition
          name="fade"
          mode="out-in"
          enter-active-class="transition-all duration-200 ease-out"
          enter-from-class="opacity-0 translate-y-2"
          leave-active-class="transition-all duration-150 ease-in"
          leave-to-class="opacity-0 -translate-y-2"
        >
          <component :is="Component" />
        </transition>
      </RouterView>
    </main>

    <!-- Footer -->
    <footer
      v-if="authStore.isAuthenticated"
      class="border-t border-slate-900 py-6 text-center text-slate-600 text-xs mt-auto"
    >
      <p>
        © {{ new Date().getFullYear() }} Iqamah (إقامة) Salah Tracker. Built with Clean Architecture
        & Vue 3.
      </p>
    </footer>
  </div>
</template>

<style>
/* Global reset overrides */
html,
body {
  background-color: #020617; /* bg-slate-950 */
}
</style>
