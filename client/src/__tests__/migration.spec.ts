import { describe, expect, it } from 'vitest'
import { CURRENT_BACKUP_VERSION, mergeBackup, migrateBackup } from '@/services/backup'

describe('backup migration and backward compatibility', () => {
  it('migrates a mobile SQLite v1 format to current v2 schema', () => {
    const mobileV1 = {
      version: 1,
      exportedAt: '2026-10-11T12:00:00.000Z',
      prayer_logs: [
        {
          id: 'test-log-1',
          userId: 1,
          prayerName: 0,
          prayerDate: '2026-10-11',
          isOffered: 0,
          waqtStatus: null,
          missedReason: 1,
          isJamaah: 0,
          isTraveling: 0,
          isJummah: 0,
          isHome: 1,
          hasTasbih: 0,
          quranNotes: 'Ayatul Kursi',
          loggedAt: '2026-10-11T12:05:00.000Z',
          updatedAt: '2026-10-11T12:05:00.000Z',
        },
      ],
      qaza_logs: [
        {
          id: 'test-qaza-1',
          prayerLogId: 'test-log-1',
          userId: 1,
          prayerName: 0,
          originalPrayerDate: '2026-10-11',
          state: 0,
          createdAt: '2026-10-11T12:05:00.000Z',
          fulfilledAt: null,
          timeToResolutionSeconds: null,
        },
      ],
    }

    const migrated = migrateBackup(mobileV1)
    expect(migrated.version).toBe(CURRENT_BACKUP_VERSION)
    expect(Array.isArray(migrated.prayerLogs)).toBe(true)

    const logs = migrated.prayerLogs as Record<string, unknown>[]
    expect(logs.length).toBe(1)
    expect(logs[0]?.id).toBe('test-log-1')
    expect(logs[0]?.isOffered).toBe(false)
    expect(logs[0]?.missedReason).toBe(1)
    expect(logs[0]?.quranNotes).toBe('Ayatul Kursi')
    expect(logs[0]?.qazaLog).toBeDefined()
    const qaza = logs[0]?.qazaLog as Record<string, unknown>
    expect(qaza.id).toBe('test-qaza-1')
    expect(qaza.state).toBe(0)

    // Merging into empty dataset should succeed seamlessly
    const merged = mergeBackup([], mobileV1)
    expect(merged.length).toBe(1)
    expect(merged[0]?.id).toBe('test-log-1')
  })

  it('migrates a web v1.1.0 format to current v2 schema', () => {
    const webV1 = {
      version: '1.1.0',
      exportedAt: '2026-06-15T10:00:00.000Z',
      appVersion: '1.1.3',
      prayerLogs: [
        {
          id: 'web-log-1',
          userId: 1,
          prayerName: 1,
          prayerDate: '2026-06-15',
          isOffered: true,
          waqtStatus: 0,
          missedReason: null,
          isJamaah: true,
          isTraveling: false,
          isJummah: false,
          isHome: false,
          hasTasbih: true,
          loggedAt: '2026-06-15T13:30:00.000Z',
          updatedAt: '2026-06-15T13:30:00.000Z',
          qazaLog: null,
        },
      ],
      preferences: {
        language: 'bn',
        districtId: '47',
        method: 'Karachi',
        madhab: 'Hanafi',
      },
    }

    const migrated = migrateBackup(webV1)
    expect(migrated.version).toBe(CURRENT_BACKUP_VERSION)
    const merged = mergeBackup([], webV1)
    expect(merged.length).toBe(1)
    expect(merged[0]?.prayerName).toBe(1)
    expect(merged[0]?.isJamaah).toBe(true)
  })

  it('rejects unsupported future version', () => {
    expect(() => migrateBackup({ version: '3.0.0', prayerLogs: [] })).toThrow('Unsupported backup version.')
  })

  it('rejects invalid records with malformed structures', () => {
    expect(() => migrateBackup('invalid-string')).toThrow('Invalid record.')
    expect(() => migrateBackup({ prayerLogs: [] })).toThrow('Backup is missing a version.')
  })
})
