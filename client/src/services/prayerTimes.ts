import { CalculationMethod, Coordinates, Madhab, PrayerTimes } from 'adhan'
import { isCalendarDate } from './calendar'

export const prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'] as const
export const methods = ['Karachi', 'MuslimWorldLeague', 'Egyptian', 'NorthAmerica', 'UmmAlQura', 'Dubai', 'Singapore'] as const
export interface TimingConfig {
  latitude: number
  longitude: number
  method: typeof methods[number]
  madhab: 'Hanafi' | 'Shafi'
  districtId?: string
}

export function validConfig(value: unknown): value is TimingConfig {
  if (!value || typeof value !== 'object') return false
  const c = value as TimingConfig
  return Number.isFinite(c.latitude) && Math.abs(c.latitude) <= 90 && Number.isFinite(c.longitude) && Math.abs(c.longitude) <= 180 && methods.includes(c.method) && ['Hanafi', 'Shafi'].includes(c.madhab)
}

export function calculateSchedule(config: TimingConfig, dateString: string) {
  if (!validConfig(config) || !isCalendarDate(dateString)) throw new Error('Invalid calculation inputs.')
  const date = new Date(`${dateString}T12:00:00`)
  const nextDate = new Date(date)
  nextDate.setDate(date.getDate() + 1)
  const previousDate = new Date(date)
  previousDate.setDate(date.getDate() - 1)
  const params = CalculationMethod[config.method]()
  params.madhab = Madhab[config.madhab]
  const coords = new Coordinates(config.latitude, config.longitude)
  const today = new PrayerTimes(coords, date, params)
  const tomorrow = new PrayerTimes(coords, nextDate, params)
  const yesterday = new PrayerTimes(coords, previousDate, params)
  const ends = [today.sunrise, today.asr, today.maghrib, today.isha, tomorrow.fajr]
  const prayers = prayerKeys.map((key, index) => ({ key, start: today[key], end: ends[index]! }))
  if ([today.sunrise, tomorrow.fajr, yesterday.isha, ...prayers.flatMap(p => [p.start, p.end])].some(time => !Number.isFinite(time.getTime()))) throw new Error('Prayer times cannot be calculated for these inputs.')
  return {
    prayers,
    sunrise: today.sunrise,
    tomorrowFajr: tomorrow.fajr,
    previousIsha: yesterday.isha,
    // Preserve existing approximate advisory windows; these are not universal religious rulings.
    zones: [
      { key: 'sunrise' as const, start: today.sunrise, end: new Date(today.sunrise.getTime() + 15 * 60000) },
      { key: 'solar_noon' as const, start: new Date(today.dhuhr.getTime() - 10 * 60000), end: today.dhuhr },
      { key: 'sunset' as const, start: new Date(today.maghrib.getTime() - 20 * 60000), end: today.maghrib },
    ],
  }
}

export function timingState(schedule: ReturnType<typeof calculateSchedule>, now: Date) {
  const next = schedule.prayers.find(p => p.start > now) ?? { key: 'fajr' as const, start: schedule.tomorrowFajr }
  const current = schedule.prayers.find(p => now >= p.start && now < p.end)?.key
    ?? (now >= schedule.previousIsha && now < schedule.prayers[0]!.start ? 'isha' : null)
  return { next, current, seconds: Math.max(0, Math.ceil((next.start.getTime() - now.getTime()) / 1000)) }
}

/** Approximate advisory only: an active interval takes priority over the next one. */
export function cautionState(schedule: ReturnType<typeof calculateSchedule>, now: Date) {
  const zone = schedule.zones.find(zone => now >= zone.start && now < zone.end)
    ?? schedule.zones.find(zone => zone.start > now)
  if (!zone) return null
  const active = now >= zone.start && now < zone.end
  return { zone, active, minutes: Math.max(1, Math.ceil(((active ? zone.end : zone.start).getTime() - now.getTime()) / 60000)) }
}

export interface DistrictWaktPrayer {
  key: typeof prayerKeys[number]
  start: Date
  end: Date
  status: 'current' | 'upcoming' | 'ended'
  secondsRemaining: number
}

export interface DistrictWaktSummary {
  district: {
    id: string
    name: string
    bnName: string
    latitude: number
    longitude: number
    division?: string
    divisionBn?: string
  }
  schedule: ReturnType<typeof calculateSchedule>
  currentWakt: typeof prayerKeys[number] | null
  currentWaktEnd: Date | null
  currentWaktTimeLeftSeconds: number
  nextWakt: {
    key: typeof prayerKeys[number]
    start: Date
    secondsUntilStart: number
  }
  prayers: DistrictWaktPrayer[]
}

export function calculateDistrictWaktSummary(
  district: { id: string; name: string; bnName: string; latitude: number; longitude: number; division?: string; divisionBn?: string },
  dateString: string,
  now: Date,
  config?: Partial<TimingConfig>,
): DistrictWaktSummary {
  const schedule = calculateSchedule({
    latitude: district.latitude,
    longitude: district.longitude,
    method: config?.method ?? 'Karachi',
    madhab: config?.madhab ?? 'Hanafi',
    districtId: district.id,
  }, dateString)

  const ishaOngoingPastMidnight = now >= schedule.previousIsha && now < schedule.prayers[0]!.start

  let currentWakt: typeof prayerKeys[number] | null = null
  let currentWaktEnd: Date | null = null
  let currentWaktTimeLeftSeconds = 0

  if (ishaOngoingPastMidnight) {
    currentWakt = 'isha'
    currentWaktEnd = schedule.prayers[0]!.start
    currentWaktTimeLeftSeconds = Math.max(0, Math.ceil((currentWaktEnd.getTime() - now.getTime()) / 1000))
  } else {
    const cur = schedule.prayers.find(p => now >= p.start && now < p.end)
    if (cur) {
      currentWakt = cur.key
      currentWaktEnd = cur.end
      currentWaktTimeLeftSeconds = Math.max(0, Math.ceil((cur.end.getTime() - now.getTime()) / 1000))
    }
  }

  const nextPrayerItem = schedule.prayers.find(p => p.start > now) ?? { key: 'fajr' as const, start: schedule.tomorrowFajr }
  const nextWakt = {
    key: nextPrayerItem.key,
    start: nextPrayerItem.start,
    secondsUntilStart: Math.max(0, Math.ceil((nextPrayerItem.start.getTime() - now.getTime()) / 1000)),
  }

  const prayers: DistrictWaktPrayer[] = schedule.prayers.map(p => {
    let status: 'current' | 'upcoming' | 'ended' = 'ended'
    let secondsRemaining = 0

    if (p.key === 'isha' && ishaOngoingPastMidnight) {
      status = 'current'
      secondsRemaining = currentWaktTimeLeftSeconds
    } else if (now >= p.start && now < p.end) {
      status = 'current'
      secondsRemaining = Math.max(0, Math.ceil((p.end.getTime() - now.getTime()) / 1000))
    } else if (now < p.start) {
      status = 'upcoming'
      secondsRemaining = Math.max(0, Math.ceil((p.start.getTime() - now.getTime()) / 1000))
    } else {
      status = 'ended'
      secondsRemaining = 0
    }

    return {
      key: p.key,
      start: p.start,
      end: p.end,
      status,
      secondsRemaining,
    }
  })

  return {
    district,
    schedule,
    currentWakt,
    currentWaktEnd,
    currentWaktTimeLeftSeconds,
    nextWakt,
    prayers,
  }
}
