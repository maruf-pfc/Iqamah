import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { findDistrict } from '@/data/districts'
import { calculateDistrictWaktSummary } from '@/services/prayerTimes'
import AllDistrictsWaktTracker from '@/components/AllDistrictsWaktTracker.vue'
import { useTimingStore } from '@/stores/timing'
import { useLocaleStore } from '@/stores/locale'

describe('All 64 districts Waqt calculation and real-time tracker', () => {
  beforeEach(() => {
    localStorage.clear()
    setActivePinia(createPinia())
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('calculates Waqt remaining time and prayer statuses for a district during Dhuhr', () => {
    const dhaka = findDistrict('47')!
    expect(dhaka).toBeDefined()
    expect(dhaka.name).toBe('Dhaka')

    // Set time to around 13:00 Bangladesh time (13:00 +06:00 is 07:00 UTC)
    const midday = new Date('2026-10-11T07:00:00Z')
    vi.setSystemTime(midday)

    const summary = calculateDistrictWaktSummary(dhaka, '2026-10-11', midday)
    expect(summary.currentWakt).toBe('dhuhr')
    expect(summary.currentWaktTimeLeftSeconds).toBeGreaterThan(0)
    expect(summary.nextWakt.key).toBe('asr')
    expect(summary.nextWakt.secondsUntilStart).toBe(summary.currentWaktTimeLeftSeconds)

    // Check all 5 prayers status and seconds remaining
    expect(summary.prayers).toHaveLength(5)
    const [fajr, dhuhr, asr, maghrib, isha] = summary.prayers

    expect(fajr?.status).toBe('ended')
    expect(fajr?.secondsRemaining).toBe(0)

    expect(dhuhr?.status).toBe('current')
    expect(dhuhr?.secondsRemaining).toBe(summary.currentWaktTimeLeftSeconds)

    expect(asr?.status).toBe('upcoming')
    expect(asr?.secondsRemaining).toBeGreaterThan(0)

    expect(maghrib?.status).toBe('upcoming')
    expect(maghrib?.secondsRemaining).toBeGreaterThan(asr?.secondsRemaining || 0)

    expect(isha?.status).toBe('upcoming')
    expect(isha?.secondsRemaining).toBeGreaterThan(maghrib?.secondsRemaining || 0)
  })

  it('calculates Waqt remaining time when Isha is active after midnight', () => {
    const sylhet = findDistrict('36')!
    // 03:00 Bangladesh time (21:00 UTC on previous day)
    const midnightTime = new Date('2026-10-11T21:00:00Z')
    vi.setSystemTime(midnightTime)

    const summary = calculateDistrictWaktSummary(sylhet, '2026-10-12', midnightTime)
    expect(summary.currentWakt).toBe('isha')
    expect(summary.currentWaktTimeLeftSeconds).toBeGreaterThan(0)
    expect(summary.nextWakt.key).toBe('fajr')
    expect(summary.nextWakt.secondsUntilStart).toBe(summary.currentWaktTimeLeftSeconds)

    const fajr = summary.prayers.find(p => p.key === 'fajr')!
    expect(fajr.status).toBe('upcoming')
    expect(fajr.secondsRemaining).toBe(summary.currentWaktTimeLeftSeconds)

    const isha = summary.prayers.find(p => p.key === 'isha')!
    expect(isha.status).toBe('current')
    expect(isha.secondsRemaining).toBe(summary.currentWaktTimeLeftSeconds)
  })

  it('renders all 64 districts in AllDistrictsWaktTracker component', async () => {
    // 12:30 BD time (06:30 UTC)
    vi.setSystemTime(new Date('2026-10-11T06:30:00Z'))
    const wrapper = mount(AllDistrictsWaktTracker)

    const cards = wrapper.findAll('article')
    expect(cards).toHaveLength(64)

    // Check timer cleanup
    wrapper.unmount()
    expect(vi.getTimerCount()).toBe(0)
  })

  it('filters districts by search query in English and Bengali', async () => {
    vi.setSystemTime(new Date('2026-10-11T06:30:00Z'))
    const wrapper = mount(AllDistrictsWaktTracker)

    // Search in English
    const input = wrapper.find('input[type="search"]')
    await input.setValue('Sylhet')
    expect(wrapper.findAll('article')).toHaveLength(1)
    expect(wrapper.text()).toContain('Sylhet')

    // Search in Bengali
    await input.setValue('ঢাকা')
    expect(wrapper.findAll('article')).toHaveLength(1)
    expect(wrapper.text()).toContain('ঢাকা')

    // Unmatched query
    await input.setValue('NonExistentPlace')
    expect(wrapper.findAll('article')).toHaveLength(0)
    expect(wrapper.text()).toContain('No districts match your search.')
  })

  it('filters districts by administrative division', async () => {
    vi.setSystemTime(new Date('2026-10-11T06:30:00Z'))
    const wrapper = mount(AllDistrictsWaktTracker)

    // Find Sylhet division button (Sylhet division has 4 districts: Sylhet, Moulvibazar, Habiganj, Sunamganj)
    const divisionButtons = wrapper.findAll('div[role="group"] button')
    const sylhetBtn = divisionButtons.find(b => b.text().includes('Sylhet') || b.text().includes('সিলেট'))
    expect(sylhetBtn).toBeDefined()

    await sylhetBtn!.trigger('click')
    const cards = wrapper.findAll('article')
    expect(cards).toHaveLength(4)
  })

  it('allows user to set a district as active directly from the card', async () => {
    vi.setSystemTime(new Date('2026-10-11T06:30:00Z'))
    const timingStore = useTimingStore()
    expect(timingStore.districtId).toBe('')

    const wrapper = mount(AllDistrictsWaktTracker)

    // Find the first "Set as my district" button and click it
    const setBtn = wrapper.findAll('button').find(b => b.text().includes('Set as my district') || b.text().includes('আমার জেলা হিসেবে সেট করুন'))
    expect(setBtn).toBeDefined()

    await setBtn!.trigger('click')
    await nextTick()

    expect(timingStore.districtId).toBeTruthy()
    expect(timingStore.config).not.toBeNull()
  })

  it('supports Bengali localization in AllDistrictsWaktTracker', async () => {
    vi.setSystemTime(new Date('2026-10-11T06:30:00Z'))
    const localeStore = useLocaleStore()
    localeStore.setLocale('bn')

    const wrapper = mount(AllDistrictsWaktTracker)
    await nextTick()

    expect(wrapper.text()).toContain('চলমান ওয়াক্ত')
    expect(wrapper.text()).toContain('সকল ৬৪ জেলা')
    expect(wrapper.text()).toContain('ঢাকা')
  })
})
