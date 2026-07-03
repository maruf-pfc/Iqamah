<script setup lang="ts">
import { ref, watch, computed, onMounted, onUnmounted } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useLocaleStore } from '@/stores/locale'
import { PrayerName, WaqtStatus, MissedReason } from '@/types/prayer.types'
import type { LogOfferedPrayerRequest, LogMissedPrayerRequest, PrayerLogDto } from '@/types/prayer.types'

const store = usePrayerStore()
const localeStore = useLocaleStore()

const ARABIC_NAMES = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء']
const PRAYER_ICONS = ['🌅', '☀️', '⛅', '🌇', '🌃']

const getLocalizedPrayerName = (prayer: number) => {
  const keys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'] as const
  const key = keys[prayer] || 'fajr'
  return localeStore.t(key)
}

const getLocalizedWaqt = (status: number) => {
  const keys = ['awwal', 'wast', 'akhir'] as const
  const key = keys[status] || 'awwal'
  return localeStore.t(key)
}

const getLocalizedMissedReason = (reason: number) => {
  const keys = ['impurity', 'sleep', 'forgetfulness', 'situational', 'laziness', 'distraction'] as const
  const key = keys[reason] || 'laziness'
  return localeStore.t(key)
}

// Date selection: Default to today
const selectedDate = ref<string>(new Date().toISOString().split('T')[0] ?? '')
const dailyLogs = ref<Record<number, PrayerLogDto>>({})

// Logging Modal / Bottom Sheet state
const isModalOpen = ref(false)
const editingPrayerName = ref<PrayerName | null>(null)
const logType = ref<'offered' | 'missed' | 'period'>('offered')

// Form inputs
const formWaqtStatus = ref<WaqtStatus>(WaqtStatus.AwwalAlWaqt)
const formMissedReason = ref<MissedReason>(MissedReason.UnexcusedLaziness)
const formIsJamaah = ref(false)
const formIsTraveling = ref(false)
const formIsJummah = ref(false)
const formIsHome = ref(false)
const formQuranNotes = ref('')
const formHasTasbih = ref(false)

// Gender preference
const isFemale = ref<boolean | null>(
  localStorage.getItem('iqamah_gender') === 'female'
    ? true
    : localStorage.getItem('iqamah_gender') === 'male'
      ? false
      : null
)

// Generate calendar bar
const getPastDays = () => {
  const days = []
  for (let i = 5; i >= 0; i--) {
    const d = new Date()
    d.setDate(d.getDate() - i)
    days.push({
      dateStr: d.toISOString().split('T')[0] ?? '',
      dayName: d.toLocaleDateString('bn-BD', { weekday: 'short' }),
      dayNum: d.getDate(),
    })
  }
  return days
}
const calendarDays = getPastDays()

// Hijri Date display (locally calculated roughly for context)
const getHijriDateStr = () => {
  // Rough Hijri calculation for decoration, SalahTimeView will pull real Hijri date if backend has it.
  const options: Intl.DateTimeFormatOptions = { calendar: 'islamic-umalqura', day: 'numeric', month: 'long', year: 'numeric' }
  return new Intl.DateTimeFormat('bn-BD-u-ca-islamic-umalqura', options).format(new Date())
}
const hijriDate = ref(getHijriDateStr())

const loadDailyLogs = async () => {
  try {
    await store.fetchPrayerLogs(selectedDate.value, selectedDate.value)
    const mapped: Record<number, PrayerLogDto> = {}
    store.prayerLogs.forEach((log) => {
      mapped[log.prayerName] = log
    })
    dailyLogs.value = mapped
  } catch (err) {
    console.error('Failed to load logs', err)
  }
}

// Stats & Streaks
const offeredCount = computed(() => {
  return Object.values(dailyLogs.value).filter(l => l.isOffered).length
})

const completionPercentage = computed(() => {
  return Math.round((offeredCount.value / 5) * 100)
})

