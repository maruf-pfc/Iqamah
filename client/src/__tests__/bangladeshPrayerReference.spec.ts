import { describe, expect, it } from 'vitest'
import { districts, findDistrict } from '@/data/districts'
import { calculateDistrictWaktSummary, calculateSchedule } from '@/services/prayerTimes'

describe('Bangladesh prayer calculation accuracy and domain verification', () => {
  it('ensures all 64 districts have valid coordinates within Bangladesh geographic bounds', () => {
    expect(districts.length).toBe(64)
    for (const d of districts) {
      // Bangladesh latitude spans approximately 20.5° N to 26.65° N
      expect(d.latitude).toBeGreaterThan(20.5)
      expect(d.latitude).toBeLessThan(27.0)
      // Bangladesh longitude spans approximately 88.0° E to 92.7° E
      expect(d.longitude).toBeGreaterThan(88.0)
      expect(d.longitude).toBeLessThan(93.0)
      expect(d.name.length).toBeGreaterThan(0)
      expect(d.bnName.length).toBeGreaterThan(0)
      expect(d.division.length).toBeGreaterThan(0)
    }
  })

  it('calculates strictly ordered prayer times for Dhaka across summer and winter dates', () => {
    const dhaka = findDistrict('47')!
    expect(dhaka).toBeDefined()
    expect(dhaka.name).toBe('Dhaka')

    const testDates = ['2026-06-21', '2026-12-21', '2026-03-21', '2026-09-23']
    for (const dateStr of testDates) {
      const schedule = calculateSchedule({
        latitude: dhaka.latitude,
        longitude: dhaka.longitude,
        method: 'Karachi',
        madhab: 'Hanafi',
      }, dateStr)

      // Time order must be strictly: Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha
      const fajr = schedule.prayers[0]!.start.getTime()
      const dhuhr = schedule.prayers[1]!.start.getTime()
      const asr = schedule.prayers[2]!.start.getTime()
      const maghrib = schedule.prayers[3]!.start.getTime()
      const isha = schedule.prayers[4]!.start.getTime()
      const sunrise = schedule.sunrise.getTime()

      expect(fajr).toBeLessThan(sunrise)
      expect(sunrise).toBeLessThan(dhuhr)
      expect(dhuhr).toBeLessThan(asr)
      expect(asr).toBeLessThan(maghrib)
      expect(maghrib).toBeLessThan(isha)

      // Verify caution intervals (forbidden zones)
      expect(schedule.zones.length).toBe(3)
      // Sunrise zone: starts at sunrise, lasts 15 mins
      expect(schedule.zones[0]?.start.getTime()).toBe(sunrise)
      expect(schedule.zones[0]?.end.getTime()).toBe(sunrise + 15 * 60000)
      // Solar noon zone: ends at Dhuhr
      expect(schedule.zones[1]?.end.getTime()).toBe(dhuhr)
      // Sunset zone: ends at Maghrib
      expect(schedule.zones[2]?.end.getTime()).toBe(maghrib)
    }
  })

  it('reflects longitudinal time variation from easternmost to westernmost districts', () => {
    // Rangamati/Bandarban is eastern (~92.2° E), Chapainawabganj is western (~88.3° E)
    // 1° of longitude corresponds to ~4 minutes of solar time.
    // Difference between 92.2° and 88.3° is ~3.9° -> ~15-16 minutes earlier sunset in Rangamati than Chapainawabganj!
    const rangamati = findDistrict('4')!
    const chapai = findDistrict('18')!

    const dateStr = '2026-03-21'
    const eastSched = calculateSchedule({ latitude: rangamati.latitude, longitude: rangamati.longitude, method: 'Karachi', madhab: 'Hanafi' }, dateStr)
    const westSched = calculateSchedule({ latitude: chapai.latitude, longitude: chapai.longitude, method: 'Karachi', madhab: 'Hanafi' }, dateStr)

    const eastMaghrib = eastSched.prayers.find(p => p.key === 'maghrib')!.start.getTime()
    const westMaghrib = westSched.prayers.find(p => p.key === 'maghrib')!.start.getTime()

    // Eastern district sunset occurs BEFORE western district sunset
    expect(eastMaghrib).toBeLessThan(westMaghrib)
    const diffMinutes = (westMaghrib - eastMaghrib) / 60000
    expect(diffMinutes).toBeGreaterThan(10)
    expect(diffMinutes).toBeLessThan(20)
  })

  it('calculates 64-district summary with accurate Waqt status and countdowns', () => {
    const sylhet = findDistrict('36')!
    const now = new Date('2026-10-11T12:00:00+06:00')
    const summary = calculateDistrictWaktSummary(sylhet, '2026-10-11', now)

    expect(summary.district.name).toBe('Sylhet')
    expect(summary.prayers.length).toBe(5)
    expect(summary.nextWakt).toBeDefined()
    expect(summary.nextWakt.secondsUntilStart).toBeGreaterThanOrEqual(0)
  })
})
