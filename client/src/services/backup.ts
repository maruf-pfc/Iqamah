import type { PrayerLogDto } from '@/types/prayer.types'
import { isCalendarDate } from './calendar'

function object(value: unknown): asserts value is Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid record.')
}
function enumValue(value: unknown, max: number): boolean {
  return typeof value === 'number' && Number.isInteger(value) && value >= 0 && value <= max
}
function timestamp(value: unknown): value is string {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(value) && isCalendarDate(value.slice(0, 10)) && Number.isFinite(Date.parse(value))
}
function id(value: unknown): boolean {
  // Older backups can contain non-UUID IDs. Preserve them rather than regenerate relationships.
  return typeof value === 'string' && value.length > 0 && value.length <= 128
}

export function validatePrayerRequest(value: unknown): void {
  object(value)
  if (!enumValue(value.prayerName, 4) || !isCalendarDate(value.prayerDate) || typeof value.isOffered !== 'boolean') throw new Error('Invalid prayer or date.')
  if (value.isOffered) {
    if (!enumValue(value.waqtStatus, 2) || value.missedReason != null) throw new Error('Offered prayers require punctuality and no missed reason.')
  } else if (!enumValue(value.missedReason, 5) || value.waqtStatus != null) {
    throw new Error('Missed prayers require a reason and no punctuality.')
  }
  if (value.isJummah === true && (value.prayerName !== 1 || !value.isOffered)) throw new Error('Jummah is only valid for offered Dhuhr.')
  for (const key of ['isJamaah', 'isTraveling', 'isJummah', 'isHome', 'hasTasbih']) {
    if (value[key] !== undefined && typeof value[key] !== 'boolean') throw new Error('Invalid prayer option.')
  }
  if (value.quranNotes !== undefined && typeof value.quranNotes !== 'string') throw new Error('Invalid notes.')
}

export function validateLogs(value: unknown): PrayerLogDto[] {
  if (!Array.isArray(value)) throw new Error('Invalid prayer records.')
  const ids = new Set<string>()
  const days = new Set<string>()
  const qazaIds = new Set<string>()
  for (const log of value) {
    object(log)
    validatePrayerRequest(log)
    if (!id(log.id) || typeof log.userId !== 'number' || !Number.isInteger(log.userId) || log.userId <= 0 || !timestamp(log.loggedAt)) throw new Error('Invalid record identity or timestamp.')
    if (log.waqtStatus === undefined || log.missedReason === undefined) throw new Error('Missing prayer classification.')
    for (const key of ['isJamaah', 'isTraveling', 'isJummah', 'isHome']) {
      if (typeof log[key] !== 'boolean') throw new Error('Missing prayer option.')
    }
    const key = `${log.prayerDate}:${log.prayerName}`
    if (ids.has(String(log.id)) || days.has(key)) throw new Error('Duplicate prayer record.')
    ids.add(String(log.id)); days.add(key)
    const requires = !log.isOffered && log.missedReason !== 0
    if (!requires && log.qazaLog !== null) throw new Error('Unexpected Qaza obligation.')
    if (requires) {
      const qaza = log.qazaLog
      object(qaza)
      if (!id(qaza.id) || qazaIds.has(String(qaza.id)) || qaza.prayerLogId !== log.id || qaza.userId !== log.userId || qaza.prayerName !== log.prayerName || qaza.originalPrayerDate !== log.prayerDate || !enumValue(qaza.state, 1) || !timestamp(qaza.createdAt)) throw new Error('Invalid Qaza relationship.')
      qazaIds.add(String(qaza.id))
      if (qaza.state === 0 && (qaza.fulfilledAt !== null || qaza.timeToResolutionSeconds !== null)) throw new Error('Invalid pending Qaza.')
      if (qaza.state === 1) {
        if (!timestamp(qaza.fulfilledAt) || typeof qaza.timeToResolutionSeconds !== 'number' || qaza.timeToResolutionSeconds < 0 || !Number.isFinite(qaza.timeToResolutionSeconds)) throw new Error('Invalid fulfilled Qaza.')
        const seconds = Math.floor((Date.parse(qaza.fulfilledAt) - Date.parse(String(qaza.createdAt))) / 1000)
        if (seconds < 0 || Math.abs(seconds - qaza.timeToResolutionSeconds) > 1) throw new Error('Invalid resolution duration.')
      }
    }
  }
  return value as PrayerLogDto[]
}

export function readLogs(): PrayerLogDto[] {
  const raw = localStorage.getItem('iqamah_prayer_logs')
  return raw ? validateLogs(JSON.parse(raw)) : []
}

function canonicalJSON(value: unknown): string {
  return JSON.stringify(value, (_key, entry: unknown) => {
    if (entry && typeof entry === 'object' && !Array.isArray(entry)) {
      const record = entry as Record<string, unknown>
      return Object.fromEntries(Object.keys(record).sort().map(key => [key, record[key]]))
    }
    return entry
  })
}

/** Validate everything before one storage write. Conflicts never silently replace current data. */
export function mergeBackup(current: PrayerLogDto[], backup: unknown): PrayerLogDto[] {
  object(backup)
  if (backup.version !== '1.1.0') throw new Error('Unsupported backup version.')
  const incoming = validateLogs(backup.prayerLogs)
  const merged = [...validateLogs(current)]
  for (const log of incoming) {
    const existing = merged.find(item => item.id === log.id || (item.prayerDate === log.prayerDate && item.prayerName === log.prayerName))
    if (existing) {
      if (canonicalJSON(existing) !== canonicalJSON(log)) throw new Error('Backup conflicts with existing records. Export current data before restoring on an empty installation.')
    } else merged.push(log)
  }
  return validateLogs(merged).sort((a, b) => a.prayerDate.localeCompare(b.prayerDate) || a.prayerName - b.prayerName)
}
