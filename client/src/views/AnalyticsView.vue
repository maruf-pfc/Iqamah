<script setup lang="ts">
import { ref, watch } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useLocaleStore } from '@/stores/locale'

const store = usePrayerStore()
const localeStore = useLocaleStore()

const getLocalizedPrayerNameStr = (pName: string) => {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
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
      class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 islamic-card p-6 rounded-2xl shadow-xl islamic-border-top"
    >
      <div>
        <h1
          class="text-3xl font-serif font-bold bg-gradient-to-r from-gold-100 via-gold-300 to-gold-500 bg-clip-text text-transparent tracking-wide"
        >
          {{ localeStore.t('salah_analytics') }}
        </h1>
        <p class="text-gold-200/60 text-sm mt-1">
          {{ localeStore.t('analytics_tagline') }}
        </p>
      </div>
    </div>

    <!-- Range Selector Toolbar -->
    <div
      class="flex flex-wrap items-center justify-between gap-4 islamic-card p-4 rounded-2xl border-t border-gold-500/10"
    >
      <div class="flex bg-islamic-deep p-1 rounded-xl border border-gold-500/15">
        <button
          v-for="r in ['7d', '30d', '365d'] as const"
          :key="r"
          @click="setRange(r)"
          class="px-4 py-1.5 text-xs font-bold rounded-lg transition-all cursor-pointer"
          :class="[
            activeRange === r
              ? 'bg-gradient-to-r from-gold-500 to-gold-600 text-islamic-deep shadow-md font-bold'
              : 'text-gold-300/60 hover:text-gold-200',
          ]"
        >
          {{ r === '7d' ? localeStore.t('days_7') : r === '30d' ? localeStore.t('days_30') : localeStore.t('year_1') }}
        </button>
        <button
          @click="activeRange = 'custom'"
          class="px-4 py-1.5 text-xs font-bold rounded-lg transition-all cursor-pointer"
          :class="[
            activeRange === 'custom'
              ? 'bg-gradient-to-r from-gold-500 to-gold-600 text-islamic-deep shadow-md font-bold'
              : 'text-gold-300/60 hover:text-gold-200',
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
          class="bg-islamic-deep border border-gold-500/20 text-slate-200 rounded-lg px-3 py-1 text-xs focus:outline-none focus:border-gold-500"
        />
        <span class="text-gold-200/40 text-xs">{{ localeStore.t('to') }}</span>
        <input
          type="date"
          v-model="toDate"
          class="bg-islamic-deep border border-gold-500/20 text-slate-200 rounded-lg px-3 py-1 text-xs focus:outline-none focus:border-gold-500"
        />
      </div>
    </div>

    <div v-if="store.loading" class="flex flex-col items-center py-24">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-gold-500 mb-4"></div>
      <p class="text-gold-200/60 text-sm">{{ localeStore.t('processing_analytics') }}</p>
    </div>

    <div v-else-if="!store.analytics" class="text-center py-16">
      <p class="text-gold-300/55 font-serif">{{ localeStore.t('no_analytics_data') }}</p>
    </div>

    <!-- Analytics Dashboard Content -->
    <div v-else class="space-y-6">
      <!-- Upper Section: Key Metrics Overview -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <!-- Offered Ratio Dial -->
        <div
          class="islamic-card p-6 rounded-2xl flex flex-col items-center justify-center text-center relative overflow-hidden border-t border-gold-500/10"
        >
          <svg class="w-32 h-32 transform -rotate-90">
            <!-- Background circle -->
            <circle cx="64" cy="64" r="50" fill="transparent" stroke="#0c261b" stroke-width="10" />
            <!-- Foreground dial -->
            <circle
              cx="64"
              cy="64"
              r="50"
              fill="transparent"
              stroke="#d4af37"
              stroke-width="10"
              stroke-linecap="round"
              :stroke-dasharray="2 * Math.PI * 50"
              :stroke-dashoffset="strokeDashOffset(store.analytics.offeredPercentage)"
              class="transition-all duration-1000 ease-out"
            />
          </svg>
          <div class="absolute flex flex-col items-center justify-center">
            <span class="text-2xl font-serif font-bold text-gold-300 text-glow-gold"
              >{{ store.analytics.offeredPercentage }}%</span
            >
            <span class="text-[9px] uppercase tracking-widest text-gold-200/50 font-black"
              >{{ localeStore.t('offered_ratio') }}</span
            >
          </div>
          <span class="text-[10px] text-slate-500 mt-4 block">{{ localeStore.t('offered_percentage_desc') }}</span>
        </div>

        <!-- Metric Cards Grid -->
        <div class="md:col-span-3 grid grid-cols-2 sm:grid-cols-4 gap-4">
          <div
            class="islamic-card p-5 rounded-2xl flex flex-col justify-between islamic-card-hover border-t border-gold-500/10"
          >
            <span class="text-gold-200/50 text-xs font-bold uppercase tracking-wider"
              >{{ localeStore.t('total_logged') }}</span
            >
            <span class="text-3xl font-serif font-bold text-slate-100 mt-2">{{
              store.analytics.totalLogged
            }}</span>
            <span class="text-[10px] text-slate-500 mt-1">{{ localeStore.t('salahs_entries') }}</span>
          </div>

          <div
            class="islamic-card p-5 rounded-2xl flex flex-col justify-between islamic-card-hover border-t border-gold-500/10"
          >
            <span class="text-gold-200/50 text-xs font-bold uppercase tracking-wider"
              >{{ localeStore.t('offered') }}</span
            >
            <span class="text-3xl font-serif font-bold text-emerald-400 text-glow-emerald mt-2">{{
              store.analytics.totalOffered
            }}</span>
            <span class="text-[10px] text-slate-500 mt-1">{{ localeStore.t('salahs_performed') }}</span>
          </div>

          <div
            class="islamic-card p-5 rounded-2xl flex flex-col justify-between islamic-card-hover border-t border-gold-500/10"
          >
            <span class="text-gold-200/50 text-xs font-bold uppercase tracking-wider"
              >{{ localeStore.t('missed') }}</span
            >
            <span class="text-3xl font-serif font-bold text-rose-400 mt-2">{{
              store.analytics.totalMissed
            }}</span>
            <span class="text-[10px] text-slate-500 mt-1">{{ localeStore.t('salahs_missed') }}</span>
          </div>

          <div
            class="islamic-card p-5 rounded-2xl flex flex-col justify-between islamic-card-hover border-t border-gold-500/10"
          >
            <span class="text-gold-200/50 text-xs font-bold uppercase tracking-wider"
              >{{ localeStore.t('qaza_made_up') }}</span
            >
            <span class="text-3xl font-serif font-bold text-gold-400 text-glow-gold mt-2">{{
              store.analytics.qazaSummary.totalFulfilled
            }}</span>
            <span class="text-[10px] text-slate-500 mt-1">{{ localeStore.t('makeup_prayers_logged') }}</span>
          </div>
        </div>
      </div>

      <!-- Mid Section: Punctuality and Missed Reasons Breakdown -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Punctuality Breakdown -->
        <div class="islamic-card p-6 rounded-2xl shadow-lg border-t border-gold-500/10">
          <h3 class="text-base font-serif font-bold text-slate-200 mb-6">{{ localeStore.t('waqt_distribution') }}</h3>

          <div class="space-y-4">
            <div>
              <div class="flex justify-between text-xs font-bold text-gold-200/80 mb-1.5">
                <span>{{ localeStore.t('awwal_waqt_title') }}</span>
                <span
                  >{{ store.analytics.punctuality.awwalAlWaqtCount }} ({{
                    store.analytics.punctuality.awwalAlWaqtPercentage
                  }}%)</span
                >
              </div>
              <div class="w-full bg-islamic-deep h-2.5 rounded-full overflow-hidden border border-gold-500/5">
                <div
                  class="bg-gradient-to-r from-gold-500 to-gold-600 h-full rounded-full transition-all duration-700"
                  :style="{ width: `${store.analytics.punctuality.awwalAlWaqtPercentage}%` }"
                ></div>
              </div>
            </div>

            <div>
              <div class="flex justify-between text-xs font-bold text-gold-200/80 mb-1.5">
                <span>{{ localeStore.t('wast_waqt_title') }}</span>
                <span
                  >{{ store.analytics.punctuality.wastAlWaqtCount }} ({{
                    store.analytics.punctuality.wastAlWaqtPercentage
                  }}%)</span
                >
              </div>
              <div class="w-full bg-islamic-deep h-2.5 rounded-full overflow-hidden border border-gold-500/5">
                <div
                  class="bg-emerald-600 h-full rounded-full transition-all duration-700"
                  :style="{ width: `${store.analytics.punctuality.wastAlWaqtPercentage}%` }"
                ></div>
              </div>
            </div>

            <div>
              <div class="flex justify-between text-xs font-bold text-gold-200/80 mb-1.5">
                <span>{{ localeStore.t('akhir_waqt_title') }}</span>
                <span
                  >{{ store.analytics.punctuality.akhirAlWaqtCount }} ({{
                    store.analytics.punctuality.akhirAlWaqtPercentage
                  }}%)</span
                >
              </div>
              <div class="w-full bg-islamic-deep h-2.5 rounded-full overflow-hidden border border-gold-500/5">
                <div
                  class="bg-rose-500 h-full rounded-full transition-all duration-700"
                  :style="{ width: `${store.analytics.punctuality.akhirAlWaqtPercentage}%` }"
                ></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Missed Reasons Breakdown -->
        <div class="islamic-card p-6 rounded-2xl shadow-lg border-t border-gold-500/10">
          <h3 class="text-base font-serif font-bold text-slate-200 mb-4">{{ localeStore.t('situational_absences') }}</h3>
          <div
            class="flex items-center gap-4 text-xs font-bold text-gold-200/50 mb-6 border-b border-gold-500/10 pb-3"
          >
            <span
              >{{ localeStore.t('excused_total') }}:
              <b class="text-gold-400 font-serif">{{ store.analytics.missedReasons.totalExcused }}</b></span
            >
            <span class="text-gold-500/20">|</span>
            <span
              >{{ localeStore.t('unexcused_total') }}:
              <b class="text-rose-400">{{ store.analytics.missedReasons.totalUnexcused }}</b></span
            >
          </div>

          <div class="grid grid-cols-2 gap-x-6 gap-y-4">
            <!-- Sleep -->
            <div>
              <span class="text-[10px] text-gold-200/50 font-bold uppercase tracking-wider block">{{ localeStore.t('sleep') }}</span>
              <span class="text-lg font-serif font-bold text-slate-200 mt-0.5 block">{{
                store.analytics.missedReasons.excusedSleepCount
              }}</span>
            </div>
            <!-- Forget -->
            <div>
              <span class="text-[10px] text-gold-200/50 font-bold uppercase tracking-wider block"
                >{{ localeStore.t('forgetfulness') }}</span
              >
              <span class="text-lg font-serif font-bold text-slate-200 mt-0.5 block">{{
                store.analytics.missedReasons.excusedForgetfulnessCount
              }}</span>
            </div>
            <!-- Impurity -->
            <div>
              <span class="text-[10px] text-gold-200/50 font-bold uppercase tracking-wider block"
                >{{ localeStore.t('impurity') }}</span
              >
              <span class="text-lg font-serif font-bold text-slate-200 mt-0.5 block">{{
                store.analytics.missedReasons.excusedImpurityCount
              }}</span>
            </div>
            <!-- Laziness -->
            <div>
              <span class="text-[10px] text-gold-200/50 font-bold uppercase tracking-wider block">{{ localeStore.t('laziness') }}</span>
              <span class="text-lg font-serif font-bold text-rose-400 mt-0.5 block">{{
                store.analytics.missedReasons.unexcusedLazinessCount
              }}</span>
            </div>
            <!-- Distraction -->
            <div>
              <span class="text-[10px] text-gold-200/50 font-bold uppercase tracking-wider block"
                >{{ localeStore.t('distraction') }}</span
              >
              <span class="text-lg font-serif font-bold text-rose-400 mt-0.5 block">{{
                store.analytics.missedReasons.unexcusedDistractionCount
              }}</span>
            </div>
            <!-- Situational -->
            <div>
              <span class="text-[10px] text-gold-200/50 font-bold uppercase tracking-wider block"
                >{{ localeStore.t('situational') }}</span
              >
              <span class="text-lg font-serif font-bold text-rose-400 mt-0.5 block">{{
                store.analytics.missedReasons.unexcusedSituationalCount
              }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Lower Section: Prayer Specific Statistics -->
      <div class="islamic-card rounded-2xl overflow-hidden shadow-lg border-t border-gold-500/10">
        <div class="p-6 border-b border-gold-500/10">
          <h3 class="text-base font-serif font-bold text-slate-200">{{ localeStore.t('salah_breakdown_metrics') }}</h3>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left text-xs text-slate-300">
            <thead
              class="bg-islamic-deep text-gold-200/70 font-bold uppercase tracking-wider text-[10px]"
            >
              <tr>
                <th class="p-4">{{ localeStore.t('prayer_name') }}</th>
                <th class="p-4">{{ localeStore.t('obligated') }}</th>
                <th class="p-4">{{ localeStore.t('offered') }}</th>
                <th class="p-4">{{ localeStore.t('offered_ratio') }}</th>
                <th class="p-4">{{ localeStore.t('jamaah_count') }}</th>
                <th class="p-4">{{ localeStore.t('jamaah_rate') }}</th>
                <th class="p-4">{{ localeStore.t('travel_count') }}</th>
                <th class="p-4">{{ localeStore.t('home_count') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gold-500/10">
              <tr
                v-for="pName in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']"
                :key="pName"
                class="hover:bg-gold-500/5"
              >
                <td class="p-4 font-serif font-bold text-slate-200">{{ getLocalizedPrayerNameStr(pName) }}</td>
                <td class="p-4 text-slate-400">
                  {{ store.analytics.prayerStats[pName]?.totalObligated ?? 0 }}
                </td>
                <td class="p-4 text-slate-400">
                  {{ store.analytics.prayerStats[pName]?.totalOffered ?? 0 }}
                </td>
                <td class="p-4">
                  <span
                    class="font-bold px-2 py-0.5 rounded text-[10px] border"
                    :class="[
                      (store.analytics.prayerStats[pName]?.offeredPercentage ?? 0) >= 90
                        ? 'bg-emerald-950/30 text-emerald-400 border-emerald-900/40'
                        : (store.analytics.prayerStats[pName]?.offeredPercentage ?? 0) >= 70
                          ? 'bg-gold-950/20 text-gold-400 border-gold-500/20'
                          : 'bg-rose-950/30 text-rose-400 border-rose-900/40',
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
                <td class="p-4 text-slate-400">
                  {{ store.analytics.prayerStats[pName]?.homeCount ?? 0 }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Qaza Lifecycle Analysis -->
      <div class="islamic-card p-6 rounded-2xl shadow-lg border-t border-gold-500/10">
        <h3 class="text-base font-serif font-bold text-slate-200 mb-4">{{ localeStore.t('lifetime_resolution') }}</h3>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
          <div class="bg-islamic-deep/60 border border-gold-500/10 p-4 rounded-xl text-center">
            <span class="text-[10px] text-gold-200/50 font-bold uppercase tracking-wider"
              >{{ localeStore.t('average_resolution') }}</span
            >
            <span class="text-2xl font-serif font-bold block mt-2 text-gold-400 text-glow-gold">
              {{ localeStore.t('hours_abbr', { hours: store.analytics.qazaSummary.averageResolutionTimeHours }) }}
            </span>
            <span class="text-[10px] text-slate-500 mt-1 block">{{ localeStore.t('from_missed_to_makeup') }}</span>
          </div>

          <div class="bg-islamic-deep/60 border border-gold-500/10 p-4 rounded-xl text-center">
            <span class="text-[10px] text-gold-200/50 font-bold uppercase tracking-wider"
              >{{ localeStore.t('total_incurred') }}</span
            >
            <span class="text-2xl font-serif font-bold block mt-2 text-slate-100">
              {{ store.analytics.qazaSummary.totalIncurred }}
            </span>
            <span class="text-[10px] text-slate-500 mt-1 block">{{ localeStore.t('total_lifetime_missed') }}</span>
          </div>

          <div class="bg-islamic-deep/60 border border-gold-500/10 p-4 rounded-xl text-center">
            <span class="text-[10px] text-gold-200/50 font-bold uppercase tracking-wider"
              >{{ localeStore.t('total_pending') }}</span
            >
            <span class="text-2xl font-serif font-bold block mt-2 text-rose-400">
              {{ store.analytics.qazaSummary.totalPending }}
            </span>
            <span class="text-[10px] text-slate-500 mt-1 block">{{ localeStore.t('pending_in_current_ledger') }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