// Local streak calculator
const streakDays = ref(0)
const loadStreak = () => {
  try {
    const logsData = localStorage.getItem('iqamah_prayer_logs')
    const logs: PrayerLogDto[] = logsData ? JSON.parse(logsData) : []
    
    // Group by date to count how many prayers were offered per day
    const daysWithPrayers: Record<string, number> = {}
    logs.forEach(l => {
      if (l.isOffered) {
        const dateStr = l.prayerDate.split('T')[0]
        if (dateStr) {
          daysWithPrayers[dateStr] = (daysWithPrayers[dateStr] || 0) + 1
        }
      }
    })
    
    // Compute streak backwards
    let currentStreak = 0
    const d = new Date()
    // Check today
    let checkStr = d.toISOString().split('T')[0]
    
    if (checkStr && daysWithPrayers[checkStr]) {
      currentStreak++
    } else {
      // If not today, check yesterday to see if streak is still alive
      d.setDate(d.getDate() - 1)
      const prevStr = d.toISOString().split('T')[0]
      if (prevStr && daysWithPrayers[prevStr]) {
        currentStreak++
        checkStr = prevStr
      }
    }
    
    if (currentStreak > 0 && checkStr) {
      while (true) {
        d.setDate(d.getDate() - 1)
        const nextStr = d.toISOString().split('T')[0]
        if (nextStr && daysWithPrayers[nextStr]) {
          currentStreak++
        } else {
          break
        }
      }
    }
    streakDays.value = currentStreak
  } catch (err) {
    console.error('Failed to calculate streak', err)
    streakDays.value = 0
  }
}

watch(selectedDate, () => {
  loadDailyLogs()
}, { immediate: true })

onMounted(() => {
  loadStreak()
  window.addEventListener('prayer-logged', loadDailyLogs)
})

onUnmounted(() => {
  window.removeEventListener('prayer-logged', loadDailyLogs)
})

const openLoggingModal = (prayer: PrayerName) => {
  editingPrayerName.value = prayer
  const existing = dailyLogs.value[prayer]

  if (existing) {
    if (!existing.isOffered && existing.missedReason === MissedReason.ExcusedImpurity) {
      logType.value = 'period'
    } else {
      logType.value = existing.isOffered ? 'offered' : 'missed'
    }
    formWaqtStatus.value = existing.waqtStatus ?? WaqtStatus.AwwalAlWaqt
    formMissedReason.value = existing.missedReason ?? MissedReason.UnexcusedLaziness
    formIsJamaah.value = existing.isJamaah
    formIsTraveling.value = existing.isTraveling
    formIsJummah.value = existing.isJummah
    formIsHome.value = existing.isHome
    formQuranNotes.value = existing.quranNotes ?? ''
    formHasTasbih.value = existing.hasTasbih ?? false
  } else {
    logType.value = 'offered'
    formWaqtStatus.value = WaqtStatus.AwwalAlWaqt
    formMissedReason.value = MissedReason.UnexcusedLaziness
    formIsJamaah.value = false
    formIsTraveling.value = false
    formIsJummah.value = false
    formIsHome.value = false
    formQuranNotes.value = ''
    formHasTasbih.value = false
  }

  isModalOpen.value = true
}

const toggleOfferedQuick = async (prayer: PrayerName) => {
  const existing = dailyLogs.value[prayer]
  
  try {
    if (existing) {
      // Toggle
      const payload = {
        prayerName: prayer,
        prayerDate: selectedDate.value,
        isOffered: !existing.isOffered,
        waqtStatus: WaqtStatus.AwwalAlWaqt,
        isTraveling: false,
        isJamaah: false,
        isJummah: false,
        isHome: false,
        hasTasbih: false,
      }
      await store.logPrayer(payload)
    } else {
      // Create offered
      const payload = {
        prayerName: prayer,
        prayerDate: selectedDate.value,
        isOffered: true,
        waqtStatus: WaqtStatus.AwwalAlWaqt,
        isTraveling: false,
        isJamaah: false,
        isJummah: false,
        isHome: false,
        hasTasbih: false,
      }
      await store.logPrayer(payload)
    }
    await loadDailyLogs()
    loadStreak()
  } catch (err) {
    console.error('Quick toggle error', err)
  }
}

