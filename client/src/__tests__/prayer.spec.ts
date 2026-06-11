import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { usePrayerStore } from '../stores/prayer'
import { PrayerName, WaqtStatus, QazaState } from '../types/prayer.types'

describe('Prayer Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.restoreAllMocks()
  })

  it('fetchPrayerLogs successfully populates prayerLogs state', async () => {
    const mockLogs = [
      {
        id: '11111111-2222-3333-4444-555555555555',
        userId: 1,
        prayerName: PrayerName.Fajr,
        prayerDate: '2025-05-01',
        isOffered: true,
        waqtStatus: WaqtStatus.AwwalAlWaqt,
        missedReason: null,
        isJamaah: true,
        isTraveling: false,
        isJummah: false,
        loggedAt: '2025-05-01T05:00:00Z',
        qazaLog: null,
      },
    ]

    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockImplementation(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve(mockLogs),
      } as Response),
    )

    const store = usePrayerStore()
    await store.fetchPrayerLogs(1, '2025-05-01', '2025-05-02')

    expect(fetchSpy).toHaveBeenCalledWith('/api/prayers?userId=1&from=2025-05-01&to=2025-05-02')
    expect(store.prayerLogs).toEqual(mockLogs)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
  })

  it('fetchPrayerLogs sets error state on API failure', async () => {
    vi.spyOn(globalThis, 'fetch').mockImplementation(() =>
      Promise.resolve({
        ok: false,
        json: () => Promise.resolve({ detail: 'Database connection failed' }),
      } as Response),
    )

    const store = usePrayerStore()
    await expect(store.fetchPrayerLogs(1, '2025-05-01', '2025-05-02')).rejects.toThrow(
      'Database connection failed',
    )

    expect(store.prayerLogs).toEqual([])
    expect(store.error).toBe('Database connection failed')
    expect(store.loading).toBe(false)
  })

  it('logPrayer posts log to backend successfully', async () => {
    const fetchSpy = vi.spyOn(globalThis, 'fetch').mockImplementation(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve('22222222-3333-4444-5555-666666666666'),
      } as Response),
    )

    const store = usePrayerStore()
    const request = {
      prayerName: PrayerName.Fajr,
      prayerDate: '2025-05-01',
      waqtStatus: WaqtStatus.AwwalAlWaqt,
      isJamaah: true,
    }

    const newId = await store.logPrayer(1, request)

    expect(fetchSpy).toHaveBeenCalledWith(
      '/api/prayers',
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ userId: 1, ...request }),
      }),
    )
    expect(newId).toBe('22222222-3333-4444-5555-666666666666')
    expect(store.error).toBeNull()
  })

  it('fetchPendingQazas populates pendingQazas state', async () => {
    const mockQazas = [
      {
        id: '99999999-8888-7777-6666-555555555555',
        prayerLogId: '11111111-2222-3333-4444-555555555555',
        userId: 1,
        prayerName: PrayerName.Asr,
        originalPrayerDate: '2025-05-02',
        state: QazaState.Pending,
        createdAt: '2025-05-02T16:00:00Z',
        fulfilledAt: null,
        timeToResolutionSeconds: null,
      },
    ]

    vi.spyOn(globalThis, 'fetch').mockImplementation(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve(mockQazas),
      } as Response),
    )

    const store = usePrayerStore()
    await store.fetchPendingQazas(1)

    expect(store.pendingQazas).toEqual(mockQazas)
    expect(store.error).toBeNull()
  })

  it('fetchAnalytics successfully populates analytics state', async () => {
    const mockAnalytics = {
      totalLogged: 10,
      totalObligated: 9,
      totalOffered: 7,
      totalMissed: 2,
      offeredPercentage: 77.78,
      punctuality: {
        awwalAlWaqtCount: 4,
        wastAlWaqtCount: 2,
        akhirAlWaqtCount: 1,
        awwalAlWaqtPercentage: 57.14,
        wastAlWaqtPercentage: 28.57,
        akhirAlWaqtPercentage: 14.29,
      },
      missedReasons: {
        excusedImpurityCount: 1,
        excusedSleepCount: 1,
        excusedForgetfulnessCount: 0,
        unexcusedSituationalCount: 0,
        unexcusedLazinessCount: 1,
        unexcusedDistractionCount: 0,
        totalExcused: 1,
        totalUnexcused: 1,
      },
      prayerStats: {},
      qazaSummary: {
        totalPending: 2,
        totalFulfilled: 3,
        totalIncurred: 5,
        averageResolutionTimeHours: 12.5,
      },
    }

    vi.spyOn(globalThis, 'fetch').mockImplementation(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve(mockAnalytics),
      } as Response),
    )

    const store = usePrayerStore()
    await store.fetchAnalytics(1, '2025-05-01', '2025-05-10')

    expect(store.analytics).toEqual(mockAnalytics)
    expect(store.error).toBeNull()
  })
})
