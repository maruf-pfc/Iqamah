<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useLocaleStore } from '@/stores/locale'
import { bangladeshDate, isCalendarDate } from '@/services/calendar'
import { prayerKeys } from '@/services/prayerTimes'

const store = usePrayerStore()
const locale = useLocaleStore()
const activeRange = ref<'7d' | '30d' | '365d' | 'all' | 'custom'>('30d')
const fromDate = ref('')
const toDate = ref('')
const rangeValid = computed(() => isCalendarDate(fromDate.value) && isCalendarDate(toDate.value) && fromDate.value <= toDate.value)
const failed = ref(false)
const number = (value: number) => value.toLocaleString(locale.currentLocale === 'bn' ? 'bn-BD' : 'en')
const setRange = (range: '7d' | '30d' | '365d' | 'all') => {
  activeRange.value = range
  const today = bangladeshDate()
  const from = new Date(`${today}T12:00:00+06:00`)
  from.setUTCDate(from.getUTCDate() - (range === '7d' ? 6 : range === '30d' ? 29 : 364))
  fromDate.value = range === 'all' ? '0001-01-01' : bangladeshDate(from)
  toDate.value = today
}
setRange('30d')
watch([fromDate, toDate], async () => {
  failed.value = false
  if (!rangeValid.value) return
  try { await store.fetchAnalytics(fromDate.value, toDate.value) } catch { failed.value = true }
}, { immediate: true })
const punctuality = computed(() => {
  const data = store.analytics?.punctuality
  return data ? [
    { key: 'awwal' as const, count: data.awwalAlWaqtCount, percentage: data.awwalAlWaqtPercentage },
    { key: 'wast' as const, count: data.wastAlWaqtCount, percentage: data.wastAlWaqtPercentage },
    { key: 'akhir' as const, count: data.akhirAlWaqtCount, percentage: data.akhirAlWaqtPercentage },
  ] : []
})
const reasons = computed(() => {
  const data = store.analytics?.missedReasons
  return data ? [
    { key: 'impurity' as const, count: data.excusedImpurityCount },
    { key: 'sleep' as const, count: data.excusedSleepCount },
    { key: 'forgetfulness' as const, count: data.excusedForgetfulnessCount },
    { key: 'situational' as const, count: data.unexcusedSituationalCount },
    { key: 'laziness' as const, count: data.unexcusedLazinessCount },
    { key: 'distraction' as const, count: data.unexcusedDistractionCount },
  ] : []
})
</script>

