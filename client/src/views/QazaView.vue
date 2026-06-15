<script setup lang="ts">
import { computed } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useLocaleStore } from '@/stores/locale'
import { PrayerName } from '@/types/prayer.types'

const store = usePrayerStore()
const localeStore = useLocaleStore()

const ARABIC_NAMES = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء']

const getLocalizedPrayerName = (prayer: number) => {
  const keys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']
  const key = keys[prayer] || 'fajr'
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return localeStore.t(key as any)
}

const loadQazas = async () => {
  try {
    await store.fetchPendingQazas()
  } catch (err) {
    console.error('Failed to load pending Qazas', err)
  }
}

loadQazas()

const handleFulfillQaza = async (qazaLogId: string) => {
  try {
    await store.fulfillQaza(qazaLogId)
    // Reload Qazas
    await loadQazas()
  } catch (err) {
    console.error('Error fulfilling Qaza:', err)
  }
}

const getRelativeTime = (dateStr: string) => {
  const date = new Date(dateStr)
  // Strip time for clean day diff
  const d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate())
  const today = new Date()
  const d2 = new Date(today.getFullYear(), today.getMonth(), today.getDate())
  const diffTime = d2.getTime() - d1.getTime()
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))
  if (diffDays <= 0) return localeStore.t('today')
  if (diffDays === 1) return localeStore.t('yesterday')
  return localeStore.t('days_ago', { count: diffDays })
}

// Group pending Qaza logs by prayer name for summary
const qazaSummary = computed<Record<number, number>>(() => {
  const counts: Record<number, number> = {
    [PrayerName.Fajr]: 0,
    [PrayerName.Dhuhr]: 0,
    [PrayerName.Asr]: 0,
    [PrayerName.Maghrib]: 0,
    [PrayerName.Isha]: 0,
  }
  store.pendingQazas.forEach((q) => {
    const key = q.prayerName
    const val = counts[key] ?? 0
    counts[key] = val + 1
  })
  return counts
})
</script>

<template>
  <div class="space-y-8 max-w-4xl mx-auto px-4 py-6">
    <!-- Header -->
    <div
      class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-slate-900/60 backdrop-blur-md border border-slate-800 p-6 rounded-2xl shadow-xl"
    >
      <div>
        <h1
          class="text-3xl font-extrabold bg-gradient-to-r from-teal-400 to-indigo-400 bg-clip-text text-transparent tracking-tight"
        >
          {{ localeStore.t('qaza_ledger') }}
        </h1>
        <p class="text-slate-400 text-sm mt-1">
          {{ localeStore.t('qaza_tagline') }}
        </p>
      </div>
    </div>

    <!-- Summary Statistics -->
    <div class="grid grid-cols-2 sm:grid-cols-5 gap-4">
      <div
        v-for="pName in [
          PrayerName.Fajr,
          PrayerName.Dhuhr,
          PrayerName.Asr,
          PrayerName.Maghrib,
          PrayerName.Isha,
        ]"
        :key="pName"
        class="bg-slate-950/40 border border-slate-800/80 rounded-2xl p-4 text-center"
      >
        <span class="text-xs text-slate-400 block font-semibold">{{
          getLocalizedPrayerName(pName)
        }}</span>
        <span
          class="text-3xl font-extrabold block mt-2"
          :class="[(qazaSummary[pName] ?? 0) > 0 ? 'text-indigo-400' : 'text-slate-600']"
        >
          {{ qazaSummary[pName] ?? 0 }}
        </span>
        <span class="text-[10px] text-slate-500 mt-1 uppercase tracking-wider block font-bold"
          >{{ localeStore.t('pending') }}</span
        >
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

    <!-- Pending Qazas List -->
    <div class="bg-slate-900/40 border border-slate-800/80 rounded-2xl p-6 shadow-lg">
      <div class="flex items-center justify-between mb-6">
        <h2 class="text-lg font-bold text-slate-100">{{ localeStore.t('outstanding_debt') }}</h2>
        <span
          class="text-xs font-bold bg-indigo-950/50 text-indigo-400 border border-indigo-900/50 px-3 py-1 rounded-full"
        >
          {{ localeStore.t('prayers_due', { count: store.pendingQazas.length }) }}
        </span>
      </div>

      <div
        v-if="store.loading && store.pendingQazas.length === 0"
        class="flex flex-col items-center py-12"
      >
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-500 mb-2"></div>
        <p class="text-slate-400 text-sm">Loading Qaza obligations...</p>
      </div>

      <div v-else-if="store.pendingQazas.length === 0" class="text-center py-16 space-y-4">
        <div
          class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-emerald-950/40 text-emerald-400 border border-emerald-900/40"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-8 w-8"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M5 13l4 4L19 7"
            />
          </svg>
        </div>
        <div>
          <h3 class="text-slate-200 font-bold text-lg">{{ localeStore.t('no_pending') }}</h3>
          <p class="text-slate-500 text-sm mt-1">
            {{ localeStore.t('no_pending_desc') }}
          </p>
        </div>
      </div>

      <div v-else class="divide-y divide-slate-800/60 max-h-[500px] overflow-y-auto pr-2">
        <div
          v-for="qaza in store.pendingQazas"
          :key="qaza.id"
          class="flex items-center justify-between py-4 first:pt-0 last:pb-0 group transition-all duration-300"
        >
          <div>
            <span class="font-bold text-slate-200 flex items-center gap-2">
              {{ getLocalizedPrayerName(qaza.prayerName) }}
              <span class="text-xs font-normal text-slate-500 font-arabic">{{
                ARABIC_NAMES[qaza.prayerName]
              }}</span>
            </span>
            <div class="flex items-center gap-2 mt-1">
              <span class="text-xs text-slate-400">{{ qaza.originalPrayerDate }}</span>
              <span class="text-[10px] text-slate-500">•</span>
              <span class="text-xs text-indigo-400 font-semibold">{{
                getRelativeTime(qaza.originalPrayerDate)
              }}</span>
            </div>
          </div>

          <button
            @click="handleFulfillQaza(qaza.id)"
            class="bg-indigo-950/40 hover:bg-emerald-500 border border-indigo-900/50 hover:border-emerald-400 text-indigo-300 hover:text-slate-950 font-bold text-xs px-4 py-2.5 rounded-xl transition-all duration-300 shadow-md cursor-pointer"
          >
            {{ localeStore.t('fulfill') }}
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
