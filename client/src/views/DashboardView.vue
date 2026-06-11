<script setup lang="ts">
import { ref, watch } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import {
  PrayerName,
  WaqtStatus,
  MissedReason,
  PRAYER_LABELS,
  WAQT_LABELS,
  MISSED_REASON_LABELS,
} from '@/types/prayer.types'
import type {
  LogOfferedPrayerRequest,
  LogMissedPrayerRequest,
  PrayerLogDto,
} from '@/types/prayer.types'

const store = usePrayerStore()

// Mock current logged in user
const currentUserId = ref(1)

// Date selection: Default to today
const selectedDate = ref<string>(new Date().toISOString().split('T')[0] ?? '')

// Selected prayer logs for the selected date
const dailyLogs = ref<Record<number, PrayerLogDto>>({})

// Logging Modal state
const isModalOpen = ref(false)
const editingPrayerName = ref<PrayerName | null>(null)
const logType = ref<'offered' | 'missed'>('offered')

// Form inputs
const formWaqtStatus = ref<WaqtStatus>(WaqtStatus.AwwalAlWaqt)
const formMissedReason = ref<MissedReason>(MissedReason.UnexcusedLaziness)
const formIsJamaah = ref(false)
const formIsTraveling = ref(false)
const formIsJummah = ref(false)

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
    await store.fetchPrayerLogs(currentUserId.value, selectedDate.value, selectedDate.value)
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

// Watch selectedDate or currentUserId
watch(
  [selectedDate, currentUserId],
  () => {
    loadDailyLogs()
  },
  { immediate: true },
)

