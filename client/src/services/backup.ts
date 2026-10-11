import type { PrayerLogDto } from '@/types/prayer.types'
import { isCalendarDate } from './calendar'

export const CURRENT_BACKUP_VERSION = '2.0.0'
export const SUPPORTED_BACKUP_VERSIONS = ['1', '1.0.0', '1.1.0', '2.0.0']
export const APP_VERSION = '1.1.4-beta.1'

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
  let logs: unknown[] = []
  if (Array.isArray(data.prayerLogs)) {
    logs = data.prayerLogs
  } else if (Array.isArray(data.prayer_logs)) {
    // Map SQLite snake_case records into canonical PrayerLogDto format
    const qazaList = Array.isArray(data.qaza_logs) ? (data.qaza_logs as Record<string, unknown>[]) : []
    const qazaByPrayerLogId = new Map<string, Record<string, unknown>>()
    for (const q of qazaList) {
      if (q && typeof q.prayerLogId === 'string') {
        qazaByPrayerLogId.set(q.prayerLogId, q)
      }
    }

    logs = (data.prayer_logs as Record<string, unknown>[]).map(row => {
      const qazaRow = qazaByPrayerLogId.get(String(row.id))
      return {
        id: String(row.id),
        userId: Number(row.userId ?? row.user_id ?? 1),
        prayerName: Number(row.prayerName ?? row.prayer_name ?? 0),
        prayerDate: String(row.prayerDate ?? row.prayer_date ?? ''),
        isOffered: Boolean(row.isOffered ?? row.is_offered),
        waqtStatus: row.waqtStatus != null ? Number(row.waqtStatus) : (row.waqt_status != null ? Number(row.waqt_status) : null),
        missedReason: row.missedReason != null ? Number(row.missedReason) : (row.missed_reason != null ? Number(row.missed_reason) : null),
        isJamaah: Boolean(row.isJamaah ?? row.is_jamaah),
        isTraveling: Boolean(row.isTraveling ?? row.is_traveling),
        isJummah: Boolean(row.isJummah ?? row.is_jummah),
        isHome: Boolean(row.isHome ?? row.is_home),
        hasTasbih: Boolean(row.hasTasbih ?? row.has_tasbih),
        quranNotes: typeof (row.quranNotes ?? row.quran_notes) === 'string' ? String(row.quranNotes ?? row.quran_notes) : undefined,
        loggedAt: String(row.loggedAt ?? row.logged_at ?? new Date().toISOString()),
        updatedAt: String(row.updatedAt ?? row.updated_at ?? new Date().toISOString()),
        qazaLog: qazaRow ? {
          id: String(qazaRow.id),
          prayerLogId: String(row.id),
          userId: Number(qazaRow.userId ?? row.userId ?? 1),
          prayerName: Number(qazaRow.prayerName ?? row.prayerName ?? 0),
          originalPrayerDate: String(qazaRow.originalPrayerDate ?? row.prayerDate ?? ''),
          state: Number(qazaRow.state ?? 0),
          createdAt: String(qazaRow.createdAt ?? row.loggedAt ?? new Date().toISOString()),
          fulfilledAt: qazaRow.fulfilledAt ? String(qazaRow.fulfilledAt) : null,
          timeToResolutionSeconds: qazaRow.timeToResolutionSeconds != null ? Number(qazaRow.timeToResolutionSeconds) : null,
        } : null,
      }
    })
  }

  return {
    version: CURRENT_BACKUP_VERSION,
    exportedAt: data.exportedAt ?? new Date().toISOString(),
    appVersion: APP_VERSION,
    prayerLogs: logs,
    preferences: {
      language: data.language === 'bn' ? 'bn' : 'en',
      theme: data.theme === 'light' ? 'light' : 'dark',
      gender: data.gender === 'female' ? 'female' : 'male',
      districtId: typeof data.districtId === 'string' ? data.districtId : undefined,
      method: typeof data.method === 'string' ? data.method : 'Karachi',
      madhab: data.madhab === 'Shafi' ? 'Shafi' : 'Hanafi',
    },
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
  if (version === '2.0.0') return data
  return migrateV1ToV2(data)
}

/** Compute a simple checksum for backup integrity verification (not encryption). */
export function backupChecksum(data: Record<string, unknown>): string {
  const json = JSON.stringify(data)
  let hash = 0
  for (let i = 0; i < json.length; i++) {
    const char = json.charCodeAt(i)
    hash = ((hash << 5) - hash + char) | 0
  }
  return hash.toString(16).padStart(8, '0')
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
export function extractPreferences(backup: unknown): Record<string, unknown> | null {
  const migrated = migrateBackup(backup)
  return (migrated.preferences as Record<string, unknown>) ?? null
}
