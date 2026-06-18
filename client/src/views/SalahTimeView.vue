<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useLocaleStore } from '@/stores/locale'
import { useAuthStore } from '@/stores/auth'

interface PrayerEntry {
  start: string
  end: string
  name: string
  isActive: boolean
}

interface ForbiddenZone {
  name: string
  start: string
  end: string
  isActive: boolean
}

interface PrayerSchedule {
  fajr: PrayerEntry
  dhuhr: PrayerEntry
  asr: PrayerEntry
  maghrib: PrayerEntry
  isha: PrayerEntry
  sunrise: string
  forbiddenZones: ForbiddenZone[]
  isAnyForbiddenNow: boolean
  hijriDate?: string
}

const localeStore = useLocaleStore()
const authStore = useAuthStore()

const latitude = ref<number>(23.7639)
const longitude = ref<number>(90.3889)
const locationName = ref<string>('Dhaka, Bangladesh (Default)')
const loading = ref<boolean>(false)
const error = ref<string | null>(null)
const schedule = ref<PrayerSchedule | null>(null)
const currentTime = ref<Date>(new Date())

let timerInterval: ReturnType<typeof setInterval> | null = null

// Determine API Base URL matching store patterns
let rawApiUrl = (import.meta.env.VITE_API_URL || '').replace(/\/$/, '')
if (rawApiUrl && !rawApiUrl.endsWith('/api')) {
  rawApiUrl = `${rawApiUrl}/api`
}
const API_BASE_URL = rawApiUrl || '/api'

const getHeaders = () => {
  const headers: Record<string, string> = {}
  if (authStore.token) {
    headers['Authorization'] = `Bearer ${authStore.token}`
  }
  return headers
}

const fetchSalahTimes = async () => {
  loading.value = true
  error.value = null
  try {
    const url = `${API_BASE_URL}/SalahTime?latitude=${latitude.value}&longitude=${longitude.value}`
    const response = await fetch(url, { headers: getHeaders() })
    if (!response.ok) {
      throw new Error('Failed to retrieve prayer timings.')
    }
    const data = await response.json()
    schedule.value = data
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Error fetching Salah times.'
  } finally {
    loading.value = false
  }
}

const requestLocation = () => {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        latitude.value = parseFloat(position.coords.latitude.toFixed(4))
        longitude.value = parseFloat(position.coords.longitude.toFixed(4))
        locationName.value = 'Detected Coordinates'
        fetchSalahTimes()
      },
      () => {
        // Default to Dhaka on error/refusal
        latitude.value = 23.7639
        longitude.value = 90.3889
        locationName.value = 'Dhaka, Bangladesh (Default)'
        fetchSalahTimes()
      }
    )
  } else {
    fetchSalahTimes()
  }
}

// Format date nicely
const formattedGregorianDate = computed(() => {
  return currentTime.value.toLocaleDateString(
    localeStore.currentLocale === 'en' ? 'en-US' : 'bn-BD',
    { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }
  )
})

const formattedTime = computed(() => {
  return currentTime.value.toLocaleTimeString(
    localeStore.currentLocale === 'en' ? 'en-US' : 'bn-BD',
    { hour: '2-digit', minute: '2-digit', second: '2-digit' }
  )
})

// Check if a specific time string (ISO format or DateTime JSON) is active now
const isTimeBetween = (startStr: string, endStr: string) => {
  const now = currentTime.value.getTime()
  const start = new Date(startStr).getTime()
  const end = new Date(endStr).getTime()
  return now >= start && now < end
}

// Compute active status for each prayer dynamically
const activePrayer = computed(() => {
  if (!schedule.value) return null
  const prayers = [
    schedule.value.fajr,
    schedule.value.dhuhr,
    schedule.value.asr,
    schedule.value.maghrib,
    schedule.value.isha,
  ]
  return prayers.find((p) => isTimeBetween(p.start, p.end)) || null
})

