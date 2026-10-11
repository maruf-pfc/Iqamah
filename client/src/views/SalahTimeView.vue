<script setup lang="ts">
import { ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import PrayerTimetable from '@/components/PrayerTimetable.vue'
import AllDistrictsWaktTracker from '@/components/AllDistrictsWaktTracker.vue'
import { bangladeshDate } from '@/services/calendar'
import { useLocaleStore } from '@/stores/locale'

const locale = useLocaleStore()
const route = useRoute()
const date = ref(bangladeshDate())
const activeTab = ref<'single' | 'all'>(route.query.view === 'all-districts' ? 'all' : 'single')

watch(() => route.query.view, (view) => {
  if (view === 'all-districts') {
    activeTab.value = 'all'
  }
})
</script>

<template>
  <div class="px-6 py-6 space-y-5">
    <div class="flex items-center justify-between flex-wrap gap-4">
      <RouterLink to="/" class="iq-link">{{ locale.t('dashboard') }}</RouterLink>

      <!-- View Selector Tabs -->
      <div class="inline-flex rounded-lg border border-[var(--iq-border)] bg-[var(--iq-secondary-surface)] p-1 text-xs" role="tablist">
        <button
          type="button"
          role="tab"
          :aria-selected="activeTab === 'single'"
          class="px-3 py-1.5 rounded-md font-semibold transition-colors"
          :class="activeTab === 'single' ? 'bg-[var(--iq-brand)] text-[var(--iq-on-brand)]' : 'text-[var(--iq-secondary)] hover:text-[var(--iq-text)]'"
          @click="activeTab = 'single'"
        >
          {{ locale.t('single_district_view') }}
        </button>
        <button
          type="button"
          role="tab"
          :aria-selected="activeTab === 'all'"
          class="px-3 py-1.5 rounded-md font-semibold transition-colors"
          :class="activeTab === 'all' ? 'bg-[var(--iq-brand)] text-[var(--iq-on-brand)]' : 'text-[var(--iq-secondary)] hover:text-[var(--iq-text)]'"
          @click="activeTab = 'all'"
        >
          {{ locale.t('all_districts_view') }}
        </button>
      </div>

      <label class="iq-field">{{ locale.t('select_date') }}<input v-model="date" type="date" required /></label>
    </div>

    <!-- Active Tab Display -->
    <PrayerTimetable v-if="activeTab === 'single'" :date="date" detailed />
    <AllDistrictsWaktTracker v-else :date="date" />
  </div>
</template>

