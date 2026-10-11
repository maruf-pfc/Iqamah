import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { districts } from '@/data/districts'
import { useTimingStore } from '@/stores/timing'
import { bangladeshDate } from '@/services/calendar'
import PrayerTimetable from '@/components/PrayerTimetable.vue'
import { useLocaleStore } from '@/stores/locale'

describe('Bangladesh district profile and live timetable', () => {
  beforeEach(() => {
    localStorage.clear()
    setActivePinia(createPinia())
    vi.useFakeTimers()
    vi.setSystemTime(new Date('2026-10-11T17:59:59Z'))
  })
  afterEach(() => { vi.useRealTimers(); vi.restoreAllMocks() })

  it('bundles all 64 unique Bangladesh district reference points', () => {
    expect(districts).toHaveLength(64)
    expect(new Set(districts.map(d => d.id)).size).toBe(64)
    for (const district of districts) {
      expect(district.latitude).toBeGreaterThan(20)
      expect(district.latitude).toBeLessThan(27)
      expect(district.longitude).toBeGreaterThan(88)
      expect(district.longitude).toBeLessThan(93)
      expect(district.bnName).toBeTruthy()
    }
  })

  it('persists a selected profile district and changes the calculation inputs', () => {
    const store = useTimingStore()
    expect(store.config).toBeNull()
    store.selectDistrict('47')
    const dhakaFajr = store.scheduleFor('2026-10-11')!.prayers[0]!.start.getTime()
    store.selectDistrict('36')
    expect(store.district?.name).toBe('Sylhet')
    expect(store.scheduleFor('2026-10-11')!.prayers[0]!.start.getTime()).not.toBe(dhakaFajr)
    setActivePinia(createPinia())
    expect(useTimingStore().districtId).toBe('36')
    expect(() => useTimingStore().selectDistrict('999')).toThrow('Invalid Bangladesh district.')
    expect(useTimingStore().districtId).toBe('36')
  })

  it('shows an honest missing-district prompt with no automatic geolocation', () => {
    const wrapper = mount(PrayerTimetable, { global: { stubs: { RouterLink: true } } })
    expect(wrapper.text()).toContain('Select your Bangladesh district')
    expect(wrapper.findAll('.timing-row')).toHaveLength(0)
    wrapper.unmount()
    expect(vi.getTimerCount()).toBe(0)
  })

  it('refreshes across Bangladesh midnight and resume and cleans up its timer', async () => {
    const store = useTimingStore()
    store.selectDistrict('47')
    const wrapper = mount(PrayerTimetable, { global: { stubs: { RouterLink: true } } })
    expect(wrapper.findAll('.timing-row')).toHaveLength(5)
    expect(store.today).toBe('2026-10-11')
    await vi.advanceTimersByTimeAsync(1000)
    expect(store.today).toBe('2026-10-12')
    vi.setSystemTime(new Date('2026-10-13T01:00:00Z'))
    window.dispatchEvent(new Event('iqamah-resume'))
    await nextTick()
    expect(store.today).toBe('2026-10-13')
    useLocaleStore().setLocale('bn')
    await nextTick()
    expect(wrapper.text()).toContain('ফজর')
    // Drain framework microtasks before checking the component-owned timer.
    await vi.advanceTimersByTimeAsync(0)
    wrapper.unmount()
    expect(vi.getTimerCount()).toBe(0)
  })

  it('uses Bangladesh day independently of the device timezone', () => {
    expect(bangladeshDate(new Date('2026-10-11T18:00:00Z'))).toBe('2026-10-12')
  })

  it('leaves profile settings intact when storage is full', () => {
    const store = useTimingStore()
    store.selectDistrict('47')
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => { throw new Error('quota') })
    expect(() => store.selectDistrict('36')).toThrow('quota')
    expect(store.districtId).toBe('47')
  })
})
