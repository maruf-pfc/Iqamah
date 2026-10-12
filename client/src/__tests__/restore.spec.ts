import { beforeEach, describe, expect, it, vi } from 'vitest'
import sqlite from './fixtures/sqlite-v1.json'
import webV1 from './fixtures/web-v1.1.0.json'
import webV2 from './fixtures/web-v2.0.0.json'
import { extractPreferences, migrateBackup, readLogs, validateLogs } from '@/services/backup'
import { previewRestore, recoverRestore, restoreBackup } from '@/services/restore'
import { createPinia, setActivePinia } from 'pinia'
import { usePrayerStore } from '@/stores/prayer'

const current = () => ({ version: '2.0.0', exportedAt: '2026-10-13T12:00:00Z', prayerLogs: validateLogs(migrateBackup(sqlite).prayerLogs), preferences: { language: 'bn', theme: 'light', districtId: '47', method: 'Karachi', madhab: 'Hanafi', username: 'পরীক্ষা' } })

describe('recoverable restore', () => {
  beforeEach(() => { vi.restoreAllMocks(); localStorage.clear(); setActivePinia(createPinia()) })
  it.each([webV1, webV2])('imports documented web fixture $version and retains prayer metadata', fixture => {
    restoreBackup(fixture, 'replace')
    expect(readLogs()[0]?.hasTasbih).toBe(true)
    expect(readLogs()[0]?.isJamaah).toBe(true)
    expect(readLogs()[0]?.quranNotes).toBe('কুরআন নোট')
    expect(localStorage.getItem('iqamah_user_g')).toBe('f')
  })
  it('migrates actual SQLite column names without changing IDs, Unicode notes or fulfillment', () => {
    restoreBackup(sqlite, 'replace')
    expect(readLogs()[0]?.quranNotes).toBe('ব্যক্তিগত নোট — إقامة')
    expect(readLogs()[0]?.qazaLog?.id).toBe('legacy-qaza')
    expect(readLogs()[0]?.qazaLog?.state).toBe(1)
    expect(extractPreferences(sqlite)).toEqual({})
  })
  it('rejects missing sections, coercible booleans, duplicates and orphan Qaza', () => {
    expect(() => previewRestore({ version: 1 }, 'replace')).toThrow('Missing prayer records')
    expect(() => previewRestore({ ...sqlite, prayer_logs: [{ ...sqlite.prayer_logs[0], isOffered: 'false' }] }, 'replace')).toThrow('Invalid SQLite boolean')
    expect(() => previewRestore({ ...sqlite, qaza_logs: [...sqlite.qaza_logs, ...sqlite.qaza_logs] }, 'replace')).toThrow('Invalid or duplicate Qaza relationship')
    expect(() => previewRestore({ ...sqlite, prayer_logs: [] }, 'replace')).toThrow('Orphan')
  })
  it('validates preferences before any writes', () => {
    localStorage.setItem('iqamah_prayer_logs', '[]')
    expect(() => restoreBackup({ ...current(), preferences: { districtId: 'invalid' } }, 'replace')).toThrow('Invalid backup district')
    expect(localStorage.getItem('iqamah_prayer_logs')).toBe('[]')
    expect(localStorage.getItem('iqamah_restore_journal')).toBeNull()
  })
  it('round trips records and settings; repeat merge is idempotent and keeps preferences', () => {
    restoreBackup(current(), 'replace')
    expect(localStorage.getItem('iqamah_locale')).toBe('bn')
    expect(localStorage.getItem('iqamah_user_name')).toBe('পরীক্ষা')
    expect(JSON.parse(localStorage.getItem('iqamah_timing_config')!).districtId).toBe('47')
    restoreBackup({ ...current(), preferences: { language: 'en' } }, 'merge')
    expect(readLogs()).toHaveLength(1)
    expect(localStorage.getItem('iqamah_locale')).toBe('bn')
  })
  it('rolls back all keys after a mid-commit I/O failure', () => {
    localStorage.setItem('iqamah_prayer_logs', '[]')
    localStorage.setItem('iqamah_locale', 'en')
    const original = Storage.prototype.setItem
    let failed = false
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(function (this: Storage, key, value) {
      if (key === 'iqamah_theme' && !failed) { failed = true; throw new Error('Disk full') }
      original.call(this, key, value)
    })
    expect(() => restoreBackup(current(), 'replace')).toThrow('Disk full')
    expect(readLogs()).toEqual([])
    expect(localStorage.getItem('iqamah_locale')).toBe('en')
    expect(localStorage.getItem('iqamah_restore_journal')).toBeNull()
  })
  it('recovers an interrupted transaction before reading records', () => {
    const keys = ['iqamah_prayer_logs', 'iqamah_locale', 'iqamah_theme', 'iqamah_user_g', 'iqamah_user_name', 'iqamah_timing_config']
    localStorage.setItem('iqamah_restore_journal', JSON.stringify(Object.fromEntries(keys.map(key => [key, key === 'iqamah_prayer_logs' ? '[]' : null]))))
    localStorage.setItem('iqamah_prayer_logs', JSON.stringify(current().prayerLogs))
    recoverRestore()
    expect(readLogs()).toEqual([])
  })
  it('retains a recovery journal and blocks record access if rollback also fails', () => {
    localStorage.setItem('iqamah_prayer_logs', '[]')
    const original = Storage.prototype.setItem
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(function (this: Storage, key, value) {
      if (key === 'iqamah_prayer_logs') throw new Error('Persistent I/O failure')
      original.call(this, key, value)
    })
    expect(() => restoreBackup(current(), 'replace')).toThrow('Persistent I/O failure')
    expect(localStorage.getItem('iqamah_restore_journal')).not.toBeNull()
    expect(() => readLogs()).toThrow('Data recovery pending')
    vi.restoreAllMocks()
    recoverRestore()
    expect(readLogs()).toEqual([])
  })
  it.each(['1', '1.0.0', '1.1.0', '2.0.0'])('imports canonical schema alias %s without inventing preferences', version => {
    restoreBackup({ version, exportedAt: current().exportedAt, prayerLogs: current().prayerLogs, preferences: version === '2.0.0' ? {} : undefined }, 'replace')
    expect(readLogs()).toHaveLength(1)
    expect(localStorage.getItem('iqamah_locale')).toBeNull()
  })
  it('rejects future versions and invalid enum values without writes', () => {
    expect(() => restoreBackup({ ...current(), version: '9.0.0' }, 'replace')).toThrow('Unsupported backup version')
    expect(() => restoreBackup({ ...current(), prayerLogs: [{ ...current().prayerLogs[0], missedReason: 99 }] }, 'replace')).toThrow('Missed prayers require a reason')
    expect(localStorage.getItem('iqamah_prayer_logs')).toBeNull()
  })
  it('restores partial calculation fields independently while preserving omitted fields', () => {
    restoreBackup(current(), 'replace')
    restoreBackup({ ...current(), preferences: { method: 'Egyptian' } }, 'replace')
    restoreBackup({ ...current(), preferences: { districtId: '1' } }, 'replace')
    const saved = JSON.parse(localStorage.getItem('iqamah_timing_config')!)
    expect(saved.method).toBe('Egyptian')
    expect(saved.madhab).toBe('Hanafi')
    expect(saved.districtId).toBe('1')
  })
  it('rejects incomplete calculation settings on empty storage instead of inventing defaults', () => {
    expect(() => restoreBackup({ ...current(), preferences: { districtId: '47' } }, 'replace')).toThrow('Partial timing preferences')
    expect(localStorage.getItem('iqamah_prayer_logs')).toBeNull()
  })
  it('preserves imported ownership and metadata through later edits and fulfillment', async () => {
    const migrated = validateLogs(migrateBackup(sqlite).prayerLogs)[0]!
    const log = { ...migrated, userId: 7, qazaLog: { ...migrated.qazaLog!, userId: 7, state: 0, fulfilledAt: null, timeToResolutionSeconds: null } }
    restoreBackup({ ...current(), prayerLogs: [log], preferences: {} }, 'replace')
    await usePrayerStore().logPrayer({ prayerName: 0, prayerDate: log.prayerDate, isOffered: false, missedReason: 1 })
    await usePrayerStore().fulfillQaza('legacy-qaza')
    expect(readLogs()[0]?.userId).toBe(7)
    expect(readLogs()[0]?.qazaLog?.userId).toBe(7)
    expect(JSON.parse(localStorage.getItem('iqamah_prayer_logs')!)[0].updatedAt).toBe(sqlite.prayer_logs[0]!.updatedAt)
  })
})
