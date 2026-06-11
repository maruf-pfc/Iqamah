<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
import { onMounted } from 'vue'
import { usePrayerStore } from '@/stores/prayer'

const store = usePrayerStore()

// Poll/Load Qaza count for global badge
const loadQazaCount = async () => {
  try {
    await store.fetchPendingQazas(1) // Demo User Ahmed
  } catch {
    // Silent fail
  }
}

onMounted(() => {
  loadQazaCount()
  // Poll every 15 seconds to keep badge fresh
  setInterval(loadQazaCount, 15000)
})
</script>

<template>
  <div
    class="min-h-screen bg-slate-950 text-slate-100 flex flex-col selection:bg-emerald-500 selection:text-slate-950 font-sans antialiased"
  >
    <!-- Navbar -->
    <header
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
        <nav class="flex items-center gap-1">
          <RouterLink
            to="/"
            class="text-xs sm:text-sm font-semibold px-3.5 py-2 rounded-xl transition-all duration-300 flex items-center gap-2 hover:bg-slate-900"
            active-class="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-bold"
          >
            Dashboard
          </RouterLink>

          <RouterLink
            to="/qaza"
            class="text-xs sm:text-sm font-semibold px-3.5 py-2 rounded-xl transition-all duration-300 flex items-center gap-2 hover:bg-slate-900 relative"
            active-class="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-bold"
          >
            Qaza
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
            class="text-xs sm:text-sm font-semibold px-3.5 py-2 rounded-xl transition-all duration-300 flex items-center gap-2 hover:bg-slate-900"
            active-class="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-bold"
          >
            Analytics
          </RouterLink>
        </nav>
      </div>
    </header>

    <!-- Main View Wrapper -->
    <main class="flex-grow py-6 sm:py-10">
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
    <footer class="border-t border-slate-900 py-6 text-center text-slate-600 text-xs">
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
