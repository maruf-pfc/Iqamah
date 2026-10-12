import { describe, expect, it } from 'vitest'
import { calculateSchedule, cautionState } from '@/services/prayerTimes'

const schedule = calculateSchedule({ latitude: 23.7115253, longitude: 90.4111451, method: 'Karachi', madhab: 'Hanafi' }, '2026-10-13')
describe('approximate caution countdown', () => {
  it.each(schedule.zones)('uses start-inclusive, end-exclusive boundaries for $key', zone => {
    expect(cautionState(schedule, zone.start)?.active).toBe(true)
    expect(cautionState(schedule, new Date(zone.end.getTime() - 1))?.minutes).toBe(1)
    expect(cautionState(schedule, zone.end)?.active).not.toBe(true)
  })
  it('counts down until the next interval rather than showing minutes left prematurely', () => {
    const sunrise = schedule.zones[0]!
    const state = cautionState(schedule, new Date(sunrise.start.getTime() - 61000))
    expect(state?.minutes).toBe(2)
    expect(state?.active).toBe(false)
  })
  it('returns no stale countdown after the final interval', () => {
    expect(cautionState(schedule, schedule.zones[2]!.end)).toBeNull()
  })
})
