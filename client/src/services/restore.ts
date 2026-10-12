import { extractPreferences, mergeBackup, migrateBackup, readLogs, validateLogs } from './backup'
import { findDistrict } from '@/data/districts'
import { validConfig, type TimingConfig } from './prayerTimes'

const journalKey = 'iqamah_restore_journal'
const keys = ['iqamah_prayer_logs', 'iqamah_locale', 'iqamah_theme', 'iqamah_user_g', 'iqamah_user_name', 'iqamah_timing_config'] as const
type Snapshot = Record<typeof keys[number], string | null>

function apply(snapshot: Snapshot) {
  for (const key of keys) {
    const value = snapshot[key]
    if (value === null) localStorage.removeItem(key)
    else localStorage.setItem(key, value)
    if (localStorage.getItem(key) !== value) throw new Error('Storage verification failed.')
  }
}

/** Run before stores initialize. A journal always represents the previous dataset. */
export function recoverRestore() {
  const raw = localStorage.getItem(journalKey)
  if (!raw) return
  const snapshot: unknown = JSON.parse(raw)
  if (!snapshot || typeof snapshot !== 'object') throw new Error('Invalid recovery journal.')
  for (const key of keys) {
    const value = (snapshot as Record<string, unknown>)[key]
    if (value !== null && typeof value !== 'string') throw new Error('Invalid recovery journal.')
  }
  apply(snapshot as Snapshot)
  localStorage.removeItem(journalKey)
}

export function previewRestore(backup: unknown, mode: 'merge' | 'replace') {
  const migrated = migrateBackup(backup)
  const logs = mode === 'merge' ? mergeBackup(readLogs(), backup) : validateLogs(migrated.prayerLogs)
  const preferences = extractPreferences(backup)
  return { logs, preferences }
}

/** Synchronous, recoverable multi-key transaction; no asynchronous writes between keys. */
export function restoreBackup(backup: unknown, mode: 'merge' | 'replace') {
  recoverRestore()
  const { logs, preferences: prefs } = previewRestore(backup, mode)
  const before = Object.fromEntries(keys.map(key => [key, localStorage.getItem(key)])) as Snapshot
  const after = { ...before, iqamah_prayer_logs: JSON.stringify(logs) }
  // Merge adds records only; it never changes the active user's preferences.
  if (mode === 'replace' && prefs) {
    for (const [field, key] of [['language', 'iqamah_locale'], ['theme', 'iqamah_theme'], ['username', 'iqamah_user_name']] as const) {
      if (typeof prefs[field] === 'string') after[key] = prefs[field]
    }
    if (prefs.gender) after.iqamah_user_g = prefs.gender === 'female' ? 'f' : 'm'
    let previous: TimingConfig | undefined
    try {
      const saved: unknown = JSON.parse(before.iqamah_timing_config ?? 'null')
      if (validConfig(saved)) previous = saved
    } catch { /* A complete incoming config can replace damaged settings. */ }
    if (prefs.districtId === '') after.iqamah_timing_config = null
    else if (prefs.districtId !== undefined || prefs.method !== undefined || prefs.madhab !== undefined) {
      const district = findDistrict(prefs.districtId ?? previous?.districtId ?? '')
      const method = prefs.method ?? previous?.method
      const madhab = prefs.madhab ?? previous?.madhab
      if (!district || !method || !madhab) throw new Error('Partial timing preferences require an existing valid location and convention.')
      after.iqamah_timing_config = JSON.stringify({ latitude: district.latitude, longitude: district.longitude, districtId: district.id, method, madhab })
    }
  }
  localStorage.setItem(journalKey, JSON.stringify(before))
  try {
    apply(after)
    localStorage.removeItem(journalKey)
  } catch (error) {
    // If rollback also fails, retain the journal and prevent startup until recovery succeeds.
    recoverRestore()
    throw error
  }
  return logs.length
}