// Calculate countdown to next prayer
const countdownText = computed(() => {
  if (!schedule.value) return ''
  const now = currentTime.value.getTime()
  const prayers = [
    { name: 'Fajr', start: new Date(schedule.value.fajr.start).getTime() },
    { name: 'Dhuhr', start: new Date(schedule.value.dhuhr.start).getTime() },
    { name: 'Asr', start: new Date(schedule.value.asr.start).getTime() },
    { name: 'Maghrib', start: new Date(schedule.value.maghrib.start).getTime() },
    { name: 'Isha', start: new Date(schedule.value.isha.start).getTime() },
  ]

  // Find next prayer starting after now
  let next = prayers.find((p) => p.start > now)
  let prefix = ''
  let diff = 0

  if (next) {
    prefix = next.name
    diff = next.start - now
  } else {
    // Next is tomorrow's Fajr
    prefix = 'Fajr (Tomorrow)'
    const tomorrowFajr = new Date(schedule.value.fajr.start).getTime() + 24 * 60 * 60 * 1000
    diff = tomorrowFajr - now
  }

  const secs = Math.floor(diff / 1000)
  const h = Math.floor(secs / 3600)
  const m = Math.floor((secs % 3600) / 60)
  const s = secs % 60

  const pad = (n: number) => String(n).padStart(2, '0')
  return `${localeStore.currentLocale === 'en' ? 'Next' : 'পরবর্তী'}: ${prefix} in ${pad(h)}:${pad(m)}:${pad(s)}`
})

// Check if any forbidden zone is currently active
const activeForbiddenZone = computed(() => {
  if (!schedule.value) return null
  return schedule.value.forbiddenZones.find((z) => isTimeBetween(z.start, z.end)) || null
})

// Helper to format C# ISO time to simple HH:MM AM/PM
const formatTimeStr = (isoStr: string) => {
  const d = new Date(isoStr)
  return d.toLocaleTimeString(
    localeStore.currentLocale === 'en' ? 'en-US' : 'bn-BD',
    { hour: '2-digit', minute: '2-digit' }
  )
}

onMounted(() => {
  requestLocation()
  timerInterval = setInterval(() => {
    currentTime.value = new Date()
  }, 1000)
})

onUnmounted(() => {
  if (timerInterval) clearInterval(timerInterval)
})
</script>

