<script setup lang="ts">
import { ref, watch, computed, onMounted, onUnmounted } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useLocaleStore } from '@/stores/locale'
import { PrayerName, WaqtStatus, MissedReason } from '@/types/prayer.types'
import type { LogOfferedPrayerRequest, LogMissedPrayerRequest, PrayerLogDto } from '@/types/prayer.types'
import PrayerTimetable from '@/components/PrayerTimetable.vue'
import { bangladeshDate, isCalendarDate } from '@/services/calendar'
import { readLogs } from '@/services/backup'
import { useTimingStore } from '@/stores/timing'
import AppDialog from '@/components/AppDialog.vue'
import { useRoute } from 'vue-router'
import { readPreference } from '@/services/preferences'

const store = usePrayerStore()
const localeStore = useLocaleStore()
const timing = useTimingStore()
const feedback = ref<'log_saved' | 'log_failed' | null>(null)
const route = useRoute()

const ARABIC_NAMES = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء']
const PRAYER_ICONS = ['wb_twilight', 'light_mode', 'partly_cloudy_day', 'wb_twilight', 'dark_mode']

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
const selectedDate = ref<string>(bangladeshDate())
const dailyLogs = ref<Record<number, PrayerLogDto>>({})

// Logging Modal / Bottom Sheet state
const isModalOpen = ref(false)
const isPrayerPickerOpen = ref(false)
const openPrayerPicker = () => { isPrayerPickerOpen.value = true }
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
  readPreference('iqamah_user_g') === 'f'
    ? true
    : readPreference('iqamah_user_g') === 'm'
      ? false
      : null
)

// Generate calendar bar
const getPastDays = () => {
  const days = []
  for (let i = 5; i >= 0; i--) {
    const d = new Date(`${timing.today}T12:00:00+06:00`)
    d.setUTCDate(d.getUTCDate() - i)
    days.push({
      dateStr: bangladeshDate(d),
      dayName: d.toLocaleDateString(localeStore.currentLocale === 'bn' ? 'bn-BD' : 'en', { timeZone: 'Asia/Dhaka', weekday: 'short' }),
      dayNum: d.toLocaleDateString(localeStore.currentLocale === 'bn' ? 'bn-BD' : 'en', { timeZone: 'Asia/Dhaka', day: 'numeric' }),
    })
  }
  return days
}
const calendarDays = computed(getPastDays)

// Hijri Date display (locally calculated roughly for context)
const getHijriDateStr = () => {
  if (!isCalendarDate(selectedDate.value)) return ''
  // Rough Hijri calculation for decoration, SalahTimeView will pull real Hijri date if backend has it.
  const options: Intl.DateTimeFormatOptions = { calendar: 'islamic-umalqura', day: 'numeric', month: 'long', year: 'numeric' }
  return new Intl.DateTimeFormat(localeStore.currentLocale === 'bn' ? 'bn-BD-u-ca-islamic-umalqura' : 'en-u-ca-islamic-umalqura', { ...options, timeZone: 'Asia/Dhaka' }).format(new Date(`${selectedDate.value}T12:00:00+06:00`))
}
const hijriDate = computed(getHijriDateStr)

const loadDailyLogs = async () => {
  try {
    await store.fetchPrayerLogs(selectedDate.value, selectedDate.value)
    const mapped: Record<number, PrayerLogDto> = {}
    store.prayerLogs.forEach((log) => {
      mapped[log.prayerName] = log
    })
    dailyLogs.value = mapped
  } catch {
    feedback.value = 'log_failed'
  }
}

// Stats & Streaks
const offeredCount = computed(() => {
  return Object.values(dailyLogs.value).filter(l => l.isOffered).length
})
const dailyObligationCount = computed(() => 5 - Object.values(dailyLogs.value).filter(l => !l.isOffered && l.missedReason === MissedReason.ExcusedImpurity).length)

const completionPercentage = computed(() => {
  return dailyObligationCount.value ? Math.round((offeredCount.value / dailyObligationCount.value) * 100) : 0
})

