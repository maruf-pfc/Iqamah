<script setup lang="ts">
import { ref, watch } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useLocaleStore } from '@/stores/locale'
import {
  PrayerName,
  WaqtStatus,
  MissedReason,
} from '@/types/prayer.types'
import type {
  LogOfferedPrayerRequest,
  LogMissedPrayerRequest,
  PrayerLogDto,
} from '@/types/prayer.types'

const store = usePrayerStore()
const localeStore = useLocaleStore()

const ARABIC_NAMES = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء']

const getLocalizedPrayerName = (prayer: number) => {
  const keys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']
  const key = keys[prayer] || 'fajr'
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return localeStore.t(key as any)
}

const getLocalizedWaqt = (status: number) => {
  const keys = ['awwal', 'wast', 'akhir']
  const key = keys[status] || 'awwal'
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return localeStore.t(key as any)
}

const getLocalizedMissedReason = (reason: number) => {
  const keys = ['impurity', 'sleep', 'forgetfulness', 'situational', 'laziness', 'distraction']
  const key = keys[reason] || 'laziness'
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return localeStore.t(key as any)
}

// Date selection: Default to today
const selectedDate = ref<string>(new Date().toISOString().split('T')[0] ?? '')

// Selected prayer logs for the selected date
const dailyLogs = ref<Record<number, PrayerLogDto>>({})

// Logging Modal state
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

// Generate list of past 7 days for the calendar bar
const getPastDays = () => {
  const days = []
  for (let i = 6; i >= 0; i--) {
    const d = new Date()
    d.setDate(d.getDate() - i)
    days.push({
      dateStr: d.toISOString().split('T')[0] ?? '',
      dayName: d.toLocaleDateString('en-US', { weekday: 'short' }),
      dayNum: d.getDate(),
    })
  }
  return days
}
const calendarDays = getPastDays()

const loadDailyLogs = async () => {
  try {
    await store.fetchPrayerLogs(selectedDate.value, selectedDate.value)
    // Map to dictionary
    const mapped: Record<number, PrayerLogDto> = {}
    store.prayerLogs.forEach((log) => {
      mapped[log.prayerName] = log
    })
    dailyLogs.value = mapped
  } catch (err) {
    console.error('Failed to load logs', err)
  }
}

// Watch selectedDate
watch(
  selectedDate,
  () => {
    loadDailyLogs()
  },
  { immediate: true },
)

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
    // Defaults
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
    isModalOpen.value = false
  } catch (err) {
    console.error('Error logging prayer:', err)
  }
}

// Helper to check if a prayer is in the future (disabled logging)
const isFuturePrayer = () => {
  const todayStr = new Date().toISOString().split('T')[0] ?? ''
  if (selectedDate.value < todayStr) return false
  if (selectedDate.value > todayStr) return true
  return false // Allow logging all prayers for today for convenience
}
</script>

