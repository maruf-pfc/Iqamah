<script setup lang="ts">
import { ref, watch } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useLocaleStore } from '@/stores/locale'

const store = usePrayerStore()
const localeStore = useLocaleStore()

const getLocalizedPrayerNameStr = (pName: string) => {
  return localeStore.t(pName as any)
}

// Date Range selection
const activeRange = ref<'7d' | '30d' | '365d' | 'custom'>('30d')
const fromDate = ref('')
const toDate = ref('')

const setRange = (range: '7d' | '30d' | '365d') => {
  activeRange.value = range
  const today = new Date()
  const from = new Date()

  if (range === '7d') {
    from.setDate(today.getDate() - 6)
  } else if (range === '30d') {
    from.setDate(today.getDate() - 29)
  } else if (range === '365d') {
    from.setDate(today.getDate() - 364)
  }

  fromDate.value = from.toISOString().split('T')[0] ?? ''
  toDate.value = today.toISOString().split('T')[0] ?? ''
}

// Initial range
setRange('30d')

const loadAnalytics = async () => {
  try {
    await store.fetchAnalytics(fromDate.value, toDate.value)
  } catch (err) {
    console.error('Failed to load analytics', err)
  }
}

watch(
  [fromDate, toDate],
  () => {
    loadAnalytics()
  },
  { immediate: true },
)

// Circular progress offset calculation for HSL dials
const strokeDashOffset = (percentage: number, radius = 50) => {
  const circumference = 2 * Math.PI * radius
  return circumference - (percentage / 100) * circumference
}
</script>

