<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { districts, divisionsList } from '@/data/districts'
import { useLocaleStore } from '@/stores/locale'
import { useTimingStore } from '@/stores/timing'
import { calculateDistrictWaktSummary, type DistrictWaktSummary } from '@/services/prayerTimes'

const props = defineProps<{ date?: string }>()
const locale = useLocaleStore()
const timing = useTimingStore()

const now = ref(new Date())
const searchQuery = ref('')
const selectedDivision = ref('all')
const sortBy = ref<'name' | 'timeLeft'>('name')
const targetDate = computed(() => props.date || timing.today)

let timer: ReturnType<typeof setInterval>
const refreshNow = () => { now.value = new Date() }

onMounted(() => {
  refreshNow()
  timer = setInterval(refreshNow, 1000)
  document.addEventListener('visibilitychange', refreshNow)
  window.addEventListener('focus', refreshNow)
  window.addEventListener('iqamah-resume', refreshNow)
})

onUnmounted(() => {
  clearInterval(timer)
  document.removeEventListener('visibilitychange', refreshNow)
  window.removeEventListener('focus', refreshNow)
  window.removeEventListener('iqamah-resume', refreshNow)
})

const formatTime = (time: Date) =>
  time.toLocaleTimeString(locale.currentLocale === 'bn' ? 'bn-BD' : 'en', {
    timeZone: 'Asia/Dhaka',
    hour: 'numeric',
    minute: '2-digit',
  })

const formatDuration = (totalSeconds: number) => {
  if (totalSeconds <= 0) return ''
  const isBn = locale.currentLocale === 'bn'
  const hours = Math.floor(totalSeconds / 3600)
  const minutes = Math.floor((totalSeconds % 3600) / 60)
  const seconds = totalSeconds % 60

  const toDigits = (n: number) =>
    n.toLocaleString(isBn ? 'bn-BD' : 'en', { useGrouping: false })

  if (hours > 0) {
    return isBn
      ? `${toDigits(hours)} ${locale.t('hours_short')} ${toDigits(minutes)} ${locale.t('minutes_short')}`
      : `${hours}${locale.t('hours_short')} ${minutes}${locale.t('minutes_short')}`
  }
  if (minutes > 0) {
    return isBn
      ? `${toDigits(minutes)} ${locale.t('minutes_short')} ${toDigits(seconds)} ${locale.t('seconds_short')}`
      : `${minutes}${locale.t('minutes_short')} ${seconds}${locale.t('seconds_short')}`
  }
  return isBn
    ? `${toDigits(seconds)} ${locale.t('seconds_short')}`
    : `${seconds}${locale.t('seconds_short')}`
}

const allSummaries = computed<DistrictWaktSummary[]>(() => {
  const cfg = timing.config ?? undefined
  const dateStr = targetDate.value
  const currentTime = now.value

  return districts.map(district =>
    calculateDistrictWaktSummary(district, dateStr, currentTime, cfg)
  )
})

const filteredSummaries = computed(() => {
  const query = searchQuery.value.trim().toLowerCase()
  const div = selectedDivision.value

  let result = allSummaries.value.filter(item => {
    if (div !== 'all' && item.district.division !== div) {
      return false
    }
    if (!query) return true
    return (
      item.district.name.toLowerCase().includes(query) ||
      item.district.bnName.includes(query)
    )
  })

  if (sortBy.value === 'timeLeft') {
    result = [...result].sort((a, b) => {
      // Current Wakt time left ascending
      const aLeft = a.currentWaktTimeLeftSeconds || Number.MAX_SAFE_INTEGER
      const bLeft = b.currentWaktTimeLeftSeconds || Number.MAX_SAFE_INTEGER
      return aLeft - bLeft
    })
  } else {
    result = [...result].sort((a, b) => {
      // Put user's current district first if selected
      const aIsCurrent = a.district.id === timing.districtId
      const bIsCurrent = b.district.id === timing.districtId
      if (aIsCurrent && !bIsCurrent) return -1
      if (!aIsCurrent && bIsCurrent) return 1
      return a.district.name.localeCompare(b.district.name)
    })
  }

  return result
})