// Local streak calculator
const streakDays = ref(0)
const loadStreak = () => {
  try {
    const logs = readLogs()
    
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
    const d = new Date(`${timing.today}T12:00:00+06:00`)
    // Check today
    let checkStr = bangladeshDate(d)
    
    if (checkStr && daysWithPrayers[checkStr]) {
      currentStreak++
    } else {
      // If not today, check yesterday to see if streak is still alive
      d.setUTCDate(d.getUTCDate() - 1)
      const prevStr = bangladeshDate(d)
      if (prevStr && daysWithPrayers[prevStr]) {
        currentStreak++
        checkStr = prevStr
      }
    }
    
    if (currentStreak > 0 && checkStr) {
      while (true) {
        d.setUTCDate(d.getUTCDate() - 1)
        const nextStr = bangladeshDate(d)
        if (nextStr && daysWithPrayers[nextStr]) {
          currentStreak++
        } else {
          break
        }
      }
    }
    streakDays.value = currentStreak
  } catch {
    streakDays.value = 0
  }
}

watch(selectedDate, () => {
  loadDailyLogs()
}, { immediate: true })
watch(() => timing.today, (today, previous) => {
  if (selectedDate.value === previous) selectedDate.value = today
  loadStreak()
})

onMounted(() => {
  loadStreak()
  if (route.query.log) openPrayerPicker()
  window.addEventListener('iqamah-open-log', openPrayerPicker)
  window.addEventListener('prayer-logged', loadDailyLogs)
})

onUnmounted(() => {
  window.removeEventListener('prayer-logged', loadDailyLogs)
  window.removeEventListener('iqamah-open-log', openPrayerPicker)
})

const openLoggingModal = (prayer: PrayerName) => {
  isPrayerPickerOpen.value = false
  feedback.value = null
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

const editPrayer = (prayer: PrayerName) => {
  openLoggingModal(prayer)
}

const handleSaveLog = async () => {
  if (editingPrayerName.value === null || store.loading) return

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
        quranNotes: formQuranNotes.value,
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
    feedback.value = 'log_saved'
    await store.fetchPendingQazas()
  } catch {
    feedback.value = 'log_failed'
  }
}
</script>

