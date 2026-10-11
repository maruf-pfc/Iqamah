import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { calculateSchedule, validConfig, type TimingConfig } from '@/services/prayerTimes'
import { bangladeshDate } from '@/services/calendar'
import { findDistrict } from '@/data/districts'

export const useTimingStore = defineStore('timing', () => {
  const config = ref<TimingConfig | null>(null)
  const now = ref(new Date())
  const error = ref(false)
  const districtId = ref('')
  try {
    const saved: unknown = JSON.parse(localStorage.getItem('iqamah_timing_config') ?? 'null')
    if (validConfig(saved)) {
      const selected = findDistrict(saved.districtId ?? '')
      if (selected && saved.latitude === selected.latitude && saved.longitude === selected.longitude) {
        config.value = saved
        districtId.value = selected.id
      }
    }
  } catch { /* Leave missing configuration visible; never substitute coordinates. */ }

  const refresh = () => { now.value = new Date() }
  const today = computed(() => bangladeshDate(now.value))
  const district = computed(() => findDistrict(districtId.value))
  const save = (value: TimingConfig) => {
    if (!validConfig(value)) throw new Error('Invalid prayer calculation settings.')
    localStorage.setItem('iqamah_timing_config', JSON.stringify(value))
    config.value = { ...value }
    refresh()
  }
  const scheduleFor = (date: string) => {
    error.value = false
    if (!config.value) return null
    try { return calculateSchedule(config.value, date) }
    catch { error.value = true; return null }
  }
  const selectDistrict = (id: string, method: TimingConfig['method'] = config.value?.method ?? 'Karachi', madhab: TimingConfig['madhab'] = config.value?.madhab ?? 'Hanafi') => {
    const selected = findDistrict(id)
    if (!selected) throw new Error('Invalid Bangladesh district.')
    // A single authoritative profile setting; calculation inputs are derived from its bundled reference point.
    save({ latitude: selected.latitude, longitude: selected.longitude, method, madhab, districtId: id })
    districtId.value = id
  }
  const reset = () => {
    localStorage.removeItem('iqamah_timing_config')
    districtId.value = ''
    config.value = null
  }
  return { config, districtId, district, now, today, error, selectDistrict, reset, refresh, scheduleFor }
})
