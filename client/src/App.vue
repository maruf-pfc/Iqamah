<script setup lang="ts">
import { RouterLink, RouterView, useRouter, useRoute } from 'vue-router'
import { onMounted, onUnmounted, ref, watch, computed } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useAuthStore } from '@/stores/auth'
import { useLocaleStore } from '@/stores/locale'
import { PrayerName } from '@/types/prayer.types'

const router = useRouter()
const route = useRoute()
const store = usePrayerStore()
const authStore = useAuthStore()
const localeStore = useLocaleStore()

// Dark mode state
const isDarkMode = ref(localStorage.getItem('iqamah_theme') !== 'light')

const toggleTheme = () => {
  isDarkMode.value = !isDarkMode.value
  localStorage.setItem('iqamah_theme', isDarkMode.value ? 'dark' : 'light')
}

// Global Bottom Sheet State for FAB
const isFabSheetOpen = ref(false)
const selectedFabPrayer = ref<PrayerName | null>(null)

// For quick logging from bottom sheet
const quickLogType = ref<'offered' | 'missed' | 'period'>('offered')

const openFabSheet = () => {
  selectedFabPrayer.value = null
  isFabSheetOpen.value = true
}

const selectPrayerForLogging = (prayer: PrayerName) => {
  selectedFabPrayer.value = prayer
  quickLogType.value = 'offered'
}

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

const getLocalizedPrayerName = (prayer: number) => {
  const keys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']
  const key = keys[prayer] || 'fajr'
  return localeStore.t(key as any)
}

const handleQuickLog = async (isOffered: boolean, missedReason?: number) => {
  if (selectedFabPrayer.value === null) return
  try {
    const todayStr = new Date().toISOString().split('T')[0] ?? ''
    const payload = isOffered 
      ? {
          prayerName: selectedFabPrayer.value,
          prayerDate: todayStr,
          isOffered: true,
          waqtStatus: 0, // Awwal
          isJamaah: false,
          isTraveling: false,
          isJummah: false,
          isHome: false,
          hasTasbih: false,
        }
      : {
          prayerName: selectedFabPrayer.value,
          prayerDate: todayStr,
          isOffered: false,
          missedReason: missedReason ?? 4, // Laziness as default
          isTraveling: false,
        }
    await store.logPrayer(payload)
    // Refresh data
    await store.fetchPendingQazas()
    // If we're on the dashboard, we should trigger a reload or since DashboardView watches selectedDate, changing dates or simple custom events work.
    // We can dispatch a custom event to notify components that a prayer was logged.
    window.dispatchEvent(new CustomEvent('prayer-logged'))
    isFabSheetOpen.value = false
  } catch (err) {
    console.error('Error logging from FAB bottom sheet', err)
  }
}
</script>