<template>
  <div class="space-y-8 max-w-4xl mx-auto px-4 py-6">
    <!-- Header with user switcher -->
    <div
      class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 islamic-card p-6 rounded-2xl shadow-xl islamic-border-top"
    >
      <div>
        <h1
          class="text-3xl font-serif font-bold bg-gradient-to-r from-gold-100 via-gold-300 to-gold-500 bg-clip-text text-transparent tracking-wide"
        >
          {{ localeStore.t('establish_salah') }}
        </h1>
        <p class="text-gold-200/60 text-sm mt-1">
          {{ localeStore.t('salah_tagline') }}
        </p>
      </div>
    </div>

    <!-- Calendar Date Strip -->
    <div class="islamic-card p-4 rounded-2xl shadow-lg border-t border-gold-500/10">
      <div class="flex items-center justify-between mb-4">
        <span class="text-gold-200 font-serif font-semibold text-sm tracking-wide">{{ localeStore.t('select_date') }}</span>
        <input
          type="date"
          v-model="selectedDate"
          class="bg-islamic-deep border border-gold-500/20 text-gold-200 rounded-lg px-3 py-1 text-sm focus:outline-none focus:border-gold-500"
        />
      </div>

      <!-- Quick date selectors -->
      <div class="grid grid-cols-7 gap-2">
        <button
          v-for="day in calendarDays"
          :key="day.dateStr"
          @click="selectedDate = day.dateStr"
          class="flex flex-col items-center py-2.5 rounded-xl border transition-all duration-300 cursor-pointer"
          :class="[
            selectedDate === day.dateStr
              ? 'bg-gold-500/10 border-gold-500 text-gold-300 shadow-[0_0_15px_rgba(212,175,55,0.08)] font-bold'
              : 'border-gold-500/5 bg-islamic-deep/40 hover:bg-gold-500/10 hover:border-gold-500/30 text-slate-400',
          ]"
        >
          <span class="text-[10px] uppercase tracking-wider opacity-80 mb-1">{{
            day.dayName
          }}</span>
          <span class="text-lg font-semibold">{{ day.dayNum }}</span>
        </button>
      </div>
    </div>

    <!-- Error indicator -->
    <div
      v-if="store.error"
      class="bg-rose-950/20 border border-rose-500/20 p-4 rounded-xl flex items-center justify-between"
    >
      <p class="text-rose-300 text-sm font-medium">{{ store.error }}</p>
      <button
        @click="store.clearError()"
        class="text-rose-400 hover:text-rose-200 text-xs font-semibold cursor-pointer"
      >
        Dismiss
      </button>
    </div>

    <!-- Prayer Cards Grid -->
    <div class="space-y-4">
      <div
        v-for="prayer in [
          PrayerName.Fajr,
          PrayerName.Dhuhr,
          PrayerName.Asr,
          PrayerName.Maghrib,
          PrayerName.Isha,
        ]"
        :key="prayer"
        class="group relative overflow-hidden islamic-card islamic-card-hover rounded-2xl p-5 shadow-md transition-all duration-300"
      >
        <!-- Glow decoration -->
        <div
          class="absolute inset-0 bg-gradient-to-r from-gold-500/0 via-gold-500/0 to-gold-500/0 opacity-0 group-hover:opacity-10 transition-opacity duration-500"
        ></div>

        <div class="flex items-center justify-between relative z-10">
          <div class="flex items-center gap-4">
            <!-- Left Name / Arabic -->
            <div>
              <h3 class="text-lg font-serif font-bold text-slate-100 flex items-center gap-2">
                {{ getLocalizedPrayerName(prayer) }}
                <span class="text-sm font-normal text-gold-400 font-arabic">{{
                  ARABIC_NAMES[prayer]
                }}</span>
              </h3>
              <!-- Logs info metadata -->
              <div class="flex items-center gap-2 mt-1">
                <span
                  v-if="dailyLogs[prayer]?.isTraveling"
                  class="text-[10px] bg-sky-950/30 text-sky-400 border border-sky-900/30 px-1.5 py-0.5 rounded font-medium uppercase tracking-wider"
                  >{{ localeStore.t('traveling') }}</span
                >
                <span
                  v-if="dailyLogs[prayer]?.isJamaah"
                  class="text-[10px] bg-emerald-950/30 text-emerald-400 border border-emerald-900/30 px-1.5 py-0.5 rounded font-medium uppercase tracking-wider"
                  >{{ localeStore.t('jamaah') }}</span
                >
                <span
                  v-if="dailyLogs[prayer]?.isJummah"
                  class="text-[10px] bg-teal-950/30 text-teal-400 border border-teal-900/30 px-1.5 py-0.5 rounded font-medium uppercase tracking-wider"
                  >{{ localeStore.t('friday_prayer') }}</span
                >
                <span
                  v-if="dailyLogs[prayer]?.isHome"
                  class="text-[10px] bg-amber-950/30 text-amber-400 border border-amber-900/30 px-1.5 py-0.5 rounded font-medium uppercase tracking-wider"
                  >{{ localeStore.t('prayed_at_home') }}</span
                >
                <span
                  v-if="dailyLogs[prayer]?.hasTasbih"
                  class="text-[10px] bg-pink-950/30 text-pink-400 border border-pink-900/30 px-1.5 py-0.5 rounded font-medium uppercase tracking-wider"
                  >📿 Tasbih</span
                >
                <span
                  v-if="dailyLogs[prayer]?.quranNotes"
                  class="text-[10px] bg-purple-950/30 text-purple-400 border border-purple-900/30 px-1.5 py-0.5 rounded font-medium uppercase tracking-wider"
                  :title="dailyLogs[prayer]?.quranNotes"
                  >📖 Quran</span
                >
              </div>
            </div>
          </div>

          <!-- Middle Status Representation -->
          <div class="flex items-center gap-3">
            <template v-if="dailyLogs[prayer]">
              <!-- Offered on time -->
              <div v-if="dailyLogs[prayer].isOffered" class="flex flex-col items-end">
                <span
                  class="text-xs text-emerald-400 font-bold bg-emerald-950/30 border border-emerald-900/40 px-3 py-1 rounded-full shadow-[0_0_10px_rgba(16,185,129,0.05)]"
                >
                  {{ localeStore.t('offered') }} ({{ getLocalizedWaqt(dailyLogs[prayer].waqtStatus!) }})
                </span>
                <span class="text-[10px] text-slate-500 mt-1"
                  >Ada' • logged
                  {{
                    new Date(dailyLogs[prayer].loggedAt).toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit',
                    })
                  }}</span
                >
              </div>

              <!-- Missed / Excused -->
              <div v-else class="flex flex-col items-end">
                <span
                  class="text-xs px-3 py-1 rounded-full border font-bold shadow-inner"
                  :class="[
                    dailyLogs[prayer].missedReason === MissedReason.ExcusedImpurity
                      ? 'text-purple-400 bg-purple-950/30 border-purple-900/40'
                      : dailyLogs[prayer].missedReason === MissedReason.ExcusedSleep ||
                          dailyLogs[prayer].missedReason === MissedReason.ExcusedForgetfulness
                        ? 'text-indigo-400 bg-indigo-950/30 border-indigo-900/40'
                        : 'text-rose-400 bg-rose-950/30 border-rose-900/40',
                  ]"
                >
                  {{ localeStore.t('missed') }} ({{
                    getLocalizedMissedReason(dailyLogs[prayer].missedReason!)
                  }})
                </span>
                <span class="text-[10px] text-slate-500 mt-1">
                  {{
                    dailyLogs[prayer].missedReason === MissedReason.ExcusedImpurity
                      ? localeStore.t('no_qaza_required')
                      : localeStore.t('qaza_generated')
                  }}
                </span>
              </div>
            </template>

            <template v-else>
              <span
                class="text-xs font-semibold text-gold-300/40 italic bg-gold-950/5 border border-gold-500/5 px-3 py-1 rounded-full"
              >
                {{ localeStore.t('not_logged') }}
              </span>
            </template>
          </div>

          <!-- Right Action button -->
          <div class="flex items-center gap-2">
            <button
              @click="openLoggingModal(prayer)"
              :disabled="isFuturePrayer()"
              class="bg-islamic-hover hover:bg-gold-500 hover:text-islamic-deep border border-gold-500/20 hover:border-gold-400 text-gold-300 font-bold text-sm px-4 py-2 rounded-xl transition-all duration-300 shadow-md disabled:opacity-40 disabled:hover:bg-islamic-hover disabled:hover:text-gold-300 disabled:hover:border-gold-500/20 cursor-pointer disabled:cursor-not-allowed"
            >
              {{ dailyLogs[prayer] ? localeStore.t('edit') : localeStore.t('log') }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Logging Modal (Glassmorphism backdrop) -->
    <div
      v-if="isModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-islamic-deep/80 backdrop-blur-sm transition-all duration-300"
    >
      <div
        class="islamic-card rounded-3xl w-full max-w-lg overflow-hidden shadow-2xl animate-in fade-in zoom-in-95 duration-200 islamic-border-top"
      >
        <!-- Modal Title -->
        <div
          class="bg-islamic-deep/60 px-6 py-4 border-b border-gold-500/10 flex items-center justify-between"
        >
          <h2 class="text-lg font-serif font-bold text-slate-100 flex items-center gap-2">
            {{ localeStore.t('log_salah', { salah: getLocalizedPrayerName(editingPrayerName!) }) }}
            <span class="text-xs text-gold-200/50 font-normal">for {{ selectedDate }}</span>
          </h2>
          <button
            @click="isModalOpen = false"
            class="text-gold-400 hover:text-gold-200 text-xl font-bold p-1 cursor-pointer"
          >
            &times;
          </button>
        </div>

        <!-- Modal Body -->
        <div class="p-6 space-y-6">
          <!-- Switch: Offered vs Missed vs Period -->
          <div class="flex bg-islamic-deep p-1.5 rounded-xl border border-gold-500/15">
            <button
              type="button"
              @click="logType = 'offered'"
              class="flex-1 text-center py-2 text-xs font-bold rounded-lg transition-all cursor-pointer"
              :class="[
                logType === 'offered'
                  ? 'bg-gradient-to-r from-gold-500 to-gold-600 text-islamic-deep shadow-md'
                  : 'text-gold-300/60 hover:text-gold-200',
              ]"
            >
              {{ localeStore.t('offered') }}
            </button>
            <button
              type="button"
              @click="logType = 'missed'"
              class="flex-1 text-center py-2 text-xs font-bold rounded-lg transition-all cursor-pointer"
              :class="[
                logType === 'missed'
                  ? 'bg-gradient-to-r from-gold-500 to-gold-600 text-islamic-deep shadow-md'
                  : 'text-gold-300/60 hover:text-gold-200',
              ]"
            >
              {{ localeStore.t('missed') }}
            </button>
            <button
              type="button"
              @click="logType = 'period'"
              class="flex-1 text-center py-2 text-xs font-bold rounded-lg transition-all cursor-pointer"
              :class="[
                logType === 'period'
                  ? 'bg-gradient-to-r from-gold-500 to-gold-600 text-islamic-deep shadow-md'
                  : 'text-gold-300/60 hover:text-gold-200',
              ]"
            >
              {{ localeStore.t('period_hayd').split(' ')[0] }}
            </button>
          </div>

          <!-- OFFERED FORM FIELDS -->
          <div
            v-if="logType === 'offered'"
            class="space-y-4 animate-in fade-in slide-in-from-top-2 duration-150"
          >
            <div>
              <label
                class="block text-xs font-bold text-gold-200/80 uppercase tracking-wider mb-2"
                >{{ localeStore.t('waqt_punctuality') }}</label
              >
              <select
                v-model="formWaqtStatus"
                class="w-full bg-islamic-deep border border-gold-500/20 text-slate-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-gold-500"
              >
                <option :value="WaqtStatus.AwwalAlWaqt">{{ localeStore.t('awwal_waqt_title') }}</option>
                <option :value="WaqtStatus.WastAlWaqt">{{ localeStore.t('wast_waqt_title') }}</option>
                <option :value="WaqtStatus.AkhirAlWaqt">{{ localeStore.t('akhir_waqt_title') }}</option>
              </select>
            </div>

            <!-- Modifiers switches -->
            <div class="grid grid-cols-2 gap-3 pt-2">
              <label
                class="flex items-center gap-3 bg-islamic-deep/60 border border-gold-500/10 p-3 rounded-xl cursor-pointer hover:border-gold-500/20 transition-colors select-none"
              >
                <input
                  type="checkbox"
                  v-model="formIsJamaah"
                  class="rounded text-gold-500 bg-islamic-deep border-gold-500/20 focus:ring-gold-500"
                />
                <span class="text-xs font-semibold text-slate-300">{{ localeStore.t('congregation') }}</span>
              </label>

              <label
                class="flex items-center gap-3 bg-islamic-deep/60 border border-gold-500/10 p-3 rounded-xl cursor-pointer hover:border-gold-500/20 transition-colors select-none"
              >
                <input
                  type="checkbox"
                  v-model="formIsTraveling"
                  class="rounded text-gold-500 bg-islamic-deep border-gold-500/20 focus:ring-gold-500"
                />
                <span class="text-xs font-semibold text-slate-300">{{ localeStore.t('traveling') }}</span>
              </label>

              <label
                :class="editingPrayerName === PrayerName.Dhuhr ? 'col-span-1' : 'col-span-2'"
                class="flex items-center gap-3 bg-islamic-deep/60 border border-gold-500/10 p-3 rounded-xl cursor-pointer hover:border-gold-500/20 transition-colors select-none"
              >
                <input
                  type="checkbox"
                  v-model="formIsHome"
                  class="rounded text-gold-500 bg-islamic-deep border-gold-500/20 focus:ring-gold-500"
                />
                <span class="text-xs font-semibold text-slate-300">{{ localeStore.t('prayed_at_home') }}</span>
              </label>

              <label
                v-if="editingPrayerName === PrayerName.Dhuhr"
                class="col-span-1 flex items-center gap-3 bg-islamic-deep/60 border border-gold-500/10 p-3 rounded-xl cursor-pointer hover:border-gold-500/20 transition-colors select-none"
              >
                <input
                  type="checkbox"
                  v-model="formIsJummah"
                  class="rounded text-gold-500 bg-islamic-deep border-gold-500/20 focus:ring-gold-500"
                />
                <span class="text-xs font-semibold text-slate-300">{{ localeStore.t('friday_prayer') }}</span>
              </label>
            </div>

            <!-- Quran notes & Tasbih tracking -->
            <div class="space-y-4 pt-4 border-t border-gold-500/10">
              <div class="grid grid-cols-1 gap-3">
                <label
                  class="flex items-center gap-3 bg-islamic-deep/60 border border-gold-500/10 p-3 rounded-xl cursor-pointer hover:border-gold-500/20 transition-colors select-none"
                >
                  <input
                    type="checkbox"
                    v-model="formHasTasbih"
                    class="rounded text-gold-500 bg-islamic-deep border-gold-500/20 focus:ring-gold-500"
                  />
                  <span class="text-xs font-semibold text-slate-300">{{ localeStore.t('track_tasbih') }}</span>
                </label>
              </div>

              <div>
                <label
                  class="block text-xs font-bold text-gold-200/80 uppercase tracking-wider mb-2"
                  >{{ localeStore.t('quran_notes') }}</label
                >
                <input
                  type="text"
                  v-model="formQuranNotes"
                  :placeholder="localeStore.t('quran_notes_placeholder')"
                  class="w-full bg-islamic-deep border border-gold-500/20 text-slate-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-gold-500"
                />
              </div>
            </div>
          </div>

          <!-- MISSED FORM FIELDS -->
          <div v-else-if="logType === 'missed'" class="space-y-4 animate-in fade-in slide-in-from-top-2 duration-150">
            <div>
              <label
                class="block text-xs font-bold text-gold-200/80 uppercase tracking-wider mb-2"
                >{{ localeStore.t('reason_missed') }}</label
              >
              <select
                v-model="formMissedReason"
                class="w-full bg-islamic-deep border border-gold-500/20 text-slate-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-gold-500"
              >
                <optgroup :label="localeStore.t('excused_optgroup')">
                  <option :value="MissedReason.ExcusedImpurity">
                    {{ localeStore.t('impurity') }}
                  </option>
                  <option :value="MissedReason.ExcusedSleep">{{ localeStore.t('sleep') }}</option>
                  <option :value="MissedReason.ExcusedForgetfulness">
                    {{ localeStore.t('forgetfulness') }}
                  </option>
                </optgroup>
                <optgroup :label="localeStore.t('unexcused_optgroup')">
                  <option :value="MissedReason.UnexcusedLaziness">
                    {{ localeStore.t('laziness') }}
                  </option>
                  <option :value="MissedReason.UnexcusedDistraction">
                    {{ localeStore.t('distraction') }}
                  </option>
                  <option :value="MissedReason.UnexcusedSituational">
                    {{ localeStore.t('situational') }}
                  </option>
                </optgroup>
              </select>
            </div>

            <div class="pt-2">
              <label
                class="flex items-center gap-3 bg-islamic-deep/60 border border-gold-500/10 p-3 rounded-xl cursor-pointer hover:border-gold-500/20 transition-colors select-none"
              >
                <input
                  type="checkbox"
                  v-model="formIsTraveling"
                  class="rounded text-gold-500 bg-islamic-deep border-gold-500/20 focus:ring-gold-500"
                />
                <span class="text-xs font-semibold text-slate-300">{{ localeStore.t('traveling') }}</span>
              </label>
            </div>
          </div>

          <!-- PERIOD / IMPURITY FORM FIELDS -->
          <div v-else-if="logType === 'period'" class="p-6 bg-gold-500/5 border border-gold-500/10 rounded-2xl space-y-3 text-center animate-in fade-in slide-in-from-top-2 duration-150">
            <div class="text-3xl">🌸</div>
            <h4 class="text-sm font-bold text-gold-300">
              {{ localeStore.t('period_hayd') }}
            </h4>
            <p class="text-xs text-slate-400 leading-relaxed max-w-xs mx-auto">
              During menstruation or post-natal bleeding (Hayd/Nifas), a woman is legally excused from performing prayers, and no make-up (Qaza) prayers are required.
            </p>
            <div class="text-xs text-gold-400/80 font-bold bg-gold-500/10 inline-block px-3 py-1 rounded-full border border-gold-500/20">
              {{ localeStore.t('no_qaza_required') }}
            </div>
          </div>
        </div>

        <!-- Modal Actions -->
        <div
          class="bg-islamic-deep/60 px-6 py-4 border-t border-gold-500/10 flex items-center justify-end gap-3"
        >
          <button
            type="button"
            @click="isModalOpen = false"
            class="text-xs font-bold text-gold-400 hover:text-gold-200 px-4 py-2 rounded-xl border border-gold-500/20 hover:bg-gold-500/10 cursor-pointer"
          >
            {{ localeStore.t('cancel') }}
          </button>
          <button
            type="button"
            @click="handleSaveLog"
            :disabled="store.loading"
            class="bg-gradient-to-r from-gold-500 to-gold-600 hover:from-gold-400 hover:to-gold-500 text-islamic-deep font-black text-xs px-5 py-2.5 rounded-xl shadow-md cursor-pointer disabled:cursor-not-allowed"
          >
            {{ localeStore.t('save') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.font-arabic {
  font-family: 'Amiri', 'Traditional Arabic', serif;
}
</style>
