<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useLocaleStore } from '@/stores/locale'
import { Coordinates, CalculationMethod, PrayerTimes, Madhab } from 'adhan'

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

const router = useRouter()
const localeStore = useLocaleStore()

const latitude = ref<number>(23.7639)
const longitude = ref<number>(90.3889)
const locationName = ref<string>('ঢাকা, বাংলাদেশ (ডিফল্ট)')
const loading = ref<boolean>(false)
const error = ref<string | null>(null)
const schedule = ref<PrayerSchedule | null>(null)
const currentTime = ref<Date>(new Date())

let timerInterval: ReturnType<typeof setInterval> | null = null

const fetchSalahTimes = async () => {
  loading.value = true
  error.value = null
  try {
    const coords = new Coordinates(latitude.value, longitude.value)
    const date = new Date()
    const params = CalculationMethod.Karachi()
    params.madhab = Madhab.Hanafi

    const prayerTimes = new PrayerTimes(coords, date, params)

    const tomorrow = new Date(date)
    tomorrow.setDate(date.getDate() + 1)
    const tomorrowTimes = new PrayerTimes(coords, tomorrow, params)
    const tomorrowFajr = tomorrowTimes.fajr

    const isBn = localeStore.currentLocale === 'bn'

    const zones = [
      {
        name: isBn ? 'সূর্যোদয়' : 'Sunrise',
        start: prayerTimes.sunrise.toISOString(),
        end: new Date(prayerTimes.sunrise.getTime() + 15 * 60 * 1000).toISOString(),
        isActive: false
      },
      {
        name: isBn ? 'দ্বিপ্রহর' : 'Noon (Istiwa)',
        start: new Date(prayerTimes.dhuhr.getTime() - 10 * 60 * 1000).toISOString(),
        end: prayerTimes.dhuhr.toISOString(),
        isActive: false
      },
      {
        name: isBn ? 'সূর্যাস্ত' : 'Sunset',
        start: new Date(prayerTimes.maghrib.getTime() - 20 * 60 * 1000).toISOString(),
        end: prayerTimes.maghrib.toISOString(),
        isActive: false
      }
    ]

    schedule.value = {
      fajr: {
        start: prayerTimes.fajr.toISOString(),
        end: prayerTimes.sunrise.toISOString(),
        name: 'Fajr',
        isActive: false
      },
      dhuhr: {
        start: prayerTimes.dhuhr.toISOString(),
        end: prayerTimes.asr.toISOString(),
        name: 'Dhuhr',
        isActive: false
      },
      asr: {
        start: prayerTimes.asr.toISOString(),
        end: prayerTimes.maghrib.toISOString(),
        name: 'Asr',
        isActive: false
      },
      maghrib: {
        start: prayerTimes.maghrib.toISOString(),
        end: prayerTimes.isha.toISOString(),
        name: 'Maghrib',
        isActive: false
      },
      isha: {
        start: prayerTimes.isha.toISOString(),
        end: tomorrowFajr.toISOString(),
        name: 'Isha',
        isActive: false
      },
      sunrise: prayerTimes.sunrise.toISOString(),
      forbiddenZones: zones,
      isAnyForbiddenNow: false
    }
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'ত্রুটি ঘটেছে।'
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
        locationName.value = 'সনাক্তকৃত স্থানাঙ্ক'
        fetchSalahTimes()
      },
      () => {
        latitude.value = 23.7639
        longitude.value = 90.3889
        locationName.value = 'ঢাকা, বাংলাদেশ (ডিফল্ট)'
        fetchSalahTimes()
      }
    )
  } else {
    fetchSalahTimes()
  }
}

const formattedGregorianDate = computed(() => {
  return currentTime.value.toLocaleDateString('bn-BD', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })
})