const handleSetDistrict = (id: string) => {
  try {
    timing.selectDistrict(id)
  } catch {
    /* Safe ignore if quota fails */
  }
}
</script>

<template>
  <section class="iq-surface all-districts-tracker space-y-5" aria-labelledby="all-districts-heading">
    <div class="flex items-start justify-between gap-3 flex-wrap">
      <div>
        <h2 id="all-districts-heading" class="iq-section-heading">
          {{ locale.t('all_districts_wakt_title') }}
        </h2>
        <p class="iq-secondary mt-1">
          {{ locale.t('all_districts_wakt_subtitle') }}
        </p>
      </div>
      <div class="flex items-center gap-2">
        <label class="iq-secondary text-xs flex items-center gap-1.5 font-semibold">
          <span>Sort:</span>
          <select v-model="sortBy" class="bg-inherit border border-current/20 rounded px-2 py-1 text-xs">
            <option value="name">{{ locale.currentLocale === 'bn' ? 'নাম অনুযায়ী' : 'Alphabetical' }}</option>
            <option value="timeLeft">{{ locale.currentLocale === 'bn' ? 'অবশিষ্ট সময় অনুযায়ী' : 'Time Left' }}</option>
          </select>
        </label>
      </div>
    </div>

    <!-- Controls: Search bar & Division filter chips -->
    <div class="space-y-3">
      <div class="flex items-center gap-2">
        <label class="sr-only" for="district-search-input">{{ locale.t('search_district') }}</label>
        <div class="relative flex-1">
          <input
            id="district-search-input"
            v-model="searchQuery"
            type="search"
            :placeholder="locale.t('search_district')"
            class="w-full min-h-[42px] px-3.5 py-2 rounded-lg border border-[var(--iq-border)] bg-[var(--iq-secondary-surface)] text-[var(--iq-text)] text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--iq-focus)]"
          />
        </div>
      </div>

      <!-- Division Filter Buttons -->
      <div class="flex items-center gap-1.5 overflow-x-auto pb-1 text-xs" role="toolbar" :aria-label="locale.t('filter_by_division')">
        <button
          type="button"
          class="px-2.5 py-1.5 rounded-md font-medium whitespace-nowrap transition-colors"
          :class="selectedDivision === 'all' ? 'bg-[var(--iq-brand)] text-[var(--iq-on-brand)]' : 'bg-[var(--iq-secondary-surface)] text-[var(--iq-secondary)] hover:text-[var(--iq-text)] border border-[var(--iq-border)]'"
          @click="selectedDivision = 'all'"
        >
          {{ locale.t('all_divisions') }} (64)
        </button>
        <button
          v-for="div in divisionsList"
          :key="div.en"
          type="button"
          class="px-2.5 py-1.5 rounded-md font-medium whitespace-nowrap transition-colors"
          :class="selectedDivision === div.en ? 'bg-[var(--iq-brand)] text-[var(--iq-on-brand)]' : 'bg-[var(--iq-secondary-surface)] text-[var(--iq-secondary)] hover:text-[var(--iq-text)] border border-[var(--iq-border)]'"
          @click="selectedDivision = div.en"
        >
          {{ locale.currentLocale === 'bn' ? div.bn : div.en }}
        </button>
      </div>
    </div>

    <!-- Empty search result -->
    <div v-if="filteredSummaries.length === 0" class="py-8 text-center text-sm text-[var(--iq-secondary)]">
      <p>{{ locale.t('no_districts_found') }}</p>
    </div>

    <!-- Districts Grid -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <article
        v-for="item in filteredSummaries"
        :key="item.district.id"
        class="border border-[var(--iq-border)] rounded-xl p-4 bg-[var(--iq-surface)] transition-all relative flex flex-col justify-between"
        :class="{ 'ring-2 ring-[var(--iq-brand)] bg-[var(--iq-accent)]/10': item.district.id === timing.districtId }"
      >
        <!-- District Header -->
        <div>
          <div class="flex items-start justify-between gap-2">
            <div>
              <div class="flex items-center gap-2 flex-wrap">
                <h3 class="font-bold text-base text-[var(--iq-text)]">
                  {{ locale.currentLocale === 'bn' ? item.district.bnName : item.district.name }}
                  <span class="text-xs font-normal text-[var(--iq-secondary)]">
                    ({{ locale.currentLocale === 'bn' ? item.district.name : item.district.bnName }})
                  </span>
                </h3>
                <span v-if="item.district.id === timing.districtId" class="text-[11px] font-bold px-2 py-0.5 rounded-full bg-[var(--iq-accent)] text-[var(--iq-brand)]">
                  {{ locale.t('my_district') }}
                </span>
              </div>
              <span class="text-xs text-[var(--iq-secondary)]">
                {{ locale.currentLocale === 'bn' ? item.district.divisionBn : item.district.division }} · {{ locale.t('district_estimate') }}
              </span>
            </div>

            <button
              v-if="item.district.id !== timing.districtId"
              type="button"
              class="text-xs font-semibold text-[var(--iq-brand)] underline hover:no-underline whitespace-nowrap"
              @click="handleSetDistrict(item.district.id)"
            >
              {{ locale.t('set_as_my_district') }}
            </button>
          </div>

          <!-- Active Waqt Hero Banner -->
          <div class="mt-3 mb-3.5 p-2.5 rounded-lg border border-[var(--iq-border)] bg-[var(--iq-secondary-surface)] flex items-center justify-between gap-2 flex-wrap">
            <div class="flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" aria-hidden="true"></span>
              <span class="text-xs text-[var(--iq-secondary)] font-medium">
                {{ locale.t('current_wakt_active') }}:
              </span>
              <strong v-if="item.currentWakt" class="text-sm font-bold text-[var(--iq-brand)]">
                {{ locale.t(item.currentWakt) }}
              </strong>
              <span v-else class="text-xs font-medium text-[var(--iq-secondary)]">
                —
              </span>
            </div>

            <!-- Remaining Time Badge -->
            <div v-if="item.currentWakt && item.currentWaktTimeLeftSeconds > 0" class="text-right">
              <span class="text-xs font-medium text-[var(--iq-secondary)]">
                {{ locale.t('ends_in') }}:
              </span>
              <span class="text-sm font-bold text-[var(--iq-brand)] tabular-nums ml-1">
                {{ formatDuration(item.currentWaktTimeLeftSeconds) }}
              </span>
            </div>
            <div v-else-if="item.nextWakt" class="text-right">
              <span class="text-xs font-medium text-[var(--iq-secondary)]">
                {{ locale.t(item.nextWakt.key) }} {{ locale.t('starts_in') }}:
              </span>
              <span class="text-sm font-bold text-[var(--iq-brand)] tabular-nums ml-1">
                {{ formatDuration(item.nextWakt.secondsUntilStart) }}
              </span>
            </div>
          </div>
        </div>

        <!-- 5 Wakts Detailed Timetable Rows -->
        <dl class="space-y-1.5 text-xs">
          <div
            v-for="p in item.prayers"
            :key="p.key"
            class="flex items-center justify-between py-1 px-2 rounded transition-colors"
            :class="p.status === 'current' ? 'bg-[var(--iq-accent)] text-[var(--iq-brand)] font-semibold' : 'text-[var(--iq-text)]'"
          >
            <!-- Wakt Name & Window -->
            <dt class="flex items-center gap-1.5 min-w-[75px]">
              <span>{{ locale.t(p.key) }}</span>
            </dt>

            <!-- Start Time -->
            <dd class="tabular-nums font-medium text-[var(--iq-secondary)]">
              {{ formatTime(p.start) }} – {{ formatTime(p.end) }}
            </dd>

            <!-- Status & Countdown -->
            <dd class="text-right tabular-nums min-w-[85px]">
              <span v-if="p.status === 'current'" class="text-emerald-700 dark:text-emerald-300 font-bold">
                {{ locale.t('wakt_remaining') }} {{ formatDuration(p.secondsRemaining) }}
              </span>
              <span v-else-if="p.status === 'upcoming'" class="text-[var(--iq-secondary)]">
                {{ locale.t('wakt_starts_in') }} {{ formatDuration(p.secondsRemaining) }}
              </span>
              <span v-else class="text-[var(--iq-secondary)] opacity-60">
                {{ locale.t('window_ended') }}
              </span>
            </dd>
          </div>
        </dl>
      </article>
    </div>
  </section>
</template>
