import type { PrayerLogDto } from '@/types/prayer.types'
import { isCalendarDate } from './calendar'
import { methods, type TimingConfig } from './prayerTimes'
import { findDistrict } from '@/data/districts'

export const CURRENT_BACKUP_VERSION = '2.0.0'
export const SUPPORTED_BACKUP_VERSIONS = ['1', '1.0.0', '1.1.0', '2.0.0']
export const APP_VERSION = '1.1.4-beta.1'

export interface BackupPreferences {
  username?: string
  language?: 'en' | 'bn'
  theme?: 'light' | 'dark'
  gender?: 'male' | 'female'
  districtId?: string
  method?: TimingConfig['method']
  madhab?: TimingConfig['madhab']
}

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

/** Migration from v1 format (both web v1.1.0 and mobile SQLite v1) to schema v2.0.0. */
function migrateV1ToV2(data: Record<string, unknown>): Record<string, unknown> {
  if (data.preferences !== undefined) object(data.preferences)
  let logs: unknown[]
  if (Array.isArray(data.prayerLogs)) {
    logs = data.prayerLogs
  } else if (Array.isArray(data.prayer_logs)) {
    // SQLite table names are snake_case; column names are camelCase.
    if (!Array.isArray(data.qaza_logs)) throw new Error('Missing Qaza records.')
    const qazaList = data.qaza_logs
    const qazaByPrayerLogId = new Map<string, Record<string, unknown>>()
    for (const q of qazaList) {
      object(q)
      if (typeof q.prayerLogId !== 'string' || qazaByPrayerLogId.has(q.prayerLogId)) throw new Error('Invalid or duplicate Qaza relationship.')
      qazaByPrayerLogId.set(q.prayerLogId, q)
    }
    logs = data.prayer_logs.map(row => {
      object(row)
      const qazaRow = typeof row.id === 'string' ? qazaByPrayerLogId.get(row.id) : undefined
      if (typeof row.id === 'string') qazaByPrayerLogId.delete(row.id)
      const flags = Object.fromEntries(['isOffered', 'isJamaah', 'isTraveling', 'isJummah', 'isHome', 'hasTasbih'].map(key => {
        if (row[key] !== 0 && row[key] !== 1) throw new Error('Invalid SQLite boolean.')
        return [key, row[key] === 1]
      }))
      return {
        ...row, ...flags,
        ...(row.quranNotes === null ? { quranNotes: undefined } : {}),
        qazaLog: qazaRow ?? null,
      }
    })
    if (qazaByPrayerLogId.size) throw new Error('Orphan Qaza records.')
  } else throw new Error('Missing prayer records.')

  return {
    version: CURRENT_BACKUP_VERSION,
    exportedAt: data.exportedAt,
    appVersion: APP_VERSION,
    prayerLogs: logs,
    // Historical files did not contain full preferences. Never invent them.
    preferences: { ...(data.preferences as Record<string, unknown> | undefined), ...Object.fromEntries(['username', 'language', 'theme', 'gender', 'districtId', 'method', 'madhab'].filter(key => data[key] !== undefined).map(key => [key, data[key]])) },
  }
}

/** Detect and migrate a backup to the current schema version. */
export function migrateBackup(data: unknown): Record<string, unknown> {
  object(data)
  const rawVersion = data.version
  let version: string
  if (typeof rawVersion === 'number') version = String(rawVersion)
  else if (typeof rawVersion === 'string') version = rawVersion
  else throw new Error('Backup is missing a version.')
  if (!SUPPORTED_BACKUP_VERSIONS.includes(version)) throw new Error('Unsupported backup version.')
  if (data.exportedAt !== undefined && !timestamp(data.exportedAt)) throw new Error('Invalid export timestamp.')
  if (version === '2.0.0') {
    if (!timestamp(data.exportedAt)) throw new Error('Missing or invalid export timestamp.')
    object(data.preferences)
    return data
  }
  return migrateV1ToV2(data)
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
    if (log.updatedAt !== undefined && !timestamp(log.updatedAt)) throw new Error('Invalid update timestamp.')
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
  if (localStorage.getItem('iqamah_restore_journal')) throw new Error('Data recovery pending. Reopen the app; do not clear storage.')
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
  const migrated = migrateBackup(backup)
  const incoming = validateLogs(migrated.prayerLogs)
  const merged = [...validateLogs(current)]
  for (const log of incoming) {
    const existing = merged.find(item => item.id === log.id || (item.prayerDate === log.prayerDate && item.prayerName === log.prayerName))
    if (existing) {
      if (canonicalJSON(existing) !== canonicalJSON(log)) throw new Error('Backup conflicts with existing records. Export current data before restoring on an empty installation.')
    } else merged.push(log)
  }
  return validateLogs(merged).sort((a, b) => a.prayerDate.localeCompare(b.prayerDate) || a.prayerName - b.prayerName)
}

/** Extract and validate preferences from a migrated backup. */
export function extractPreferences(backup: unknown): BackupPreferences | null {
  const migrated = migrateBackup(backup)
  const prefs = migrated.preferences
  if (prefs === undefined) return null
  object(prefs)
  if (prefs.username !== undefined && (typeof prefs.username !== 'string' || prefs.username.length > 200)) throw new Error('Invalid backup profile.')
  for (const [key, options] of Object.entries({ language: ['en', 'bn'], theme: ['light', 'dark'], gender: ['male', 'female'], method: methods, madhab: ['Hanafi', 'Shafi'] })) {
    if (prefs[key] !== undefined && !(options as readonly unknown[]).includes(prefs[key])) throw new Error('Invalid backup preferences.')
  }
  if (prefs.districtId !== undefined && prefs.districtId !== '' && (typeof prefs.districtId !== 'string' || !findDistrict(prefs.districtId))) throw new Error('Invalid backup district.')
  return prefs as BackupPreferences
}