<template>
  <div 
    :class="[isDarkMode ? 'dark bg-slate-950' : 'bg-slate-100']"
    class="min-h-screen transition-colors duration-300 font-sans selection:bg-teal-500 selection:text-white flex items-center justify-center p-0 md:p-6"
  >
    <!-- Background Mosque Pattern Accent for Desktop -->
    <div class="hidden md:block absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(15,118,110,0.15)_0%,transparent_50%)] pointer-events-none z-0"></div>
    <div class="hidden md:block absolute bottom-0 left-0 right-0 h-64 bg-gradient-to-t from-teal-950/10 to-transparent pointer-events-none z-0"></div>

    <!-- Phone Wrapper / Mock Device -->
    <div 
      class="w-full h-screen md:h-[880px] md:max-w-[440px] md:rounded-[48px] md:shadow-[0_25px_60px_-15px_rgba(0,0,0,0.4)] md:border-[10px] md:border-slate-800 dark:md:border-slate-900 bg-m3-background dark:bg-m3-dark-background text-slate-800 dark:text-slate-200 flex flex-col relative overflow-hidden z-10 transition-colors duration-300"
    >
      <!-- Phone Bezel Details / Camera Cutout for Premium styling on Desktop -->
      <div class="hidden md:flex absolute top-0 left-0 right-0 h-8 justify-center items-center pointer-events-none z-50">
        <div class="w-32 h-4.5 bg-slate-800 dark:bg-slate-900 rounded-full"></div>
      </div>

      <!-- Scrollable Main Viewport -->
      <div class="flex-grow flex flex-col overflow-y-auto overflow-x-hidden pt-0 md:pt-4 pb-20">
        <RouterView v-slot="{ Component }">
          <transition
            name="fade"
            mode="out-in"
            enter-active-class="transition-all duration-200 ease-out"
            enter-from-class="opacity-0 translate-y-4"
            leave-active-class="transition-all duration-150 ease-in"
            leave-to-class="opacity-0 -translate-y-4"
          >
            <component :is="Component" :key="route.fullPath" @toggle-theme="toggleTheme" :is-dark="isDarkMode" />
          </transition>
        </RouterView>
      </div>

      <!-- Floating Action Button (FAB) (Only visible if authenticated and not on onboarding page) -->
      <button 
        v-if="authStore.isAuthenticated && route.name !== 'onboarding'"
        @click="openFabSheet"
        class="absolute bottom-24 right-6 w-14 h-14 rounded-2xl bg-m3-primary dark:bg-m3-dark-primary text-white dark:text-m3-dark-on-primary shadow-lg shadow-teal-700/30 hover:scale-105 active:scale-95 transition-all duration-200 flex items-center justify-center z-40 cursor-pointer"
        title="নামাজ লগ করুন"
      >
        <span class="material-symbols-rounded text-3xl font-bold">add</span>
      </button>

      <!-- Bottom Navigation Bar (Only visible if authenticated) -->
      <nav 
        v-if="authStore.isAuthenticated && route.name !== 'onboarding'"
        class="absolute bottom-0 left-0 right-0 h-18 bg-m3-surface dark:bg-m3-dark-surface border-t border-slate-200/50 dark:border-slate-800/80 flex items-center justify-around px-2 z-40 transition-colors duration-300"
      >
        <!-- আজ (Dashboard) -->
        <RouterLink 
          to="/"
          class="flex flex-col items-center gap-1 py-1 px-4 text-slate-500 dark:text-slate-400 select-none group"
          active-class="active-nav-link"
        >
          <div class="w-16 h-8 rounded-full flex items-center justify-center group-hover:bg-slate-100 dark:group-hover:bg-slate-800 transition-colors duration-200 active-pill">
            <span class="material-symbols-rounded text-2xl">home</span>
          </div>
          <span class="text-xs font-medium">আজ</span>
        </RouterLink>

        <!-- রেকর্ড (Qaza Ledger) -->
        <RouterLink 
          to="/qaza"
          class="flex flex-col items-center gap-1 py-1 px-4 text-slate-500 dark:text-slate-400 select-none group relative"
          active-class="active-nav-link"
        >
          <div class="w-16 h-8 rounded-full flex items-center justify-center group-hover:bg-slate-100 dark:group-hover:bg-slate-800 transition-colors duration-200 active-pill">
            <span class="material-symbols-rounded text-2xl">history</span>
          </div>
          <span class="text-xs font-medium">রেকর্ড</span>
          <!-- Qaza Count Badge -->
          <span 
            v-if="store.pendingQazas.length > 0"
            class="absolute top-1 right-5 flex h-4 min-w-4 px-1 items-center justify-center rounded-full bg-m3-error text-[9px] font-bold text-white border border-white dark:border-m3-dark-surface"
          >
            {{ store.pendingQazas.length }}
          </span>
        </RouterLink>

        <!-- অগ্রগতি (Analytics) -->
        <RouterLink 
          to="/analytics"
          class="flex flex-col items-center gap-1 py-1 px-4 text-slate-500 dark:text-slate-400 select-none group"
          active-class="active-nav-link"
        >
          <div class="w-16 h-8 rounded-full flex items-center justify-center group-hover:bg-slate-100 dark:group-hover:bg-slate-800 transition-colors duration-200 active-pill">
            <span class="material-symbols-rounded text-2xl">insights</span>
          </div>
          <span class="text-xs font-medium">অগ্রগতি</span>
        </RouterLink>

        <!-- সেটিংস (Settings) -->
        <RouterLink 
          to="/settings"
          class="flex flex-col items-center gap-1 py-1 px-4 text-slate-500 dark:text-slate-400 select-none group"
          active-class="active-nav-link"
        >
          <div class="w-16 h-8 rounded-full flex items-center justify-center group-hover:bg-slate-100 dark:group-hover:bg-slate-800 transition-colors duration-200 active-pill">
            <span class="material-symbols-rounded text-2xl">settings</span>
          </div>
          <span class="text-xs font-medium">সেটিংস</span>
        </RouterLink>
      </nav>

      <!-- FAB Bottom Sheet (Material 3 Style) -->
      <div 
        v-if="isFabSheetOpen"
        class="absolute inset-0 bg-black/60 z-50 flex flex-col justify-end"
        @click.self="isFabSheetOpen = false"
      >
        <div 
          class="bg-m3-surface dark:bg-m3-dark-surface rounded-t-[32px] p-6 pb-8 space-y-6 shadow-[0_-10px_30px_rgba(0,0,0,0.3)] animate-slide-up max-h-[90%] overflow-y-auto"
        >
          <!-- Drag Handle Indicator -->
          <div class="w-12 h-1.5 bg-slate-300 dark:bg-slate-700 rounded-full mx-auto mb-2"></div>

          <!-- Bottom Sheet Header -->
          <div class="flex items-center justify-between">
            <h3 class="text-xl font-serif font-bold text-slate-900 dark:text-white">
              {{ selectedFabPrayer === null ? 'আজকের নামাজ লিপিবদ্ধ করুন' : getLocalizedPrayerName(selectedFabPrayer) + ' সালাত' }}
            </h3>
            <button 
              @click="isFabSheetOpen = false"
              class="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-600 dark:text-slate-400 cursor-pointer"
            >
              <span class="material-symbols-rounded text-xl">close</span>
            </button>
          </div>

          <!-- Option View 1: Select Prayer -->
          <div v-if="selectedFabPrayer === null" class="grid grid-cols-1 gap-3">
            <button 
              v-for="p in [PrayerName.Fajr, PrayerName.Dhuhr, PrayerName.Asr, PrayerName.Maghrib, PrayerName.Isha]"
              :key="p"
              @click="selectPrayerForLogging(p)"
              class="w-full p-4 rounded-2xl bg-m3-background dark:bg-m3-dark-background hover:bg-teal-500/10 dark:hover:bg-teal-500/20 text-left font-semibold text-slate-800 dark:text-slate-200 border border-slate-200/40 dark:border-slate-800/40 flex items-center justify-between group transition-all duration-200 cursor-pointer"
            >
              <div class="flex items-center gap-3">
                <span class="text-2xl">
                  {{ p === PrayerName.Fajr ? '🌅' : p === PrayerName.Dhuhr ? '☀️' : p === PrayerName.Asr ? '⛅' : p === PrayerName.Maghrib ? '🌇' : '🌃' }}
                </span>
                <span>{{ getLocalizedPrayerName(p) }}</span>
              </div>
              <span class="material-symbols-rounded text-slate-400 group-hover:translate-x-1 transition-transform">arrow_forward_ios</span>
            </button>
          </div>

          <!-- Option View 2: Quick Log Action -->
          <div v-else class="space-y-4">
            <p class="text-sm text-slate-500 dark:text-slate-400 text-center">
              আজকের জন্য দ্রুত সালাত স্টেট নির্ধারণ করুন। বিস্তারিত বিবরণের জন্য ড্যাশবোর্ড ব্যবহার করুন।
            </p>

            <div class="grid grid-cols-2 gap-4">
              <!-- Offered Button -->
              <button 
                @click="handleQuickLog(true)"
                class="p-4 rounded-2xl bg-m3-success-container hover:bg-m3-success hover:text-white text-emerald-800 dark:text-emerald-300 font-bold border border-emerald-500/20 text-center flex flex-col items-center gap-2 cursor-pointer transition-all"
              >
                <span class="material-symbols-rounded text-3xl">check_circle</span>
                <span>আদায় করেছি</span>
              </button>

              <!-- Missed Button -->
              <button 
                @click="handleQuickLog(false)"
                class="p-4 rounded-2xl bg-m3-error-container hover:bg-m3-error hover:text-white text-rose-800 dark:text-rose-300 font-bold border border-rose-500/20 text-center flex flex-col items-center gap-2 cursor-pointer transition-all"
              >
                <span class="material-symbols-rounded text-3xl">cancel</span>
                <span>ছুটে গেছে</span>
              </button>
            </div>
            
            <button 
              @click="selectedFabPrayer = null"
              class="w-full py-3 rounded-xl border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-400 text-sm font-semibold text-center cursor-pointer mt-2"
            >
              পেছনে যান
            </button>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

<style>
/* Active link pills styling */
.active-nav-link {
  color: #0F766E !important;
}
.dark .active-nav-link {
  color: #5EEAD4 !important;
}
.active-nav-link .active-pill {
  background-color: #CCFBF1 !important;
  color: #042F2E !important;
}
.dark .active-nav-link .active-pill {
  background-color: #115E59 !important;
  color: #99F6E4 !important;
}

/* Animations */
@keyframes slide-up {
  from {
    transform: translateY(100%);
  }
  to {
    transform: translateY(0);
  }
}
.animate-slide-up {
  animation: slide-up 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