<template>
  <div class="px-6 py-6 space-y-5">
    <header><h1 class="text-2xl font-bold">{{ locale.t('salah_analytics') }}</h1><p class="iq-secondary mt-2">{{ locale.t('analytics_tagline') }}</p></header>
    <div class="flex flex-wrap gap-2">
      <button v-for="range in ['7d', '30d', '365d', 'all'] as const" :key="range" class="iq-button" :class="{ 'iq-button-secondary': activeRange !== range }" :aria-pressed="activeRange === range" @click="setRange(range)">{{ locale.t(range === '7d' ? 'days_7' : range === '30d' ? 'days_30' : range === '365d' ? 'year_1' : 'all_time') }}</button>
      <button class="iq-button" :class="{ 'iq-button-secondary': activeRange !== 'custom' }" :aria-pressed="activeRange === 'custom'" @click="activeRange = 'custom'">{{ locale.t('custom') }}</button>
    </div>
    <div v-if="activeRange === 'custom'" class="grid sm:grid-cols-2 gap-4">
      <label class="iq-field">{{ locale.t('from_date') }}<input type="date" v-model="fromDate" /></label>
      <label class="iq-field">{{ locale.t('to_date') }}<input type="date" v-model="toDate" /></label>
    </div>
    <p v-if="!rangeValid" role="alert">{{ locale.t('invalid_date_range') }}</p>
    <p v-else-if="failed" role="alert">{{ locale.t('data_error') }}</p>
    <p v-else-if="store.loading" role="status">{{ locale.t('processing_analytics') }}</p>
    <p v-else-if="!store.analytics?.totalLogged" class="iq-surface iq-secondary">{{ locale.t('no_analytics_data') }}</p>
    <template v-else-if="store.analytics">
      <dl class="iq-surface grid grid-cols-2 lg:grid-cols-4 gap-5">
        <div><dt class="iq-secondary">{{ locale.t('total_logged') }}</dt><dd class="iq-section-heading">{{ number(store.analytics.totalLogged) }}</dd></div>
        <div><dt class="iq-secondary">{{ locale.t('offered') }}</dt><dd class="iq-section-heading">{{ number(store.analytics.totalOffered) }}</dd></div>
        <div><dt class="iq-secondary">{{ locale.t('missed_count') }}</dt><dd class="iq-section-heading">{{ number(store.analytics.totalMissed) }}</dd></div>
        <div><dt class="iq-secondary">{{ locale.t('offered_ratio') }}</dt><dd class="iq-section-heading">{{ store.analytics.totalObligated ? `${number(store.analytics.offeredPercentage)}%` : '—' }}</dd></div>
      </dl>
      <p class="iq-secondary">{{ locale.t('analytics_denominators') }}</p>
      <div class="grid md:grid-cols-2 gap-5">
        <section class="iq-surface space-y-4">
          <h2 class="iq-section-heading">{{ locale.t('waqt_distribution') }}</h2>
          <p v-if="!store.analytics.totalOffered" class="iq-secondary">{{ locale.t('no_offered_records') }}</p>
          <div v-for="row in punctuality" v-else :key="row.key">
            <p class="flex justify-between gap-3"><span>{{ locale.t(row.key) }}</span><span>{{ number(row.count) }} · {{ number(row.percentage) }}%</span></p>
            <progress class="iq-progress" max="100" :value="row.percentage" :aria-label="locale.t(row.key)">{{ row.percentage }}%</progress>
          </div>
        </section>
        <section class="iq-surface space-y-3">
          <h2 class="iq-section-heading">{{ locale.t('missed_reasons_dist') }}</h2>
          <dl class="space-y-2"><div v-for="row in reasons" :key="row.key" class="flex justify-between gap-3"><dt>{{ locale.t(row.key) }}</dt><dd>{{ number(row.count) }}</dd></div></dl>
          <p class="iq-secondary">{{ locale.t('excused_total') }}: {{ number(store.analytics.missedReasons.totalExcused) }} · {{ locale.t('unexcused_total') }}: {{ number(store.analytics.missedReasons.totalUnexcused) }}</p>
        </section>
      </div>
      <section class="iq-surface space-y-4">
        <h2 class="iq-section-heading">{{ locale.t('salah_performance') }}</h2>
        <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          <div v-for="key in prayerKeys" :key="key">
            <h3 class="font-bold">{{ locale.t(key) }}</h3>
            <dl class="iq-secondary space-y-1">
              <div class="flex justify-between gap-3"><dt>{{ locale.t('obligated') }}</dt><dd>{{ number(store.analytics.prayerStats[key]!.totalObligated) }}</dd></div>
              <div class="flex justify-between gap-3"><dt>{{ locale.t('offered') }}</dt><dd>{{ number(store.analytics.prayerStats[key]!.totalOffered) }} · {{ store.analytics.prayerStats[key]!.totalObligated ? `${number(store.analytics.prayerStats[key]!.offeredPercentage)}%` : '—' }}</dd></div>
              <div class="flex justify-between gap-3"><dt>{{ locale.t('jamaah') }}</dt><dd>{{ number(store.analytics.prayerStats[key]!.jamaahCount) }} · {{ store.analytics.prayerStats[key]!.totalOffered ? `${number(store.analytics.prayerStats[key]!.jamaahPercentage)}%` : '—' }}</dd></div>
              <div class="flex justify-between gap-3"><dt>{{ locale.t('travel_count') }}</dt><dd>{{ number(store.analytics.prayerStats[key]!.travelingCount) }}</dd></div>
              <div class="flex justify-between gap-3"><dt>{{ locale.t('home_count') }}</dt><dd>{{ number(store.analytics.prayerStats[key]!.homeCount) }}</dd></div>
            </dl>
          </div>
        </div>
      </section>
      <section class="iq-surface space-y-3">
        <h2 class="iq-section-heading">{{ locale.t('lifetime_resolution') }}</h2>
        <dl class="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div><dt class="iq-secondary">{{ locale.t('total_incurred') }}</dt><dd class="font-semibold">{{ number(store.analytics.qazaSummary.totalIncurred) }}</dd></div>
          <div><dt class="iq-secondary">{{ locale.t('total_pending') }}</dt><dd class="font-semibold">{{ number(store.analytics.qazaSummary.totalPending) }}</dd></div>
          <div><dt class="iq-secondary">{{ locale.t('qaza_made_up') }}</dt><dd class="font-semibold">{{ number(store.analytics.qazaSummary.totalFulfilled) }}</dd></div>
          <div><dt class="iq-secondary">{{ locale.t('average_resolution') }}</dt><dd class="font-semibold">{{ store.analytics.qazaSummary.totalFulfilled ? locale.t('hours_abbr', { hours: number(store.analytics.qazaSummary.averageResolutionTimeHours) }) : '—' }}</dd></div>
        </dl>
      </section>
    </template>
  </div>
</template>
