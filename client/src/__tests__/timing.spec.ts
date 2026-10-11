import { describe, expect, it } from 'vitest'
import { calculateSchedule, timingState, validConfig } from '@/services/prayerTimes'
import { localDate } from '@/services/calendar'

const config = { latitude: 23.7639, longitude: 90.3889, method: 'Karachi', madhab: 'Hanafi' } as const
describe('shared prayer calculation', () => {
  it('does not accept missing or invented configuration', () => {
    expect(validConfig(null)).toBe(false)
    expect(validConfig({ ...config, latitude: 91 })).toBe(false)
    expect(validConfig({ ...config, longitude: NaN })).toBe(false)
    expect(() => calculateSchedule(config, '2026-02-30')).toThrow('Invalid calculation inputs.')
  })
  it('calculates five chronological windows and tomorrow Fajr separately', () => {
    const schedule = calculateSchedule(config, '2026-01-01')
    expect(schedule.prayers).toHaveLength(5)
    schedule.prayers.forEach(p => expect(p.end.getTime()).toBeGreaterThan(p.start.getTime()))
    expect(schedule.tomorrowFajr.getTime()).toBe(calculateSchedule(config, '2026-01-02').prayers[0]!.start.getTime())
    expect(schedule.tomorrowFajr.getTime()).not.toBe(schedule.prayers[0]!.start.getTime() + 86400000)
  })
  it('changes current and upcoming prayer exactly at a boundary', () => {
    const schedule = calculateSchedule(config, '2026-10-11')
    const dhuhr = schedule.prayers[1]!
    expect(timingState(schedule, new Date(dhuhr.start.getTime() - 1000)).next.key).toBe('dhuhr')
    expect(timingState(schedule, dhuhr.start).current).toBe('dhuhr')
    expect(timingState(schedule, dhuhr.start).next.key).toBe('asr')
    expect(timingState(schedule, schedule.sunrise).current).toBeNull()
  })
  it('uses tomorrow astronomical Fajr after Isha and previous Isha before dawn', () => {
    const schedule = calculateSchedule(config, '2026-10-11')
    expect(timingState(schedule, schedule.prayers[4]!.start).next.start).toEqual(schedule.tomorrowFajr)
    const dawn = schedule.prayers[0]!.start
    expect(timingState(schedule, new Date(dawn.getTime() - 60000)).current).toBe('isha')
  })
  it('uses local calendar formatting', () => {
    expect(localDate(new Date(2026, 9, 11, 0, 1))).toBe('2026-10-11')
  })
})