const openLoggingModal = (prayer: PrayerName) => {
  editingPrayerName.value = prayer
  const existing = dailyLogs.value[prayer]

  if (existing) {
    logType.value = existing.isOffered ? 'offered' : 'missed'
    formWaqtStatus.value = existing.waqtStatus ?? WaqtStatus.AwwalAlWaqt
    formMissedReason.value = existing.missedReason ?? MissedReason.UnexcusedLaziness
    formIsJamaah.value = existing.isJamaah
    formIsTraveling.value = existing.isTraveling
    formIsJummah.value = existing.isJummah
  } else {
    // Defaults
    logType.value = 'offered'
    formWaqtStatus.value = WaqtStatus.AwwalAlWaqt
    formMissedReason.value = MissedReason.UnexcusedLaziness
    formIsJamaah.value = false
    formIsTraveling.value = false
    formIsJummah.value = false
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
        waqtStatus: formWaqtStatus.value,
        isJamaah: formIsJamaah.value,
        isTraveling: formIsTraveling.value,
        isJummah: formIsJummah.value,
      }
    } else {
      payload = {
        prayerName: editingPrayerName.value,
        prayerDate: selectedDate.value,
        missedReason: formMissedReason.value,
        isTraveling: formIsTraveling.value,
      }
    }

    await store.logPrayer(currentUserId.value, payload)
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
      class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-slate-900/60 backdrop-blur-md border border-slate-800 p-6 rounded-2xl shadow-xl"
    >
      <div>
        <h1
          class="text-3xl font-extrabold bg-gradient-to-r from-emerald-400 to-teal-200 bg-clip-text text-transparent tracking-tight"
        >
          Establish Salah (إقامة)
        </h1>
        <p class="text-slate-400 text-sm mt-1">
          Track punctuality, log situational absences, and fulfill obligations.
        </p>
      </div>

      <div class="flex items-center gap-3">
        <span class="text-slate-400 text-xs font-semibold uppercase tracking-wider"
          >Demo User:</span
        >
        <select
          v-model="currentUserId"
          class="bg-slate-950 border border-slate-800 text-slate-200 rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:border-emerald-500 transition-colors"
        >
          <option :value="1">Brother Ahmed</option>
          <option :value="2">Sister Fatima</option>
        </select>
      </div>
    </div>

    <!-- Calendar Date Strip -->
    <div class="bg-slate-900/40 border border-slate-800/80 p-4 rounded-2xl shadow-lg">
      <div class="flex items-center justify-between mb-4">
        <span class="text-slate-200 font-bold text-sm tracking-wide">Select Date</span>
        <input
          type="date"
          v-model="selectedDate"
          class="bg-slate-950 border border-slate-800 text-slate-200 rounded-lg px-3 py-1 text-sm focus:outline-none focus:border-emerald-500"
        />
      </div>

      <!-- Quick date selectors -->
      <div class="grid grid-cols-7 gap-2">
        <button
          v-for="day in calendarDays"
          :key="day.dateStr"
          @click="selectedDate = day.dateStr"
          class="flex flex-col items-center py-2.5 rounded-xl border transition-all duration-300"
          :class="[
            selectedDate === day.dateStr
              ? 'bg-emerald-500/20 border-emerald-500 text-emerald-300 shadow-md shadow-emerald-950/40 font-bold'
              : 'border-slate-800 bg-slate-950/40 hover:bg-slate-800/50 hover:border-slate-700 text-slate-400',
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
      class="bg-rose-950/30 border border-rose-900/60 p-4 rounded-xl flex items-center justify-between"
    >
      <p class="text-rose-300 text-sm font-medium">{{ store.error }}</p>
      <button
        @click="store.clearError()"
        class="text-rose-400 hover:text-rose-200 text-xs font-semibold"
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
        class="group relative overflow-hidden bg-slate-950/60 border border-slate-800/80 hover:border-slate-700 rounded-2xl p-5 shadow-md transition-all duration-300 hover:shadow-lg hover:shadow-slate-950/50"
      >
        <!-- Glow decoration -->
        <div
          class="absolute inset-0 bg-gradient-to-r from-emerald-500/0 via-emerald-500/0 to-emerald-500/0 opacity-0 group-hover:opacity-10 transition-opacity duration-500"
        ></div>

        <div class="flex items-center justify-between relative z-10">
          <div class="flex items-center gap-4">
            <!-- Left Name / Arabic -->
            <div>
              <h3 class="text-lg font-bold text-slate-100 flex items-center gap-2">
                {{ PRAYER_LABELS[prayer].split(' ')[0] }}
                <span class="text-xs font-normal text-slate-500 font-arabic">{{
                  PRAYER_LABELS[prayer].split(' ')[1]
                }}</span>
              </h3>
              <!-- Logs info metadata -->
              <div class="flex items-center gap-2 mt-1">
                <span
                  v-if="dailyLogs[prayer]?.isTraveling"
                  class="text-[10px] bg-sky-950/40 text-sky-400 border border-sky-900/50 px-1.5 py-0.5 rounded font-medium uppercase tracking-wider"
                  >Musafir</span
                >
                <span
                  v-if="dailyLogs[prayer]?.isJamaah"
                  class="text-[10px] bg-emerald-950/40 text-emerald-400 border border-emerald-900/50 px-1.5 py-0.5 rounded font-medium uppercase tracking-wider"
                  >Jamaah</span
                >
                <span
                  v-if="dailyLogs[prayer]?.isJummah"
                  class="text-[10px] bg-teal-950/40 text-teal-400 border border-teal-900/50 px-1.5 py-0.5 rounded font-medium uppercase tracking-wider"
                  >Jumu'ah</span
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
                  class="text-xs text-emerald-400 font-bold bg-emerald-950/50 border border-emerald-900/50 px-3 py-1 rounded-full shadow-inner shadow-emerald-950"
                >
                  Offered ({{ WAQT_LABELS[dailyLogs[prayer].waqtStatus!] }})
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
                      ? 'text-purple-400 bg-purple-950/50 border-purple-900/50 shadow-purple-950'
                      : dailyLogs[prayer].missedReason === MissedReason.ExcusedSleep ||
                          dailyLogs[prayer].missedReason === MissedReason.ExcusedForgetfulness
                        ? 'text-indigo-400 bg-indigo-950/50 border-indigo-900/50 shadow-indigo-950'
                        : 'text-rose-400 bg-rose-950/50 border-rose-900/50 shadow-rose-950',
                  ]"
                >
                  Missed ({{
                    MISSED_REASON_LABELS[dailyLogs[prayer].missedReason!].split(' — ')[0]
                  }})
                </span>
                <span class="text-[10px] text-slate-500 mt-1">
                  {{
                    dailyLogs[prayer].missedReason === MissedReason.ExcusedImpurity
                      ? 'No Qaza required'
                      : 'Qaza Generated'
                  }}
                </span>
              </div>
            </template>

            <template v-else>
              <span
                class="text-xs font-semibold text-slate-500 italic bg-slate-900/40 border border-slate-900 px-3 py-1 rounded-full"
              >
                Not Logged
              </span>
            </template>
          </div>

          <!-- Right Action button -->
          <div class="flex items-center gap-2">
            <button
              @click="openLoggingModal(prayer)"
              :disabled="isFuturePrayer()"
              class="bg-slate-900 hover:bg-emerald-500 hover:text-slate-950 border border-slate-800 hover:border-emerald-400 text-slate-300 font-semibold text-sm px-4 py-2 rounded-xl transition-all duration-300 shadow-md disabled:opacity-40 disabled:hover:bg-slate-900 disabled:hover:text-slate-300 disabled:hover:border-slate-800 cursor-pointer disabled:cursor-not-allowed"
            >
              {{ dailyLogs[prayer] ? 'Edit' : 'Log' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Logging Modal (Glassmorphism backdrop) -->
    <div
      v-if="isModalOpen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm transition-all duration-300"
    >
      <div
        class="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-lg overflow-hidden shadow-2xl animate-in fade-in zoom-in-95 duration-200"
      >
        <!-- Modal Title -->
        <div
          class="bg-slate-950/60 px-6 py-4 border-b border-slate-800 flex items-center justify-between"
        >
          <h2 class="text-lg font-bold text-slate-100 flex items-center gap-2">
            Log {{ PRAYER_LABELS[editingPrayerName!].split(' ')[0] }}
            <span class="text-xs text-slate-500 font-normal">for {{ selectedDate }}</span>
          </h2>
          <button
            @click="isModalOpen = false"
            class="text-slate-400 hover:text-slate-200 text-xl font-bold p-1"
          >
            &times;
          </button>
        </div>

        <!-- Modal Body -->
        <div class="p-6 space-y-6">
          <!-- Switch: Offered vs Missed -->
          <div class="flex bg-slate-950 p-1.5 rounded-xl border border-slate-800">
            <button
              type="button"
              @click="logType = 'offered'"
              class="flex-1 text-center py-2 text-sm font-semibold rounded-lg transition-all"
              :class="[
                logType === 'offered'
                  ? 'bg-emerald-500 text-slate-950 shadow-md font-bold'
                  : 'text-slate-400 hover:text-slate-200',
              ]"
            >
              Offered (Ada')
            </button>
            <button
              type="button"
              @click="logType = 'missed'"
              class="flex-1 text-center py-2 text-sm font-semibold rounded-lg transition-all"
              :class="[
                logType === 'missed'
                  ? 'bg-emerald-500 text-slate-950 shadow-md font-bold'
                  : 'text-slate-400 hover:text-slate-200',
              ]"
            >
              Missed (Qaza)
            </button>
          </div>

          <!-- OFFERED FORM FIELDS -->
          <div
            v-if="logType === 'offered'"
            class="space-y-4 animate-in fade-in slide-in-from-top-2 duration-150"
          >
            <div>
              <label
                class="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2"
                >Punctuality (Waqt)</label
              >
              <select
                v-model="formWaqtStatus"
                class="w-full bg-slate-950 border border-slate-800 text-slate-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-emerald-500"
              >
                <option :value="WaqtStatus.AwwalAlWaqt">First 15-20 min (Awwal al-Waqt)</option>
                <option :value="WaqtStatus.WastAlWaqt">Middle window (Wast al-Waqt)</option>
                <option :value="WaqtStatus.AkhirAlWaqt">Late near expiry (Akhir al-Waqt)</option>
              </select>
            </div>

            <!-- Modifiers switches -->
            <div class="grid grid-cols-2 gap-3 pt-2">
              <label
                class="flex items-center gap-3 bg-slate-950/40 border border-slate-800/80 p-3 rounded-xl cursor-pointer hover:border-slate-700 transition-colors select-none"
              >
                <input
                  type="checkbox"
                  v-model="formIsJamaah"
                  class="rounded text-emerald-500 bg-slate-900 border-slate-800 focus:ring-emerald-500"
                />
                <span class="text-xs font-semibold text-slate-300">Jamaah (Congregation)</span>
              </label>

              <label
                class="flex items-center gap-3 bg-slate-950/40 border border-slate-800/80 p-3 rounded-xl cursor-pointer hover:border-slate-700 transition-colors select-none"
              >
                <input
                  type="checkbox"
                  v-model="formIsTraveling"
                  class="rounded text-emerald-500 bg-slate-900 border-slate-800 focus:ring-emerald-500"
                />
                <span class="text-xs font-semibold text-slate-300">Traveling (Musafir)</span>
              </label>

              <label
                v-if="editingPrayerName === PrayerName.Dhuhr"
                class="col-span-2 flex items-center gap-3 bg-slate-950/40 border border-slate-800/80 p-3 rounded-xl cursor-pointer hover:border-slate-700 transition-colors select-none"
              >
                <input
                  type="checkbox"
                  v-model="formIsJummah"
                  class="rounded text-emerald-500 bg-slate-900 border-slate-800 focus:ring-emerald-500"
                />
                <span class="text-xs font-semibold text-slate-300">Friday Jumu'ah Prayer</span>
              </label>
            </div>
          </div>

          <!-- MISSED FORM FIELDS -->
          <div v-else class="space-y-4 animate-in fade-in slide-in-from-top-2 duration-150">
            <div>
              <label
                class="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2"
                >Absence Reason</label
              >
              <select
                v-model="formMissedReason"
                class="w-full bg-slate-950 border border-slate-800 text-slate-200 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-emerald-500"
              >
                <optgroup label="Excused (No Sin)">
                  <option :value="MissedReason.ExcusedImpurity">
                    Menstruation/Impurity (Hayd) — NO Qaza
                  </option>
                  <option :value="MissedReason.ExcusedSleep">Unintentional Sleep (Nawm)</option>
                  <option :value="MissedReason.ExcusedForgetfulness">
                    Genuine Forgetfulness (Nisyan)
                  </option>
                </optgroup>
                <optgroup label="Unexcused">
                  <option :value="MissedReason.UnexcusedLaziness">
                    Laziness / Procrastination (Kasl)
                  </option>
                  <option :value="MissedReason.UnexcusedDistraction">
                    Distraction / Entertainment (Ghaflah)
                  </option>
                  <option :value="MissedReason.UnexcusedSituational">
                    Busy / Work / Worldly Preoccupations (Shughl)
                  </option>
                </optgroup>
              </select>
            </div>

            <div class="pt-2">
              <label
                class="flex items-center gap-3 bg-slate-950/40 border border-slate-800/80 p-3 rounded-xl cursor-pointer hover:border-slate-700 transition-colors select-none"
              >
                <input
                  type="checkbox"
                  v-model="formIsTraveling"
                  class="rounded text-emerald-500 bg-slate-900 border-slate-800 focus:ring-emerald-500"
                />
                <span class="text-xs font-semibold text-slate-300">Traveling (Musafir)</span>
              </label>
            </div>
          </div>
        </div>

        <!-- Modal Actions -->
        <div
          class="bg-slate-950/60 px-6 py-4 border-t border-slate-800 flex items-center justify-end gap-3"
        >
          <button
            type="button"
            @click="isModalOpen = false"
            class="text-xs font-bold text-slate-400 hover:text-slate-200 px-4 py-2 rounded-xl border border-slate-800 hover:bg-slate-850 cursor-pointer"
          >
            Cancel
          </button>
          <button
            type="button"
            @click="handleSaveLog"
            :disabled="store.loading"
            class="bg-emerald-500 hover:bg-emerald-400 disabled:opacity-50 text-slate-950 font-bold text-xs px-5 py-2.5 rounded-xl shadow-md cursor-pointer disabled:cursor-not-allowed"
          >
            Save Log
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
