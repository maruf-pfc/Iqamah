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
    class="min-h-screen bg-islamic-deep text-slate-200 flex flex-col selection:bg-gold-500 selection:text-islamic-deep font-sans antialiased relative overflow-hidden"
  >
    <!-- Top gold glow -->
    <div class="absolute top-0 left-1/2 -translate-x-1/2 w-full max-w-7xl h-[350px] bg-[radial-gradient(circle_at_top,rgba(212,175,55,0.08)_0%,transparent_70%)] pointer-events-none"></div>

    <!-- Navbar (Only visible if authenticated) -->
    <header
      v-if="authStore.isAuthenticated"
      class="sticky top-0 z-40 bg-islamic-deep/80 backdrop-blur-md border-b border-gold-500/10 shadow-lg shadow-islamic-deep/50 islamic-border-top"
    >
      <div class="max-w-4xl mx-auto px-4 h-16 flex items-center justify-between">
        <!-- Brand logo -->
        <RouterLink to="/" class="flex items-center gap-2.5 group">
          <div
            class="w-9 h-9 rounded-xl bg-gradient-to-br from-gold-400 to-gold-600 flex items-center justify-center font-serif text-lg font-bold text-islamic-deep shadow-lg shadow-gold-500/10 border border-gold-300/30 group-hover:rotate-6 transition-all duration-300"
          >
            إ
          </div>
          <span
            class="font-serif font-bold text-xl tracking-wide bg-gradient-to-r from-gold-100 via-gold-300 to-gold-500 bg-clip-text text-transparent group-hover:brightness-110 transition-all duration-300"
          >
            Iqamah
          </span>
        </RouterLink>

        <!-- Navigation Links -->
        <div class="flex items-center gap-3">
          <nav class="flex items-center gap-1">
            <RouterLink
              to="/"
              class="text-xs sm:text-sm font-semibold px-3 py-1.5 rounded-xl border border-transparent transition-all duration-300 flex items-center gap-2 hover:bg-islamic-hover hover:text-gold-300"
              active-class="bg-gold-500/10 text-gold-400 border border-gold-500/20 font-bold shadow-[0_0_15px_rgba(212,175,55,0.05)]"
            >
              {{ localeStore.t('dashboard') }}
            </RouterLink>

            <RouterLink
              to="/qaza"
              class="text-xs sm:text-sm font-semibold px-3 py-1.5 rounded-xl border border-transparent transition-all duration-300 flex items-center gap-2 hover:bg-islamic-hover hover:text-gold-300 relative"
              active-class="bg-gold-500/10 text-gold-400 border border-gold-500/20 font-bold shadow-[0_0_15px_rgba(212,175,55,0.05)]"
            >
              {{ localeStore.t('qaza') }}
              <!-- Badge count -->
              <span
                v-if="store.pendingQazas.length > 0"
                class="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-rose-500 text-[8px] font-black text-white border border-islamic-deep animate-pulse"
              >
                {{ store.pendingQazas.length }}
              </span>
            </RouterLink>

            <RouterLink
              to="/analytics"
              class="text-xs sm:text-sm font-semibold px-3 py-1.5 rounded-xl border border-transparent transition-all duration-300 flex items-center gap-2 hover:bg-islamic-hover hover:text-gold-300"
              active-class="bg-gold-500/10 text-gold-400 border border-gold-500/20 font-bold shadow-[0_0_15px_rgba(212,175,55,0.05)]"
            >
              {{ localeStore.t('analytics') }}
            </RouterLink>

            <RouterLink
              to="/salah-time"
              class="text-xs sm:text-sm font-semibold px-3 py-1.5 rounded-xl border border-transparent transition-all duration-300 flex items-center gap-2 hover:bg-islamic-hover hover:text-gold-300"
              active-class="bg-gold-500/10 text-gold-400 border border-gold-500/20 font-bold shadow-[0_0_15px_rgba(212,175,55,0.05)]"
            >
              {{ localeStore.t('salah_time') }}
            </RouterLink>

            <RouterLink
              to="/guide"
              class="text-xs sm:text-sm font-semibold px-3 py-1.5 rounded-xl border border-transparent transition-all duration-300 flex items-center gap-2 hover:bg-islamic-hover hover:text-gold-300"
              active-class="bg-gold-500/10 text-gold-400 border border-gold-500/20 font-bold shadow-[0_0_15px_rgba(212,175,55,0.05)]"
            >
              {{ localeStore.t('guide') }}
            </RouterLink>
          </nav>

          <!-- User Display & Logout -->
          <div class="flex items-center gap-2 border-l border-gold-500/10 pl-3">
            <button
              @click="localeStore.toggleLocale"
              class="flex items-center justify-center h-8 px-2.5 rounded-lg bg-islamic-hover hover:bg-gold-500/20 border border-gold-500/20 hover:border-gold-500/50 text-[10px] sm:text-xs font-bold text-gold-300 hover:text-gold-200 transition-all duration-200 cursor-pointer"
              title="Switch Language / ভাষা পরিবর্তন করুন"
            >
              🌐 {{ localeStore.currentLocale === 'en' ? 'EN' : 'বাং' }}
            </button>
            <span class="hidden md:inline text-xs font-bold text-gold-200/70">
              {{ authStore.user?.username }}
            </span>
            <button
              @click="handleLogout"
              class="bg-islamic-hover hover:bg-rose-950/40 hover:text-rose-400 border border-gold-500/10 hover:border-rose-500/20 text-slate-400 font-bold text-[10px] uppercase tracking-wider px-2.5 py-1.5 rounded-lg transition-all duration-200 cursor-pointer"
            >
              {{ localeStore.t('logout') }}
            </button>
          </div>
        </div>
      </div>
    </header>

    <!-- Main View Wrapper -->
    <main class="flex-grow flex flex-col justify-stretch z-10">
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
      class="border-t border-gold-500/10 py-6 text-center text-slate-500 text-xs mt-auto bg-islamic-deep/40 z-10"
    >
      <p>
        © {{ new Date().getFullYear() }} Iqamah (إقامة) Salah Tracker. Elegant & Devoted tracking platform.
      </p>
    </footer>
  </div>
</template>

<style>
/* Global reset overrides */
html,
body {
  background-color: #030c08;
}
</style>