<template>
  <div class="space-y-8 max-w-4xl mx-auto px-4 py-6">
    <!-- Header -->
    <div
      class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-slate-900/60 backdrop-blur-md border border-slate-800 p-6 rounded-2xl shadow-xl"
    >
      <div>
        <h1
          class="text-3xl font-extrabold bg-gradient-to-r from-emerald-400 to-indigo-400 bg-clip-text text-transparent tracking-tight"
        >
          {{ localeStore.t('salah_analytics') }}
        </h1>
        <p class="text-slate-400 text-sm mt-1">
          {{ localeStore.t('analytics_tagline') }}
        </p>
      </div>
    </div>

    <!-- Range Selector Toolbar -->
    <div
      class="flex flex-wrap items-center justify-between gap-4 bg-slate-950/60 border border-slate-800/80 p-4 rounded-2xl"
    >
      <div class="flex bg-slate-900 p-1 rounded-xl border border-slate-800">
        <button
          v-for="r in ['7d', '30d', '365d'] as const"
          :key="r"
          @click="setRange(r)"
          class="px-4 py-1.5 text-xs font-bold rounded-lg transition-all"
          :class="[
            activeRange === r
              ? 'bg-emerald-500 text-slate-950 shadow'
              : 'text-slate-400 hover:text-slate-200',
          ]"
        >
          {{ r === '7d' ? localeStore.t('days_7') : r === '30d' ? localeStore.t('days_30') : localeStore.t('year_1') }}
        </button>
        <button
          @click="activeRange = 'custom'"
          class="px-4 py-1.5 text-xs font-bold rounded-lg transition-all"
          :class="[
            activeRange === 'custom'
              ? 'bg-emerald-500 text-slate-950 shadow'
              : 'text-slate-400 hover:text-slate-200',
          ]"
        >
          {{ localeStore.t('custom') }}
        </button>
      </div>

      <!-- Custom Date Pickers -->
      <div
        v-if="activeRange === 'custom'"
        class="flex items-center gap-2 animate-in fade-in duration-200"
      >
        <input
          type="date"
          v-model="fromDate"
          class="bg-slate-900 border border-slate-800 text-slate-200 rounded-lg px-3 py-1 text-xs focus:outline-none focus:border-emerald-500"
        />
        <span class="text-slate-600 text-xs">{{ localeStore.t('to') }}</span>
        <input
          type="date"
          v-model="toDate"
          class="bg-slate-900 border border-slate-800 text-slate-200 rounded-lg px-3 py-1 text-xs focus:outline-none focus:border-emerald-500"
        />
      </div>
    </div>

    <div v-if="store.loading" class="flex flex-col items-center py-24">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-500 mb-4"></div>
      <p class="text-slate-400 text-sm">{{ localeStore.t('processing_analytics') }}</p>
    </div>

    <div v-else-if="!store.analytics" class="text-center py-16">
      <p class="text-slate-500">{{ localeStore.t('no_analytics_data') }}</p>
    </div>

    <!-- Analytics Dashboard Content -->
    <div v-else class="space-y-6">
      <!-- Upper Section: Key Metrics Overview -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <!-- Offered Ratio Dial -->
        <div
          class="bg-slate-900/40 border border-slate-800 p-6 rounded-2xl flex flex-col items-center justify-center text-center relative overflow-hidden"
        >
          <svg class="w-32 h-32 transform -rotate-90">
            <!-- Background circle -->
            <circle cx="64" cy="64" r="50" fill="transparent" stroke="#1e293b" stroke-width="10" />
            <!-- Foreground dial -->
            <circle
              cx="64"
              cy="64"
              r="50"
              fill="transparent"
              stroke="#10b981"
              stroke-width="10"
              stroke-linecap="round"
              :stroke-dasharray="2 * Math.PI * 50"
              :stroke-dashoffset="strokeDashOffset(store.analytics.offeredPercentage)"
              class="transition-all duration-1000 ease-out"
            />
          </svg>
          <div class="absolute flex flex-col items-center justify-center">
            <span class="text-2xl font-black text-slate-100"
              >{{ store.analytics.offeredPercentage }}%</span
            >
            <span class="text-[9px] uppercase tracking-widest text-slate-400 font-bold"
              >{{ localeStore.t('offered_ratio') }}</span
            >
          </div>
          <span class="text-[10px] text-slate-500 mt-4 block">{{ localeStore.t('offered_percentage_desc') }}</span>
        </div>

        <!-- Metric Cards Grid -->
        <div class="md:col-span-3 grid grid-cols-2 sm:grid-cols-4 gap-4">
          <div
            class="bg-slate-900/40 border border-slate-800 p-5 rounded-2xl flex flex-col justify-between"
          >
            <span class="text-slate-400 text-xs font-semibold uppercase tracking-wider"
              >{{ localeStore.t('total_logged') }}</span
            >
            <span class="text-3xl font-extrabold text-slate-100 mt-2">{{
              store.analytics.totalLogged
            }}</span>
            <span class="text-[10px] text-slate-500 mt-1">{{ localeStore.t('salahs_entries') }}</span>
          </div>

          <div
            class="bg-slate-900/40 border border-slate-800 p-5 rounded-2xl flex flex-col justify-between"
          >
            <span class="text-slate-400 text-xs font-semibold uppercase tracking-wider"
              >{{ localeStore.t('offered') }}</span
            >
            <span class="text-3xl font-extrabold text-emerald-400 mt-2">{{
              store.analytics.totalOffered
            }}</span>
            <span class="text-[10px] text-slate-500 mt-1">{{ localeStore.t('salahs_performed') }}</span>
          </div>

          <div
            class="bg-slate-900/40 border border-slate-800 p-5 rounded-2xl flex flex-col justify-between"
          >
            <span class="text-slate-400 text-xs font-semibold uppercase tracking-wider"
              >{{ localeStore.t('missed') }}</span
            >
            <span class="text-3xl font-extrabold text-rose-400 mt-2">{{
              store.analytics.totalMissed
            }}</span>
            <span class="text-[10px] text-slate-500 mt-1">{{ localeStore.t('salahs_missed') }}</span>
          </div>

          <div
            class="bg-slate-900/40 border border-slate-800 p-5 rounded-2xl flex flex-col justify-between"
          >
            <span class="text-slate-400 text-xs font-semibold uppercase tracking-wider"
              >{{ localeStore.t('qaza_made_up') }}</span
            >
            <span class="text-3xl font-extrabold text-indigo-400 mt-2">{{
              store.analytics.qazaSummary.totalFulfilled
            }}</span>
            <span class="text-[10px] text-slate-500 mt-1">{{ localeStore.t('makeup_prayers_logged') }}</span>
          </div>
        </div>
      </div>

      <!-- Mid Section: Punctuality and Missed Reasons Breakdown -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Punctuality Breakdown -->
        <div class="bg-slate-900/40 border border-slate-800 p-6 rounded-2xl shadow-lg">
          <h3 class="text-base font-bold text-slate-200 mb-6">{{ localeStore.t('waqt_distribution') }}</h3>

          <div class="space-y-4">
            <div>
              <div class="flex justify-between text-xs font-semibold text-slate-300 mb-1.5">
                <span>{{ localeStore.t('awwal_waqt_title') }}</span>
                <span
                  >{{ store.analytics.punctuality.awwalAlWaqtCount }} ({{
                    store.analytics.punctuality.awwalAlWaqtPercentage
                  }}%)</span
                >
              </div>
              <div class="w-full bg-slate-950 h-2.5 rounded-full overflow-hidden">
                <div
                  class="bg-emerald-500 h-full rounded-full transition-all duration-700"
                  :style="{ width: `${store.analytics.punctuality.awwalAlWaqtPercentage}%` }"
                ></div>
              </div>
            </div>

            <div>
              <div class="flex justify-between text-xs font-semibold text-slate-300 mb-1.5">
                <span>{{ localeStore.t('wast_waqt_title') }}</span>
                <span
                  >{{ store.analytics.punctuality.wastAlWaqtCount }} ({{
                    store.analytics.punctuality.wastAlWaqtPercentage
                  }}%)</span
                >
              </div>
              <div class="w-full bg-slate-950 h-2.5 rounded-full overflow-hidden">
                <div
                  class="bg-amber-500 h-full rounded-full transition-all duration-700"
                  :style="{ width: `${store.analytics.punctuality.wastAlWaqtPercentage}%` }"
                ></div>
              </div>
            </div>

            <div>
              <div class="flex justify-between text-xs font-semibold text-slate-300 mb-1.5">
                <span>{{ localeStore.t('akhir_waqt_title') }}</span>
                <span
                  >{{ store.analytics.punctuality.akhirAlWaqtCount }} ({{
                    store.analytics.punctuality.akhirAlWaqtPercentage
                  }}%)</span
                >
              </div>
              <div class="w-full bg-slate-950 h-2.5 rounded-full overflow-hidden">
                <div
                  class="bg-rose-500 h-full rounded-full transition-all duration-700"
                  :style="{ width: `${store.analytics.punctuality.akhirAlWaqtPercentage}%` }"
                ></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Missed Reasons Breakdown -->
        <div class="bg-slate-900/40 border border-slate-800 p-6 rounded-2xl shadow-lg">
          <h3 class="text-base font-bold text-slate-200 mb-4">{{ localeStore.t('situational_absences') }}</h3>
          <div
            class="flex items-center gap-4 text-xs font-semibold text-slate-400 mb-6 border-b border-slate-800 pb-3"
          >
            <span
              >{{ localeStore.t('excused_total') }}:
              <b class="text-indigo-400">{{ store.analytics.missedReasons.totalExcused }}</b></span
            >
            <span class="text-slate-700">|</span>
            <span
              >{{ localeStore.t('unexcused_total') }}:
              <b class="text-rose-400">{{ store.analytics.missedReasons.totalUnexcused }}</b></span
            >
          </div>

          <div class="grid grid-cols-2 gap-x-6 gap-y-4">
            <!-- Sleep -->
            <div>
              <span class="text-[10px] text-slate-400 font-semibold block">{{ localeStore.t('sleep') }}</span>
              <span class="text-lg font-bold text-slate-200 mt-0.5 block">{{
                store.analytics.missedReasons.excusedSleepCount
              }}</span>
            </div>
            <!-- Forget -->
            <div>
              <span class="text-[10px] text-slate-400 font-semibold block"
                >{{ localeStore.t('forgetfulness') }}</span
              >
              <span class="text-lg font-bold text-slate-200 mt-0.5 block">{{
                store.analytics.missedReasons.excusedForgetfulnessCount
              }}</span>
            </div>
            <!-- Impurity -->
            <div>
              <span class="text-[10px] text-slate-400 font-semibold block"
                >{{ localeStore.t('impurity') }}</span
              >
              <span class="text-lg font-bold text-slate-200 mt-0.5 block">{{
                store.analytics.missedReasons.excusedImpurityCount
              }}</span>
            </div>
            <!-- Laziness -->
            <div>
              <span class="text-[10px] text-slate-400 font-semibold block">{{ localeStore.t('laziness') }}</span>
              <span class="text-lg font-bold text-rose-400 mt-0.5 block">{{
                store.analytics.missedReasons.unexcusedLazinessCount
              }}</span>
            </div>
            <!-- Distraction -->
            <div>
              <span class="text-[10px] text-slate-400 font-semibold block"
                >{{ localeStore.t('distraction') }}</span
              >
              <span class="text-lg font-bold text-rose-400 mt-0.5 block">{{
                store.analytics.missedReasons.unexcusedDistractionCount
              }}</span>
            </div>
            <!-- Situational -->
            <div>
              <span class="text-[10px] text-slate-400 font-semibold block"
                >{{ localeStore.t('situational') }}</span
              >
              <span class="text-lg font-bold text-rose-400 mt-0.5 block">{{
                store.analytics.missedReasons.unexcusedSituationalCount
              }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Lower Section: Prayer Specific Statistics -->
      <div class="bg-slate-900/40 border border-slate-800 rounded-2xl overflow-hidden shadow-lg">
        <div class="p-6 border-b border-slate-800">
          <h3 class="text-base font-bold text-slate-200">{{ localeStore.t('salah_breakdown_metrics') }}</h3>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left text-xs text-slate-300">
            <thead
              class="bg-slate-950 text-slate-400 font-bold uppercase tracking-wider text-[10px]"
            >
              <tr>
                <th class="p-4">{{ localeStore.t('prayer_name') }}</th>
                <th class="p-4">{{ localeStore.t('obligated') }}</th>
                <th class="p-4">{{ localeStore.t('offered') }}</th>
                <th class="p-4">{{ localeStore.t('offered_ratio') }}</th>
                <th class="p-4">{{ localeStore.t('jamaah_count') }}</th>
                <th class="p-4">{{ localeStore.t('jamaah_rate') }}</th>
                <th class="p-4">{{ localeStore.t('travel_count') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-800/50">
              <tr
                v-for="pName in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']"
                :key="pName"
                class="hover:bg-slate-950/20"
              >
                <td class="p-4 font-bold text-slate-200">{{ getLocalizedPrayerNameStr(pName) }}</td>
                <td class="p-4 text-slate-400">
                  {{ store.analytics.prayerStats[pName]?.totalObligated ?? 0 }}
                </td>
                <td class="p-4 text-slate-400">
                  {{ store.analytics.prayerStats[pName]?.totalOffered ?? 0 }}
                </td>
                <td class="p-4">
                  <span
                    class="font-bold px-2 py-0.5 rounded text-[10px]"
                    :class="[
                      (store.analytics.prayerStats[pName]?.offeredPercentage ?? 0) >= 90
                        ? 'bg-emerald-950/40 text-emerald-400'
                        : (store.analytics.prayerStats[pName]?.offeredPercentage ?? 0) >= 70
                          ? 'bg-amber-950/40 text-amber-400'
                          : 'bg-rose-950/40 text-rose-400',
                    ]"
                  >
                    {{ store.analytics.prayerStats[pName]?.offeredPercentage ?? 0 }}%
                  </span>
                </td>
                <td class="p-4 text-slate-400">
                  {{ store.analytics.prayerStats[pName]?.jamaahCount ?? 0 }}
                </td>
                <td class="p-4 text-slate-400">
                  {{ store.analytics.prayerStats[pName]?.jamaahPercentage ?? 0 }}%
                </td>
                <td class="p-4 text-slate-400">
                  {{ store.analytics.prayerStats[pName]?.travelingCount ?? 0 }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Qaza Lifecycle Analysis -->
      <div class="bg-slate-900/40 border border-slate-800 p-6 rounded-2xl shadow-lg">
        <h3 class="text-base font-bold text-slate-200 mb-4">{{ localeStore.t('lifetime_resolution') }}</h3>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
          <div class="bg-slate-950/30 border border-slate-900 p-4 rounded-xl text-center">
            <span class="text-[10px] text-slate-400 font-semibold uppercase tracking-wider"
              >{{ localeStore.t('average_resolution') }}</span
            >
            <span class="text-2xl font-black block mt-2 text-indigo-400">
              {{ localeStore.t('hours_abbr', { hours: store.analytics.qazaSummary.averageResolutionTimeHours }) }}
            </span>
            <span class="text-[10px] text-slate-500 mt-1 block">{{ localeStore.t('from_missed_to_makeup') }}</span>
          </div>

          <div class="bg-slate-950/30 border border-slate-900 p-4 rounded-xl text-center">
            <span class="text-[10px] text-slate-400 font-semibold uppercase tracking-wider"
              >{{ localeStore.t('total_incurred') }}</span
            >
            <span class="text-2xl font-black block mt-2 text-slate-100">
              {{ store.analytics.qazaSummary.totalIncurred }}
            </span>
            <span class="text-[10px] text-slate-500 mt-1 block">{{ localeStore.t('total_lifetime_missed') }}</span>
          </div>

          <div class="bg-slate-950/30 border border-slate-900 p-4 rounded-xl text-center">
            <span class="text-[10px] text-slate-400 font-semibold uppercase tracking-wider"
              >{{ localeStore.t('total_pending') }}</span
            >
            <span class="text-2xl font-black block mt-2 text-rose-400">
              {{ store.analytics.qazaSummary.totalPending }}
            </span>
            <span class="text-[10px] text-slate-500 mt-1 block">{{ localeStore.t('pending_in_current_ledger') }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