const handleSaveLog = async () => {
  if (editingPrayerName.value === null) return

  try {
    let payload: LogOfferedPrayerRequest | LogMissedPrayerRequest

    if (logType.value === 'offered') {
      payload = {
        prayerName: editingPrayerName.value,
        prayerDate: selectedDate.value,
        isOffered: true,
        waqtStatus: formWaqtStatus.value,
        isJamaah: formIsJamaah.value,
        isTraveling: formIsTraveling.value,
        isJummah: formIsJummah.value,
        isHome: formIsHome.value,
        quranNotes: formQuranNotes.value || undefined,
        hasTasbih: formHasTasbih.value,
      }
    } else if (logType.value === 'period') {
      payload = {
        prayerName: editingPrayerName.value,
        prayerDate: selectedDate.value,
        isOffered: false,
        missedReason: MissedReason.ExcusedImpurity,
        isTraveling: false,
      }
    } else {
      payload = {
        prayerName: editingPrayerName.value,
        prayerDate: selectedDate.value,
        isOffered: false,
        missedReason: formMissedReason.value,
        isTraveling: formIsTraveling.value,
      }
    }

    await store.logPrayer(payload)
    await loadDailyLogs()
    loadStreak()
    isModalOpen.value = false
  } catch (err) {
    console.error('Error logging prayer:', err)
  }
}
</script>

