<script setup lang="ts">
import { ref } from 'vue'
import { methods, type TimingConfig } from '@/services/prayerTimes'
import DistrictSelect from './DistrictSelect.vue'
import { useTimingStore } from '@/stores/timing'
import { useLocaleStore } from '@/stores/locale'

const timing = useTimingStore()
const locale = useLocaleStore()
const districtId = ref(timing.districtId)
const method = ref<TimingConfig['method']>(timing.config?.method ?? 'Karachi')
const madhab = ref<TimingConfig['madhab']>(timing.config?.madhab ?? 'Hanafi')
const status = ref<'settings_saved' | 'settings_error' | null>(null)
const save = () => {
  try {
    timing.selectDistrict(districtId.value, method.value, madhab.value)
    status.value = 'settings_saved'
  } catch { status.value = 'settings_error' }
}
</script>

<template>
  <section id="prayer-calculation" class="iq-surface space-y-4">
    <h2 class="iq-section-heading">{{ locale.t('configure_timing') }}</h2>
    <p class="iq-secondary">{{ locale.t('calculation_note') }}</p>
    <form class="space-y-4" @submit.prevent="save">
      <DistrictSelect v-model="districtId" />
      <div class="grid sm:grid-cols-2 gap-4">
        <label class="iq-field">{{ locale.t('calculation_method') }}<select v-model="method"><option v-for="entry in methods" :key="entry">{{ entry }}</option></select></label>
        <label class="iq-field">{{ locale.t('asr_method') }}<select v-model="madhab"><option>Hanafi</option><option>Shafi</option></select></label>
      </div>
      <button type="submit" class="iq-button">{{ locale.t('save') }}</button>
      <p v-if="status" role="status" class="iq-secondary">{{ locale.t(status) }}</p>
    </form>
  </section>
</template>