<template>
  <div class="px-6 space-y-6">
    
    <!-- Greeting & Header -->
    <div class="flex items-center justify-between pt-4">
      <div>
        <h1 class="text-2xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
          <span>{{ localeStore.t('greeting') }}</span>
        </h1>
        <p class="text-xs font-semibold text-slate-400 dark:text-slate-500 mt-1">
          {{ selectedDate }} · {{ hijriDate }}
        </p>
      </div>
    </div>

    <PrayerTimetable :date="selectedDate" />
    <p v-if="feedback" role="status" class="iq-secondary">{{ localeStore.t(feedback) }}</p>

    <div class="iq-surface grid grid-cols-2 gap-4">
      <div>
        <p class="iq-secondary">{{ localeStore.t('offered') }}</p>
        <p class="iq-section-heading">{{ dailyObligationCount ? `${offeredCount} / ${dailyObligationCount} · ${completionPercentage}%` : localeStore.t('no_qaza_required') }}</p>
      </div>
      <div>
        <p class="iq-secondary">{{ localeStore.t('streak') }}</p>
        <p class="iq-section-heading">{{ localeStore.t('streak_days', { count: streakDays }) }}</p>
      </div>
    </div>

    <!-- Date selector horizontal strip -->
    <div class="bg-m3-surface dark:bg-m3-dark-surface p-3.5 rounded-3xl border border-slate-200/50 dark:border-slate-800/80 shadow-sm space-y-3">
      <div class="flex items-center justify-between flex-wrap gap-3 px-1">
        <span class="text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1.5">
          <span class="material-symbols-rounded text-sm">calendar_month</span>
           {{ localeStore.t('select_date') }}
        </span>
        <input 
          type="date"
          v-model="selectedDate"
          :aria-label="localeStore.t('select_date')"
          class="bg-slate-100 dark:bg-slate-800 border border-slate-200/30 dark:border-slate-700 text-xs font-bold text-slate-800 dark:text-slate-200 rounded-lg px-2 py-1 outline-none"
        />
      </div>
      <div class="prayer-date-grid grid grid-cols-6 gap-2">
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
        {{ localeStore.t('daily_prayers') }}
      </h2>

      <div 
        v-for="p in [PrayerName.Fajr, PrayerName.Dhuhr, PrayerName.Asr, PrayerName.Maghrib, PrayerName.Isha]"
        :key="p"
        class="iq-surface prayer-log-row flex items-center justify-between gap-3 relative"
      >
        <div class="flex items-center gap-3 min-w-0">
          <!-- Icon -->
          <div class="prayer-log-icon w-10 h-10 shrink-0 flex items-center justify-center">
            <span class="material-symbols-rounded" aria-hidden="true">{{ PRAYER_ICONS[p] }}</span>
          </div>
          <!-- Details -->
          <div>
            <div class="flex items-center gap-2 flex-wrap">
              <span class="font-bold text-base text-slate-900 dark:text-white">{{ getLocalizedPrayerName(p) }}</span>
               <span lang="ar" class="font-arabic text-sm text-slate-500 dark:text-slate-400">{{ ARABIC_NAMES[p] }}</span>
            </div>
            
            <!-- Metadata badges -->
            <div class="flex flex-wrap items-center gap-1.5 mt-1.5">
              <span v-if="dailyLogs[p]?.isJamaah" class="iq-secondary">{{ localeStore.t('jamaah') }} ·</span>
              <span v-if="dailyLogs[p]?.isTraveling" class="iq-secondary">{{ localeStore.t('traveling') }} ·</span>
              <span v-if="dailyLogs[p]?.isHome" class="iq-secondary">{{ localeStore.t('prayed_at_home') }} ·</span>
              <span v-if="dailyLogs[p]?.hasTasbih" class="iq-secondary">{{ localeStore.t('track_tasbih') }} ·</span>
              <span v-if="dailyLogs[p]?.quranNotes" class="iq-secondary">{{ localeStore.t('quran_notes') }} ·</span>
              
              <!-- Punctuality / Missed Reason text -->
              <span v-if="dailyLogs[p]?.isOffered" class="iq-secondary block mt-0.5">
                 {{ localeStore.t('offered') }} · {{ getLocalizedWaqt(dailyLogs[p].waqtStatus!) }}
              </span>
              <span v-else-if="dailyLogs[p]" class="iq-secondary block mt-0.5">
                {{ getLocalizedMissedReason(dailyLogs[p].missedReason!) }}
              </span>
              <span v-else class="iq-secondary block mt-0.5">
                 {{ localeStore.t('not_logged') }}
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
                : dailyLogs[p]?.missedReason === MissedReason.ExcusedImpurity
                  ? 'bg-m3-secondary text-white'
                : dailyLogs[p]
                  ? 'bg-m3-error text-white'
                  : 'border-2 border-slate-300 dark:border-slate-700 bg-transparent text-transparent'
            ]"
            class="w-8 h-8 rounded-full flex items-center justify-center transition-all duration-300"
          >
            <span class="material-symbols-rounded text-lg font-bold">
              {{ dailyLogs[p]?.isOffered ? 'check' : dailyLogs[p]?.missedReason === MissedReason.ExcusedImpurity ? 'remove' : dailyLogs[p] ? 'close' : '' }}
            </span>
          </div>

          <!-- Edit button icon -->
          <button 
            @click.stop="editPrayer(p)"
            class="iq-button iq-button-secondary"
            :aria-label="localeStore.t('log_salah', { salah: getLocalizedPrayerName(p) })"
          >
            {{ localeStore.t(dailyLogs[p] ? 'edit' : 'log') }}
          </button>
        </div>
      </div>
    </div>

    <AppDialog v-model="isPrayerPickerOpen" :label="localeStore.t('daily_prayers')">
      <div class="p-6 space-y-4">
        <h2 class="iq-section-heading">{{ localeStore.t('daily_prayers') }}</h2>
        <button v-for="(key, index) in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'] as const" :key="key" class="iq-button iq-button-secondary w-full" @click="openLoggingModal(index)">{{ localeStore.t(key) }}</button>
        <button class="iq-button w-full" @click="isPrayerPickerOpen = false">{{ localeStore.t('close') }}</button>
      </div>
    </AppDialog>

    <!-- Details/Edit Bottom Sheet Modal -->
    <AppDialog v-model="isModalOpen" :label="localeStore.t('log_salah', { salah: getLocalizedPrayerName(editingPrayerName ?? 0) })">
       <div class="bg-m3-surface dark:bg-m3-dark-surface w-full overflow-hidden">
        <!-- Title -->
        <div class="px-6 py-4 bg-slate-50 dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between">
          <h3 id="log-dialog-heading" class="font-bold text-lg text-slate-800 dark:text-slate-200">
            {{ localeStore.t('log_salah', { salah: getLocalizedPrayerName(editingPrayerName!) }) }}
          </h3>
          <button @click="isModalOpen = false" :aria-label="localeStore.t('close')" class="text-slate-400 hover:text-slate-600 text-xl font-bold cursor-pointer">&times;</button>
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
              {{ localeStore.t('offered') }}
            </button>
            <button 
              @click="logType = 'missed'"
              :class="[logType === 'missed' ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 shadow font-bold' : 'text-slate-700 dark:text-slate-200']"
              class="flex-1 text-center py-2 text-xs font-bold rounded-xl transition-all cursor-pointer"
            >
              {{ localeStore.t('missed') }}
            </button>
            <button 
              v-if="isFemale"
              @click="logType = 'period'"
              :class="[logType === 'period' ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 shadow font-bold' : 'text-slate-700 dark:text-slate-200']"
              class="flex-1 text-center py-2 text-xs font-bold rounded-xl transition-all cursor-pointer"
            >
              {{ localeStore.t('period_hayd') }}
            </button>
          </div>

          <!-- Offered form fields -->
          <div v-if="logType === 'offered'" class="space-y-4">
            <div>
              <label for="log-waqt" class="block text-sm font-bold mb-2">{{ localeStore.t('waqt_punctuality') }}</label>
              <select id="log-waqt" v-model="formWaqtStatus" class="w-full bg-slate-100 dark:bg-slate-800 border border-slate-300 dark:border-slate-600 text-slate-900 dark:text-slate-100 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-teal-500">
                <option :value="WaqtStatus.AwwalAlWaqt">{{ localeStore.t('awwal') }}</option>
                <option :value="WaqtStatus.WastAlWaqt">{{ localeStore.t('wast') }}</option>
                <option :value="WaqtStatus.AkhirAlWaqt">{{ localeStore.t('akhir') }}</option>
              </select>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <label class="flex items-center gap-3 bg-slate-100 dark:bg-slate-800 p-3 rounded-2xl cursor-pointer border border-slate-200 dark:border-slate-700 hover:border-teal-500/50 transition-all select-none">
                <input type="checkbox" v-model="formIsJamaah" class="rounded text-teal-600 focus:ring-teal-500" />
                <span class="text-xs font-bold text-slate-800 dark:text-slate-100">{{ localeStore.t('congregation') }}</span>
              </label>

              <label class="flex items-center gap-3 bg-slate-100 dark:bg-slate-800 p-3 rounded-2xl cursor-pointer border border-slate-200 dark:border-slate-700 hover:border-teal-500/50 transition-all select-none">
                <input type="checkbox" v-model="formIsTraveling" class="rounded text-teal-600 focus:ring-teal-500" />
                <span class="text-xs font-bold text-slate-800 dark:text-slate-100">{{ localeStore.t('traveling') }}</span>
              </label>

              <label class="col-span-2 flex items-center gap-3 bg-slate-100 dark:bg-slate-800 p-3 rounded-2xl cursor-pointer border border-slate-200 dark:border-slate-700 hover:border-teal-500/50 transition-all select-none">
                <input type="checkbox" v-model="formIsHome" class="rounded text-teal-600 focus:ring-teal-500" />
                <span class="text-xs font-bold text-slate-700 dark:text-slate-300">{{ localeStore.t('prayed_at_home') }}</span>
              </label>
            </div>

            <label v-if="editingPrayerName === PrayerName.Dhuhr" class="flex items-center gap-3">
              <input type="checkbox" v-model="formIsJummah" />{{ localeStore.t('friday_prayer') }}
            </label>
            <div class="pt-3 border-t border-slate-100 dark:border-slate-800 space-y-4">
              <label class="flex items-center gap-3 bg-slate-100 dark:bg-slate-800 p-3 rounded-2xl cursor-pointer border border-slate-200 dark:border-slate-700 hover:border-teal-500/50 transition-all select-none">
                <input type="checkbox" v-model="formHasTasbih" class="rounded text-teal-600 focus:ring-teal-500" />
                <span class="text-xs font-bold text-slate-800 dark:text-slate-100">{{ localeStore.t('track_tasbih') }}</span>
              </label>

              <div>
                <label for="log-notes" class="block text-sm font-bold mb-2">{{ localeStore.t('quran_notes') }}</label>
                <input id="log-notes" type="text" v-model="formQuranNotes" :placeholder="localeStore.t('quran_notes_placeholder')" class="w-full bg-slate-100 dark:bg-slate-800 border border-slate-300 dark:border-slate-600 text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-500 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-teal-500" />
              </div>
            </div>
          </div>

          <!-- Missed form fields -->
          <div v-else-if="logType === 'missed'" class="space-y-4">
            <div>
              <label for="log-reason" class="block text-sm font-bold mb-2">{{ localeStore.t('reason_missed') }}</label>
              <select id="log-reason" v-model="formMissedReason" class="w-full bg-slate-100 dark:bg-slate-800 border border-slate-300 dark:border-slate-600 text-slate-900 dark:text-slate-100 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-teal-500">
                <optgroup :label="localeStore.t('excused_optgroup')">
                  <option :value="MissedReason.ExcusedSleep">{{ localeStore.t('sleep') }}</option>
                  <option :value="MissedReason.ExcusedForgetfulness">{{ localeStore.t('forgetfulness') }}</option>
                </optgroup>
                <optgroup :label="localeStore.t('unexcused_optgroup')">
                  <option :value="MissedReason.UnexcusedLaziness">{{ localeStore.t('laziness') }}</option>
                  <option :value="MissedReason.UnexcusedDistraction">{{ localeStore.t('distraction') }}</option>
                  <option :value="MissedReason.UnexcusedSituational">{{ localeStore.t('situational') }}</option>
                </optgroup>
              </select>
            </div>

            <label class="flex items-center gap-3 bg-slate-100 dark:bg-slate-800 p-3 rounded-2xl cursor-pointer border border-slate-200 dark:border-slate-700 hover:border-teal-500/50 transition-all select-none">
              <input type="checkbox" v-model="formIsTraveling" class="rounded text-teal-600 focus:ring-teal-500" />
              <span class="text-sm font-bold">{{ localeStore.t('traveling') }}</span>
            </label>
          </div>

          <!-- Period (Excused Impurity) -->
          <div v-else-if="logType === 'period'" class="p-6 bg-teal-500/5 border border-teal-500/10 rounded-2xl text-center space-y-2">
            <h4 class="font-bold text-sm text-teal-700 dark:text-teal-400">{{ localeStore.t('period_hayd') }}</h4>
            <p class="text-xs text-slate-500 leading-relaxed max-w-xs mx-auto">
              {{ localeStore.t('no_qaza_required') }}
            </p>
          </div>
        </div>

        <!-- Actions -->
        <div class="px-6 py-4 bg-slate-50 dark:bg-slate-800 border-t border-slate-200 dark:border-slate-700 flex items-center justify-end gap-3">
          <p v-if="feedback === 'log_failed'" role="alert">{{ localeStore.t(feedback) }}</p>
          <button @click="isModalOpen = false" class="iq-button iq-button-secondary">{{ localeStore.t('cancel') }}</button>
          <button @click="handleSaveLog" :disabled="store.loading" class="iq-button">{{ localeStore.t('save') }}</button>
        </div>
      </div>
    </AppDialog>

  </div>
</template>