<template>
  <div class="px-6 space-y-6">
    
    <!-- Greeting & Header -->
    <div class="flex items-center justify-between pt-4">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
          <span>আসসালামু আলাইকুম</span>
          <span class="text-glow-emerald">👋</span>
        </h1>
        <p class="text-xs font-semibold text-slate-400 dark:text-slate-500 mt-1">
          {{ selectedDate }} · {{ hijriDate }}
        </p>
      </div>
    </div>

    <!-- Circular Progress & Streak Combined Section -->
    <div class="grid grid-cols-2 gap-4">
      
      <!-- Today Completion Dial Card -->
      <div class="bg-m3-surface dark:bg-m3-dark-surface p-4 rounded-3xl border border-slate-200/50 dark:border-slate-800/80 shadow-sm flex flex-col items-center justify-center text-center">
        <div class="relative w-24 h-24 flex items-center justify-center">
          <svg class="w-full h-full transform -rotate-90">
            <circle cx="48" cy="48" r="38" fill="transparent" stroke="#E2E8F0" class="dark:stroke-slate-800" stroke-width="8" />
            <circle cx="48" cy="48" r="38" fill="transparent" stroke="#0F766E" class="dark:stroke-[#5EEAD4] transition-all duration-500" stroke-width="8" :stroke-dasharray="2 * Math.PI * 38" :stroke-dashoffset="2 * Math.PI * 38 - (completionPercentage / 100) * 2 * Math.PI * 38" stroke-linecap="round" />
          </svg>
          <div class="absolute flex flex-col items-center">
            <span class="text-lg font-bold text-slate-900 dark:text-white">{{ offeredCount }} / 5</span>
            <span class="text-[9px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider">{{ completionPercentage }}%</span>
          </div>
        </div>
        <span class="text-xs font-bold text-slate-600 dark:text-slate-300 mt-3">আজকের নামাজ</span>
      </div>

      <!-- Streak Motivational Card -->
      <div class="bg-m3-surface dark:bg-m3-dark-surface p-4 rounded-3xl border border-slate-200/50 dark:border-slate-800/80 shadow-sm flex flex-col items-center justify-center text-center">
        <div class="w-14 h-14 rounded-full bg-orange-500/10 flex items-center justify-center text-orange-500 dark:text-orange-400 mb-2">
          <span class="material-symbols-rounded text-3xl">local_fire_department</span>
        </div>
        <h3 class="text-lg font-bold text-slate-900 dark:text-white">
          {{ streakDays }} দিন
        </h3>
        <span class="text-xs font-bold text-slate-600 dark:text-slate-300 mt-1">অবিরাম নামাজ</span>
      </div>

    </div>

    <!-- Date selector horizontal strip -->
    <div class="bg-m3-surface dark:bg-m3-dark-surface p-3.5 rounded-3xl border border-slate-200/50 dark:border-slate-800/80 shadow-sm space-y-3">
      <div class="flex items-center justify-between px-1">
        <span class="text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1.5">
          <span class="material-symbols-rounded text-sm">calendar_month</span>
          তারিখ নির্বাচন করুন
        </span>
        <input 
          type="date"
          v-model="selectedDate"
          class="bg-slate-100 dark:bg-slate-800 border border-slate-200/30 dark:border-slate-700 text-xs font-bold text-slate-800 dark:text-slate-200 rounded-lg px-2 py-1 outline-none"
        />
      </div>
      <div class="grid grid-cols-6 gap-2">
        <button 
          v-for="day in calendarDays"
          :key="day.dateStr"
          @click="selectedDate = day.dateStr"
          class="flex flex-col items-center py-2.5 rounded-2xl border transition-all duration-200 cursor-pointer"
          :class="[selectedDate === day.dateStr ? 'bg-m3-primary-container dark:bg-m3-dark-primary-container text-m3-primary dark:text-m3-dark-primary border-m3-primary dark:border-m3-dark-primary font-bold shadow-sm' : 'border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700 text-slate-600 dark:text-slate-300']"
        >
          <span class="text-[9px] uppercase font-bold tracking-wider mb-1">{{ day.dayName }}</span>
          <span class="text-base font-semibold">{{ day.dayNum }}</span>
        </button>
      </div>
    </div>

    <!-- List of Prayer Cards -->
    <div class="space-y-3">
      <h2 class="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 px-1">
        দৈনিক সালাত ট্র্যাকার
      </h2>

      <div 
        v-for="p in [PrayerName.Fajr, PrayerName.Dhuhr, PrayerName.Asr, PrayerName.Maghrib, PrayerName.Isha]"
        :key="p"
        @click="toggleOfferedQuick(p)"
        @contextmenu.prevent="openLoggingModal(p)"
        class="bg-m3-surface dark:bg-m3-dark-surface p-4 rounded-3xl border border-slate-200/50 dark:border-slate-800/80 shadow-sm flex items-center justify-between hover:scale-[1.01] active:scale-[0.99] transition-all duration-250 cursor-pointer select-none relative overflow-hidden"
      >
        <!-- Indicator Left bar -->
        <div 
          :class="[dailyLogs[p]?.isOffered ? 'bg-m3-success' : dailyLogs[p] ? 'bg-m3-error' : 'bg-slate-200 dark:bg-slate-800']"
          class="absolute left-0 top-0 bottom-0 w-1.5 transition-colors duration-300"
        ></div>

        <div class="flex items-center gap-4.5 pl-2">
          <!-- Icon -->
          <div class="w-12 h-12 rounded-2xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-2xl">
            {{ PRAYER_ICONS[p] }}
          </div>
          <!-- Details -->
          <div>
            <div class="flex items-center gap-2">
              <span class="font-bold text-base text-slate-900 dark:text-white">{{ getLocalizedPrayerName(p) }}</span>
              <span class="font-serif text-xs text-slate-400 dark:text-slate-500">{{ ARABIC_NAMES[p] }}</span>
            </div>
            
            <!-- Metadata badges -->
            <div class="flex flex-wrap items-center gap-1.5 mt-1.5">
              <span v-if="dailyLogs[p]?.isJamaah" class="text-[9px] font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 px-2 py-0.5 rounded-full border border-emerald-500/10">জামায়াত</span>
              <span v-if="dailyLogs[p]?.isTraveling" class="text-[9px] font-bold bg-sky-500/10 text-sky-600 dark:text-sky-400 px-2 py-0.5 rounded-full border border-sky-500/10">মুসাফির</span>
              <span v-if="dailyLogs[p]?.isHome" class="text-[9px] font-bold bg-amber-500/10 text-amber-600 dark:text-amber-400 px-2 py-0.5 rounded-full border border-amber-500/10">বাসায়</span>
              <span v-if="dailyLogs[p]?.hasTasbih" class="text-[9px] font-bold bg-pink-500/10 text-pink-600 dark:text-pink-400 px-2 py-0.5 rounded-full border border-pink-500/10">📿 তাসবীহ</span>
              <span v-if="dailyLogs[p]?.quranNotes" class="text-[9px] font-bold bg-purple-500/10 text-purple-600 dark:text-purple-400 px-2 py-0.5 rounded-full border border-purple-500/10">📖 কোরআন</span>
              
              <!-- Punctuality / Missed Reason text -->
              <span v-if="dailyLogs[p]?.isOffered" class="text-[10px] font-semibold text-emerald-600 dark:text-emerald-400 block mt-0.5">
                {{ getLocalizedWaqt(dailyLogs[p].waqtStatus!) }} ওয়াক্ত
              </span>
              <span v-else-if="dailyLogs[p]" class="text-[10px] font-semibold text-rose-500 dark:text-rose-400 block mt-0.5">
                {{ getLocalizedMissedReason(dailyLogs[p].missedReason!) }}
              </span>
              <span v-else class="text-[10px] font-semibold text-slate-400 dark:text-slate-500 block mt-0.5">
                লিপিবদ্ধ নেই
              </span>
            </div>
          </div>
        </div>

        <!-- Right Offered Indicator Icon / More Options -->
        <div class="flex items-center gap-2">
          <!-- Checkmark / Circle Status Indicator -->
          <div 
            :class="[
              dailyLogs[p]?.isOffered 
                ? 'bg-m3-success text-white' 
                : dailyLogs[p]
                  ? 'bg-m3-error text-white'
                  : 'border-2 border-slate-300 dark:border-slate-700 bg-transparent text-transparent'
            ]"
            class="w-8 h-8 rounded-full flex items-center justify-center transition-all duration-300"
          >
            <span class="material-symbols-rounded text-lg font-bold">
              {{ dailyLogs[p]?.isOffered ? 'check' : dailyLogs[p] ? 'close' : '' }}
            </span>
          </div>

          <!-- Edit button icon -->
          <button 
            @click.stop="openLoggingModal(p)"
            class="w-8 h-8 rounded-full bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 flex items-center justify-center text-slate-500 dark:text-slate-400 cursor-pointer"
            title="বিস্তারিত সম্পাদনা"
          >
            <span class="material-symbols-rounded text-lg">edit</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Details/Edit Bottom Sheet Modal -->
    <div 
      v-if="isModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60"
      @click.self="isModalOpen = false"
    >
      <div class="bg-m3-surface dark:bg-m3-dark-surface rounded-[32px] w-full max-w-lg overflow-hidden shadow-2xl animate-slide-up border border-slate-200/50 dark:border-slate-800">
        <!-- Title -->
        <div class="px-6 py-4 bg-slate-50 dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between">
          <h3 class="font-bold text-lg text-slate-800 dark:text-slate-200">
            {{ getLocalizedPrayerName(editingPrayerName!) }} সালাত
          </h3>
          <button @click="isModalOpen = false" class="text-slate-400 hover:text-slate-600 text-xl font-bold cursor-pointer">&times;</button>
        </div>

        <!-- Body -->
        <div class="p-6 space-y-5 max-h-[400px] overflow-y-auto">
          <!-- Log Offered / Missed Switcher -->
          <div class="flex bg-slate-100 dark:bg-slate-800 p-1 rounded-2xl border border-slate-200 dark:border-slate-700">
            <button 
              @click="logType = 'offered'"
              :class="[logType === 'offered' ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 shadow font-bold' : 'text-slate-700 dark:text-slate-200']"
              class="flex-1 text-center py-2 text-xs font-bold rounded-xl transition-all cursor-pointer"
            >
              আদায় করেছি
            </button>
            <button 
              @click="logType = 'missed'"
              :class="[logType === 'missed' ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 shadow font-bold' : 'text-slate-700 dark:text-slate-200']"
              class="flex-1 text-center py-2 text-xs font-bold rounded-xl transition-all cursor-pointer"
            >
              ছুটে গেছে
            </button>
            <button 
              v-if="isFemale"
              @click="logType = 'period'"
              :class="[logType === 'period' ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 shadow font-bold' : 'text-slate-700 dark:text-slate-200']"
              class="flex-1 text-center py-2 text-xs font-bold rounded-xl transition-all cursor-pointer"
            >
              হায়েজ / নিফাস
            </button>
          </div>

          <!-- Offered form fields -->
          <div v-if="logType === 'offered'" class="space-y-4">
            <div>
              <label class="block text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-2">ওয়াক্তের সময়ানুবর্তিতা</label>
              <select v-model="formWaqtStatus" class="w-full bg-slate-100 dark:bg-slate-800 border border-slate-300 dark:border-slate-600 text-slate-900 dark:text-slate-100 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-teal-500">
                <option :value="WaqtStatus.AwwalAlWaqt">আউয়াল ওয়াক্ত (শুরুতে)</option>
                <option :value="WaqtStatus.WastAlWaqt">ওয়াসাত ওয়াক্ত (মাঝামাঝি)</option>
                <option :value="WaqtStatus.AkhirAlWaqt">আখির ওয়াক্ত (শেষের দিকে)</option>
              </select>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <label class="flex items-center gap-3 bg-slate-100 dark:bg-slate-800 p-3 rounded-2xl cursor-pointer border border-slate-200 dark:border-slate-700 hover:border-teal-500/50 transition-all select-none">
                <input type="checkbox" v-model="formIsJamaah" class="rounded text-teal-600 focus:ring-teal-500" />
                <span class="text-xs font-bold text-slate-800 dark:text-slate-100">জামায়াত</span>
              </label>

              <label class="flex items-center gap-3 bg-slate-100 dark:bg-slate-800 p-3 rounded-2xl cursor-pointer border border-slate-200 dark:border-slate-700 hover:border-teal-500/50 transition-all select-none">
                <input type="checkbox" v-model="formIsTraveling" class="rounded text-teal-600 focus:ring-teal-500" />
                <span class="text-xs font-bold text-slate-800 dark:text-slate-100">মুসাফির</span>
              </label>

              <label class="col-span-2 flex items-center gap-3 bg-slate-100 dark:bg-slate-800 p-3 rounded-2xl cursor-pointer border border-slate-200 dark:border-slate-700 hover:border-teal-500/50 transition-all select-none">
                <input type="checkbox" v-model="formIsHome" class="rounded text-teal-600 focus:ring-teal-500" />
                <span class="text-xs font-bold text-slate-700 dark:text-slate-300">বাসায় আদায় করেছি</span>
              </label>
            </div>

            <div class="pt-3 border-t border-slate-100 dark:border-slate-800 space-y-4">
              <label class="flex items-center gap-3 bg-slate-100 dark:bg-slate-800 p-3 rounded-2xl cursor-pointer border border-slate-200 dark:border-slate-700 hover:border-teal-500/50 transition-all select-none">
                <input type="checkbox" v-model="formHasTasbih" class="rounded text-teal-600 focus:ring-teal-500" />
                <span class="text-xs font-bold text-slate-800 dark:text-slate-100">সালাতের পর তাসবীহ</span>
              </label>

              <div>
                <label class="block text-xs font-bold text-slate-600 dark:text-slate-300 uppercase tracking-wider mb-2">কোরআন পাঠের নোট</label>
                <input type="text" v-model="formQuranNotes" placeholder="যেমন, সূরা আল-বাকারাহ ১-১০, পৃষ্ঠা ৫" class="w-full bg-slate-100 dark:bg-slate-800 border border-slate-300 dark:border-slate-600 text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-500 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-teal-500" />
              </div>
            </div>
          </div>

          <!-- Missed form fields -->
          <div v-else-if="logType === 'missed'" class="space-y-4">
            <div>
              <label class="block text-xs font-bold text-slate-600 dark:text-slate-300 uppercase tracking-wider mb-2">ছুটে যাওয়ার কারণ</label>
              <select v-model="formMissedReason" class="w-full bg-slate-100 dark:bg-slate-800 border border-slate-300 dark:border-slate-600 text-slate-900 dark:text-slate-100 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-teal-500">
                <optgroup label="ক্ষমাযোগ্য ওজর (Excused)">
                  <option :value="MissedReason.ExcusedSleep">ঘুম (নওম)</option>
                  <option :value="MissedReason.ExcusedForgetfulness">ভুলে যাওয়া (নিসইয়ান)</option>
                </optgroup>
                <optgroup label="ক্ষমা অযোগ্য (Unexcused)">
                  <option :value="MissedReason.UnexcusedLaziness">অলসতা (কাসাল)</option>
                  <option :value="MissedReason.UnexcusedDistraction">উদাসীনতা (গাফলাহ)</option>
                  <option :value="MissedReason.UnexcusedSituational">ব্যস্ততা / পরিস্থিতিগত</option>
                </optgroup>
              </select>
            </div>

            <label class="flex items-center gap-3 bg-slate-100 dark:bg-slate-800 p-3 rounded-2xl cursor-pointer border border-slate-200 dark:border-slate-700 hover:border-teal-500/50 transition-all select-none">
              <input type="checkbox" v-model="formIsTraveling" class="rounded text-teal-600 focus:ring-teal-500" />
              <span class="text-xs font-bold text-slate-800 dark:text-slate-100">সফররত (মুসাফির) ছিলাম</span>
            </label>
          </div>

          <!-- Period (Excused Impurity) -->
          <div v-else-if="logType === 'period'" class="p-6 bg-teal-500/5 border border-teal-500/10 rounded-2xl text-center space-y-2">
            <span class="text-3xl block">🌸</span>
            <h4 class="font-bold text-sm text-teal-700 dark:text-teal-400">হায়েজ / নিফাস অব্যাহতি</h4>
            <p class="text-xs text-slate-500 leading-relaxed max-w-xs mx-auto">
              মাসিক ঋতুস্রাব বা সন্তান প্রসব পরবর্তী ওজরের কারণে সালাতের বাধ্যবাধকতা সাময়িকভাবে অব্যাহতিপ্রাপ্ত। কোনো কাজার প্রয়োজন নেই।
            </p>
          </div>
        </div>

        <!-- Actions -->
        <div class="px-6 py-4 bg-slate-50 dark:bg-slate-800 border-t border-slate-200 dark:border-slate-700 flex items-center justify-end gap-3">
          <button @click="isModalOpen = false" class="text-xs font-bold text-slate-600 dark:text-slate-400 px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer">বাতিল</button>
          <button @click="handleSaveLog" class="bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 font-bold text-xs px-5 py-2.5 rounded-xl shadow cursor-pointer">সংরক্ষণ করুন</button>
        </div>
      </div>
    </div>

  </div>
</template>