const formattedTime = computed(() => {
  return currentTime.value.toLocaleTimeString('bn-BD', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
})

const isTimeBetween = (startStr: string, endStr: string) => {
  const now = currentTime.value.getTime()
  const start = new Date(startStr).getTime()
  const end = new Date(endStr).getTime()
  return now >= start && now < end
}

const countdownText = computed(() => {
  if (!schedule.value) return ''
  const now = currentTime.value.getTime()
  const prayers = [
    { name: 'ফজর', start: new Date(schedule.value.fajr.start).getTime() },
    { name: 'যোহর', start: new Date(schedule.value.dhuhr.start).getTime() },
    { name: 'আসর', start: new Date(schedule.value.asr.start).getTime() },
    { name: 'মাগরিব', start: new Date(schedule.value.maghrib.start).getTime() },
    { name: 'ইশা', start: new Date(schedule.value.isha.start).getTime() },
  ]

  let next = prayers.find((p) => p.start > now)
  let prefix = ''
  let diff = 0

  if (next) {
    prefix = next.name
    diff = next.start - now
  } else {
    prefix = 'ফজর (আগামীকাল)'
    const tomorrowFajr = new Date(schedule.value.fajr.start).getTime() + 24 * 60 * 60 * 1000
    diff = tomorrowFajr - now
  }

  const secs = Math.floor(diff / 1000)
  const h = Math.floor(secs / 3600)
  const m = Math.floor((secs % 3600) / 60)
  const s = secs % 60

  const pad = (n: number) => String(n).padStart(2, '0')
  return `পরবর্তী: ${prefix} (${pad(h)}:${pad(m)}:${pad(s)})`
})

const activeForbiddenZone = computed(() => {
  if (!schedule.value) return null
  return schedule.value.forbiddenZones.find((z) => isTimeBetween(z.start, z.end)) || null
})

const formatTimeStr = (isoStr: string) => {
  const d = new Date(isoStr)
  return d.toLocaleTimeString('bn-BD', { hour: '2-digit', minute: '2-digit' })
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
  <div class="px-6 space-y-6">
    <!-- Header with Back Button -->
    <div class="flex items-center gap-3 pt-4">
      <button 
        @click="router.push('/settings')"
        class="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-700 dark:text-slate-300 cursor-pointer"
      >
        <span class="material-symbols-rounded">arrow_back</span>
      </button>
      <div>
        <h1 class="text-xl font-bold text-slate-900 dark:text-white">সালাতের সময়সূচী</h1>
        <p class="text-[11px] text-slate-400 dark:text-slate-500 font-semibold">
          📍 {{ locationName }}
        </p>
      </div>
      <button 
        @click="requestLocation"
        class="ml-auto w-10 h-10 rounded-full bg-slate-150 dark:bg-slate-800 flex items-center justify-center text-teal-650 dark:text-teal-400 cursor-pointer"
        title="অবস্থান আপডেট করুন"
      >
        <span class="material-symbols-rounded">my_location</span>
      </button>
    </div>

    <!-- Active Forbidden Warning -->
    <transition
      enter-active-class="transform transition ease-out duration-250"
      enter-from-class="-translate-y-2 opacity-0"
      enter-to-class="translate-y-0 opacity-100"
      leave-active-class="transition ease-in duration-200"
      leave-to-class="-translate-y-2 opacity-0"
    >
      <div 
        v-if="activeForbiddenZone"
        class="p-4 rounded-3xl bg-amber-500/10 border border-amber-500/20 text-amber-800 dark:text-amber-350 space-y-1 shadow-sm"
      >
        <div class="flex items-center gap-2 text-sm font-bold">
          <span class="material-symbols-rounded text-lg">warning</span>
          <span>মাকরূহ সময় চলমান</span>
        </div>
        <p class="text-xs leading-relaxed opacity-90">
          {{ activeForbiddenZone.name }}: {{ formatTimeStr(activeForbiddenZone.start) }} – {{ formatTimeStr(activeForbiddenZone.end) }}
        </p>
      </div>
    </transition>

    <!-- Time & Countdown Card -->
    <div class="bg-m3-surface dark:bg-m3-dark-surface p-5 rounded-[32px] border border-slate-200/50 dark:border-slate-800/80 shadow-sm text-center space-y-3">
      <span class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider block">বর্তমান সময়</span>
      <h2 class="text-3xl font-black text-slate-900 dark:text-white tracking-widest font-mono">
        {{ formattedTime }}
      </h2>
      <div class="inline-block bg-teal-500/10 dark:bg-teal-500/20 text-teal-700 dark:text-teal-300 px-4 py-1.5 rounded-full border border-teal-500/10 text-xs font-bold mt-1">
        {{ countdownText }}
      </div>
    </div>

    <!-- Timings List -->
    <div class="space-y-3">
      <h3 class="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 px-1">আজকের সালাতের ওয়াক্ত</h3>
      
      <div v-if="loading" class="flex flex-col items-center py-10">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-m3-primary mb-2"></div>
        <p class="text-slate-400 text-xs font-bold">ওয়াক্ত লোড করা হচ্ছে...</p>
      </div>

      <div v-else-if="error" class="p-4 rounded-2xl bg-rose-500/10 border border-rose-500/20 text-rose-800 dark:text-rose-300 text-center text-xs font-bold">
        <span>{{ error }}</span>
      </div>

      <div v-else-if="schedule" class="space-y-3">
        <div 
          v-for="p in [
            { key: 'Fajr', entry: schedule.fajr, emoji: '🌅', bnName: 'ফজর' },
            { key: 'Dhuhr', entry: schedule.dhuhr, emoji: '☀️', bnName: 'যোহর' },
            { key: 'Asr', entry: schedule.asr, emoji: '🌤️', bnName: 'আসর' },
            { key: 'Maghrib', entry: schedule.maghrib, emoji: '🌇', bnName: 'মাগরিব' },
            { key: 'Isha', entry: schedule.isha, emoji: '🌃', bnName: 'ইশা' }
          ]"
          :key="p.key"
          :class="[
            isTimeBetween(p.entry.start, p.entry.end) 
              ? 'bg-m3-primary-container dark:bg-m3-dark-primary-container border-m3-primary dark:border-m3-dark-primary text-m3-primary dark:text-m3-dark-primary font-bold shadow-sm'
              : 'bg-m3-surface dark:bg-m3-dark-surface border-slate-200/50 dark:border-slate-800/80 text-slate-800 dark:text-slate-200'
          ]"
          class="p-4 rounded-[24px] border flex items-center justify-between transition-all duration-300"
        >
          <div class="flex items-center gap-4">
            <span class="text-2xl">{{ p.emoji }}</span>
            <div>
              <span class="font-bold block text-sm">{{ p.bnName }}</span>
              <span class="text-[11px] font-semibold text-slate-450 dark:text-slate-400 block mt-0.5">
                {{ formatTimeStr(p.entry.start) }} - {{ formatTimeStr(p.entry.end) }}
              </span>
            </div>
          </div>

          <span 
            v-if="isTimeBetween(p.entry.start, p.entry.end)"
            class="text-[9px] uppercase font-bold tracking-widest bg-m3-primary text-white px-2 py-1 rounded-md"
          >
            চলমান
          </span>
        </div>
      </div>
    </div>

    <!-- Forbidden Windows -->
    <div v-if="schedule" class="space-y-3 pb-8">
      <h3 class="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 px-1">নিষিদ্ধ / মাকরূহ সময়সমূহ</h3>
      
      <div class="grid grid-cols-3 gap-2">
        <div 
          v-for="zone in schedule.forbiddenZones"
          :key="zone.name"
          :class="[isTimeBetween(zone.start, zone.end) ? 'border-amber-500 bg-amber-500/5 text-amber-700 dark:text-amber-300' : 'border-slate-200/50 dark:border-slate-800/80 bg-m3-surface dark:bg-m3-dark-surface text-slate-500 dark:text-slate-400']"
          class="p-3 border rounded-2xl text-center space-y-1.5 transition-colors"
        >
          <span class="font-bold text-[10px] block leading-tight">{{ zone.name }}</span>
          <span class="font-mono text-[9px] block">{{ formatTimeStr(zone.start) }} - {{ formatTimeStr(zone.end) }}</span>
          <span v-if="isTimeBetween(zone.start, zone.end)" class="text-[8px] font-bold text-amber-500 uppercase block">সক্রিয়</span>
        </div>
      </div>
    </div>

  </div>
</template>
