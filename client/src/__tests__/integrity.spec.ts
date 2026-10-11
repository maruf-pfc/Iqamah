import { beforeEach, describe, expect, it } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'
import { usePrayerStore } from '@/stores/prayer'
import { mergeBackup, validateLogs } from '@/services/backup'

describe('record integrity', () => {
  beforeEach(() => {
    localStorage.clear()
    setActivePinia(createPinia())
  })

  it('rejects invalid missed requests without modifying storage', async () => {
    const store = usePrayerStore()
    await expect(store.logPrayer({ prayerName: 0, prayerDate: '2026-10-11', isOffered: false, waqtStatus: 0 })).rejects.toThrow('Missed prayers require a reason')
    expect(localStorage.getItem('iqamah_prayer_logs')).toBeNull()
  })

  it('rejects invalid dates and Jummah on another prayer', async () => {
    const store = usePrayerStore()
    await expect(store.logPrayer({ prayerName: 0, prayerDate: '2026-02-30', isOffered: true, waqtStatus: 0 })).rejects.toThrow('Invalid prayer or date.')
    await expect(store.logPrayer({ prayerName: 0, prayerDate: '2026-10-11', isOffered: true, waqtStatus: 0, isJummah: true })).rejects.toThrow('Jummah is only valid')
  })

  it.each([0, 1, 2, 3, 4, 5])('applies the canonical Qaza rule for reason %s', async (missedReason) => {
    const store = usePrayerStore()
    await store.logPrayer({ prayerName: 0, prayerDate: '2026-10-11', isOffered: false, missedReason })
    const logs = validateLogs(JSON.parse(localStorage.getItem('iqamah_prayer_logs')!))
    expect(Boolean(logs[0]?.qazaLog)).toBe(missedReason !== 0)
  })

  it('preserves a fulfilled obligation across repeated saves and rejects refulfillment', async () => {
    const store = usePrayerStore()
    const request = { prayerName: 0, prayerDate: '2026-10-11', isOffered: false, missedReason: 1 }
    await store.logPrayer(request)
    await store.fetchPendingQazas()
    const id = store.pendingQazas[0]!.id
    await store.fulfillQaza(id)
    const before = localStorage.getItem('iqamah_prayer_logs')
    await expect(store.fulfillQaza(id)).rejects.toThrow('already been fulfilled')
    expect(localStorage.getItem('iqamah_prayer_logs')).toBe(before)
    await store.logPrayer(request)
    expect(validateLogs(JSON.parse(localStorage.getItem('iqamah_prayer_logs')!))[0]?.qazaLog?.state).toBe(1)
  })

  it('fails closed on damaged storage instead of overwriting it', async () => {
    localStorage.setItem('iqamah_prayer_logs', '{broken')
    await expect(usePrayerStore().logPrayer({ prayerName: 0, prayerDate: '2026-10-11', isOffered: true, waqtStatus: 0 })).rejects.toThrow(SyntaxError)
    expect(localStorage.getItem('iqamah_prayer_logs')).toBe('{broken')
  })

  it('preserves notes on a partial edit and does not erase fulfilled debt through correction', async () => {
    const store = usePrayerStore()
    await store.logPrayer({ prayerName: 0, prayerDate: '2026-10-11', isOffered: true, waqtStatus: 0, quranNotes: 'Private note' })
    await store.logPrayer({ prayerName: 0, prayerDate: '2026-10-11', isOffered: true, waqtStatus: 1 })
    expect(readStored()[0]?.quranNotes).toBe('Private note')
    await store.logPrayer({ prayerName: 0, prayerDate: '2026-10-11', isOffered: false, missedReason: 1 })
    await store.fetchPendingQazas()
    await store.fulfillQaza(store.pendingQazas[0]!.id)
    const before = localStorage.getItem('iqamah_prayer_logs')
    await expect(store.logPrayer({ prayerName: 0, prayerDate: '2026-10-11', isOffered: true, waqtStatus: 0 })).rejects.toThrow('fulfilled Qaza is historical evidence')
    expect(localStorage.getItem('iqamah_prayer_logs')).toBe(before)
  })

  it('restores stable IDs and fulfillment, is repeatable, and rejects conflicting imports', async () => {
    const store = usePrayerStore()
    await store.logPrayer({ prayerName: 0, prayerDate: '2020-01-01', isOffered: false, missedReason: 1 })
    await store.fetchPendingQazas()
    await store.fulfillQaza(store.pendingQazas[0]!.id)
    const logs = validateLogs(JSON.parse(localStorage.getItem('iqamah_prayer_logs')!))
    const backup = { version: '1.1.0', prayerLogs: logs }
    expect(mergeBackup([], backup)).toEqual(logs)
    expect(mergeBackup(logs, backup)).toEqual(logs)
    expect(() => mergeBackup(logs, { ...backup, version: '99' })).toThrow('Unsupported backup version.')
    expect(() => mergeBackup(logs, { ...backup, prayerLogs: [{ ...logs[0], id: 'another-id' }] })).toThrow('Invalid Qaza relationship.')
    expect(() => mergeBackup([], { ...backup, prayerLogs: [logs[0], { invalid: true }] })).toThrow('Invalid prayer or date.')
  })
})

function readStored() { return validateLogs(JSON.parse(localStorage.getItem('iqamah_prayer_logs')!)) }