<template>
  <div class="min-h-screen py-10 px-4 sm:px-6 lg:px-8">
    <div class="max-w-4xl mx-auto">
      
      <!-- Sticky/Floating Warning Banner for Active Forbidden Period -->
      <transition
        enter-active-class="transform transition ease-out duration-300"
        enter-from-class="-translate-y-4 opacity-0"
        enter-to-class="translate-y-0 opacity-100"
        leave-active-class="transition ease-in duration-200"
        leave-to-class="-translate-y-4 opacity-0"
      >
        <div
          v-if="activeForbiddenZone"
          class="mb-6 p-4 bg-amber-500/20 border border-amber-500/40 rounded-2xl flex items-center justify-between text-amber-200 shadow-lg shadow-amber-500/5 backdrop-blur-md animate-pulse"
        >
          <div class="flex items-center gap-3">
            <span class="text-2xl">⚠️</span>
            <div>
              <p class="font-serif font-bold text-sm sm:text-base">
                {{ localeStore.currentLocale === 'en' ? 'Forbidden Prayer Time Active' : 'মাকরূহ সালাতের সময় চলমান' }}
              </p>
              <p class="text-xs text-amber-200/70">
                {{ activeForbiddenZone.name }}: {{ formatTimeStr(activeForbiddenZone.start) }} – {{ formatTimeStr(activeForbiddenZone.end) }}
              </p>
            </div>
          </div>
          <span class="text-xs font-mono font-bold uppercase tracking-wider bg-amber-500/20 px-2.5 py-1 rounded-lg border border-amber-500/30">
            {{ localeStore.currentLocale === 'en' ? 'Forbidden' : 'মাকরূহ' }}
          </span>
        </div>
      </transition>

      <!-- Main Widget Card -->
      <div class="bg-islamic-deep/40 border border-gold-500/10 rounded-3xl p-6 sm:p-8 backdrop-blur-md shadow-2xl relative overflow-hidden">
        
        <!-- Header Info -->
        <div class="flex flex-col sm:flex-row justify-between items-center gap-4 border-b border-gold-500/10 pb-6 mb-6">
          <div class="text-center sm:text-left">
            <h1 class="text-2xl sm:text-3xl font-serif font-bold bg-gradient-to-r from-gold-100 via-gold-300 to-gold-500 bg-clip-text text-transparent">
              {{ localeStore.currentLocale === 'en' ? 'Salah Schedule' : 'সালাতের সময়সূচী' }}
            </h1>
            <p class="text-xs text-gold-200/60 mt-1 flex items-center gap-2 justify-center sm:justify-start">
              <span>📍 {{ locationName }}</span>
              <button 
                @click="requestLocation"
                class="hover:text-gold-300 transition-colors text-[10px] font-bold uppercase tracking-wider border border-gold-500/20 px-2 py-0.5 rounded bg-gold-500/5 cursor-pointer"
              >
                {{ localeStore.currentLocale === 'en' ? 'Detect' : 'ডিটেক্ট' }}
              </button>
            </p>
          </div>
          
          <div class="text-center sm:text-right">
            <p class="text-sm font-serif font-bold text-gold-300">
              {{ schedule?.hijriDate || '... AH' }}
            </p>
            <p class="text-xs text-gold-200/55 mt-0.5">
              {{ formattedGregorianDate }}
            </p>
          </div>
        </div>

        <!-- Big Clock & Live Countdown -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 items-center bg-islamic-deep/60 border border-gold-500/5 rounded-2xl p-6 mb-8 text-center md:text-left">
          <div>
            <p class="text-[10px] uppercase font-bold tracking-widest text-gold-500">
              {{ localeStore.currentLocale === 'en' ? 'Current Time' : 'বর্তমান সময়' }}
            </p>
            <p class="text-3xl sm:text-4xl font-mono font-bold text-slate-100 mt-1 tracking-wider">
              {{ formattedTime }}
            </p>
          </div>
          <div class="md:text-right">
            <p class="text-sm sm:text-base font-serif font-bold text-gold-400 bg-gold-500/10 border border-gold-500/20 px-4 py-2 rounded-xl inline-block shadow-inner">
              {{ countdownText }}
            </p>
          </div>
        </div>

        <!-- Error State -->
        <div v-if="error" class="p-4 bg-rose-500/10 border border-rose-500/20 text-rose-300 rounded-2xl text-center mb-6">
          <p class="font-bold">⚠️ {{ error }}</p>
          <button @click="fetchSalahTimes" class="mt-2 text-xs font-bold text-gold-300 hover:underline">
            {{ localeStore.currentLocale === 'en' ? 'Try Again' : 'আবার চেষ্টা করুন' }}
          </button>
        </div>

        <!-- Loading State -->
        <div v-if="loading" class="flex flex-col items-center justify-center py-12">
          <div class="animate-spin rounded-full h-10 w-10 border-2 border-t-gold-400 border-gold-500/10 mb-4"></div>
          <p class="text-xs text-gold-200/50">
            {{ localeStore.currentLocale === 'en' ? 'Fetching coordinates & times...' : 'স্থানাঙ্ক ও সালাতের সময় আনা হচ্ছে...' }}
          </p>
        </div>

        <!-- Timings List -->
        <div v-else-if="schedule" class="space-y-4">
          
          <!-- Helper to render card -->
          <div
            v-for="prayer in [
              { key: 'Fajr', entry: schedule.fajr, emoji: '🌙', bnName: 'ফজর' },
              { key: 'Dhuhr', entry: schedule.dhuhr, emoji: '☀️', bnName: 'যোহর' },
              { key: 'Asr', entry: schedule.asr, emoji: '🌤️', bnName: 'আসর' },
              { key: 'Maghrib', entry: schedule.maghrib, emoji: '🌅', bnName: 'মাগরিব' },
              { key: 'Isha', entry: schedule.isha, emoji: '🌃', bnName: 'এশা' },
            ]"
            :key="prayer.key"
            class="transition-all duration-300 border rounded-2xl p-4 sm:p-5 flex items-center justify-between relative overflow-hidden"
            :class="
              isTimeBetween(prayer.entry.start, prayer.entry.end)
                ? 'bg-gradient-to-r from-emerald-950/90 to-emerald-900/90 border-emerald-500/40 text-slate-100 shadow-[0_0_20px_rgba(16,185,129,0.15)] ring-1 ring-emerald-500/20'
                : 'bg-islamic-deep/20 border-gold-500/5 text-slate-400 hover:bg-gold-500/5'
            "
          >
            <!-- Background glow for active prayer -->
            <div 
              v-if="isTimeBetween(prayer.entry.start, prayer.entry.end)"
              class="absolute inset-0 bg-[radial-gradient(circle_at_right,rgba(16,185,129,0.15)_0%,transparent_60%)] pointer-events-none"
            ></div>

            <div class="flex items-center gap-4">
              <span class="text-3xl filter drop-shadow">{{ prayer.emoji }}</span>
              <div>
                <h3 
                  class="font-serif font-bold text-base sm:text-lg transition-colors"
                  :class="isTimeBetween(prayer.entry.start, prayer.entry.end) ? 'text-gold-300' : 'text-slate-300'"
                >
                  {{ localeStore.currentLocale === 'en' ? prayer.key : prayer.bnName }}
                </h3>
                <p class="text-xs font-mono mt-0.5">
                  {{ formatTimeStr(prayer.entry.start) }} – {{ formatTimeStr(prayer.entry.end) }}
                </p>
              </div>
            </div>

            <div class="flex items-center gap-2">
              <span 
                v-if="isTimeBetween(prayer.entry.start, prayer.entry.end)"
                class="text-[9px] uppercase font-bold tracking-widest bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 px-2 py-1 rounded-md"
              >
                {{ localeStore.currentLocale === 'en' ? 'Active' : 'চলমান' }}
              </span>
              
              <!-- Forbidden warning in card if current time is inside a forbidden zone and this is the active prayer -->
              <span 
                v-if="isTimeBetween(prayer.entry.start, prayer.entry.end) && activeForbiddenZone"
                class="text-[9px] uppercase font-bold tracking-widest bg-rose-500/20 text-rose-300 border border-rose-500/30 px-2 py-1 rounded-md animate-pulse"
              >
                ⛔ {{ localeStore.currentLocale === 'en' ? 'Forbidden' : 'মাকরূহ' }}
              </span>
            </div>
          </div>

        </div>

        <!-- Bottom Collapsible Forbidden Zones Details -->
        <div class="mt-8 border-t border-gold-500/10 pt-6">
          <h2 class="font-serif font-bold text-sm sm:text-base text-gold-300 mb-4 flex items-center gap-2">
            <span>⛔</span>
            <span>{{ localeStore.currentLocale === 'en' ? 'Forbidden (Makruh) Prayer Windows' : 'মাকরূহ (নিষিদ্ধ) সালাতের সময়সূচী' }}</span>
          </h2>
          
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div 
              v-for="zone in schedule?.forbiddenZones" 
              :key="zone.name"
              class="p-3.5 border rounded-xl flex flex-col justify-between transition-colors bg-islamic-deep/20"
              :class="isTimeBetween(zone.start, zone.end) ? 'border-amber-500/40 bg-amber-500/5 text-amber-200' : 'border-gold-500/5 text-slate-400'"
            >
              <div>
                <p 
                  class="font-serif font-bold text-xs"
                  :class="isTimeBetween(zone.start, zone.end) ? 'text-amber-300' : 'text-slate-300'"
                >
                  {{ zone.name }}
                </p>
                <p class="text-[11px] font-mono mt-1">
                  {{ formatTimeStr(zone.start) }} – {{ formatTimeStr(zone.end) }}
                </p>
              </div>
              <span 
                v-if="isTimeBetween(zone.start, zone.end)"
                class="text-[9px] font-bold uppercase tracking-wider text-amber-400 mt-2 self-start"
              >
                ● {{ localeStore.currentLocale === 'en' ? 'Active Now' : 'বর্তমানে সক্রিয়' }}
              </span>
            </div>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>
