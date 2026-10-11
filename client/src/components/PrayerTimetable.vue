<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'
import { useLocaleStore } from '@/stores/locale'
import { useTimingStore } from '@/stores/timing'
import { timingState } from '@/services/prayerTimes'

const props = defineProps<{ date?: string; detailed?: boolean }>()
const locale = useLocaleStore()
const timing = useTimingStore()
const schedule = computed(() => timing.scheduleFor(props.date || timing.today))
const isToday = computed(() => !props.date || props.date === timing.today)
const state = computed(() => schedule.value && isToday.value ? timingState(schedule.value, timing.now) : null)
const countdown = computed(() => {
  const seconds = state.value?.seconds ?? 0
  return [Math.floor(seconds / 3600), Math.floor(seconds / 60) % 60, seconds % 60]
    .map(n => n.toLocaleString(locale.currentLocale === 'bn' ? 'bn-BD' : 'en', { minimumIntegerDigits: 2, useGrouping: false })).join(':')
})
const format = (time: Date) => time.toLocaleTimeString(locale.currentLocale === 'bn' ? 'bn-BD' : 'en', { timeZone: 'Asia/Dhaka', hour: 'numeric', minute: '2-digit' })
let interval: ReturnType<typeof setInterval>
onMounted(() => {
  timing.refresh()
  interval = setInterval(timing.refresh, 1000)
  document.addEventListener('visibilitychange', timing.refresh)
  window.addEventListener('focus', timing.refresh)
  window.addEventListener('iqamah-resume', timing.refresh)
})
onUnmounted(() => {
  clearInterval(interval)
  document.removeEventListener('visibilitychange', timing.refresh)
  window.removeEventListener('focus', timing.refresh)
  window.removeEventListener('iqamah-resume', timing.refresh)
})
</script>

<template>
  <section class="iq-surface timetable" aria-labelledby="timetable-heading">
    <div class="flex items-center justify-between gap-3 flex-wrap">
      <h2 id="timetable-heading" class="iq-section-heading">{{ locale.t('salah_time') }}</h2>
      <div v-if="!detailed" class="flex items-center gap-3 flex-wrap">
        <RouterLink to="/salah-time?view=all-districts" class="iq-link">{{ locale.t('all_districts_times') }}</RouterLink>
        <RouterLink to="/salah-time" class="iq-link">{{ locale.t('full_timetable') }}</RouterLink>
      </div>
    </div>
    <template v-if="schedule">
      <p v-if="timing.district" class="iq-secondary mt-2">{{ locale.currentLocale === 'bn' ? timing.district.bnName : timing.district.name }} · {{ locale.t('district_estimate') }}</p>
      <div v-if="state" class="timing-next">
        <div>
          <span class="iq-secondary">{{ locale.t('next_prayer') }}</span>
          <p class="iq-section-heading">{{ locale.t(state.next.key) }} <span class="iq-secondary">· {{ format(state.next.start) }}</span></p>
        </div>
        <time class="timing-countdown" :aria-label="locale.t('countdown')">{{ countdown }}</time>
      </div>
      <p v-else class="iq-secondary mt-3">{{ date }}</p>
      <dl class="timing-grid">
        <div v-for="prayer in schedule.prayers" :key="prayer.key" class="timing-row" :class="{ 'timing-upcoming': state?.next.key === prayer.key && state.next.start.getTime() === prayer.start.getTime() }">
          <dt>{{ locale.t(prayer.key) }}</dt>
          <dd class="font-semibold tabular-nums">{{ format(prayer.start) }}</dd>
          <dd v-if="detailed" class="iq-secondary">{{ locale.t('window_ends') }} {{ format(prayer.end) }}</dd>
          <dd class="timing-status">{{ state?.current === prayer.key ? locale.t('current_window') : state && timing.now >= prayer.end ? locale.t('window_ended') : state?.next.key === prayer.key && state.next.start.getTime() === prayer.start.getTime() ? locale.t('next_prayer') : '' }}</dd>
        </div>
      </dl>
      <div class="flex justify-between gap-3 flex-wrap iq-secondary">
        <p>{{ locale.t('sunrise') }} · {{ format(schedule.sunrise) }}</p>
        <RouterLink to="/settings#prayer-calculation" class="iq-link">{{ timing.config?.method }} · {{ timing.config?.madhab }}</RouterLink>
      </div>
      <div v-if="detailed" class="mt-5 space-y-3">
        <h3 class="iq-section-heading">{{ locale.t('advisory_windows') }}</h3>
        <p class="iq-secondary">{{ locale.t('timing_qualification') }}</p>
        <ul class="divide-y divide-current/10">
          <li v-for="zone in schedule.zones" :key="zone.key" class="py-3 flex justify-between gap-3 flex-wrap">
            <span>{{ locale.t(zone.key) }} <strong v-if="isToday && timing.now >= zone.start && timing.now < zone.end">· {{ locale.t('current_window') }}</strong></span>
            <span>{{ format(zone.start) }} – {{ format(zone.end) }}</span>
          </li>
        </ul>
        <p class="iq-secondary">{{ locale.t('device_timezone') }}: Asia/Dhaka (UTC+06:00)</p>
      </div>
    </template>
    <div v-else class="mt-4 space-y-3">
      <p role="status" class="iq-secondary">{{ locale.t(timing.error ? 'timing_error' : 'location_prompt') }}</p>
      <RouterLink to="/settings#prayer-calculation" class="iq-button inline-flex">{{ locale.t('configure_timing') }}</RouterLink>
    </div>
  </section>
</template>
