import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { usePrayerStore } from '../stores/prayer'
import { useAuthStore } from '../stores/auth'
import { PrayerName, WaqtStatus, QazaState, MissedReason } from '../types/prayer.types'

describe('Prayer Store (Offline-First)', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()

    // Initialize auth store to completed onboarding
    const authStore = useAuthStore()
    authStore.completeOnboarding('male', 'bn', 'Test User')
  })

  it('fetchPrayerLogs successfully populates prayerLogs state from LocalStorage', async () => {
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
        isHome: false,
        loggedAt: '2025-05-01T05:00:00Z',
        qazaLog: null,
      },
    ]
    localStorage.setItem('iqamah_prayer_logs', JSON.stringify(mockLogs))

    const store = usePrayerStore()
    await store.fetchPrayerLogs('2025-05-01', '2025-05-02')

    expect(store.prayerLogs).toEqual(mockLogs)
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
  })

  it('logPrayer saves offered prayer to LocalStorage', async () => {
    const store = usePrayerStore()
    const request = {
      prayerName: PrayerName.Fajr,
      prayerDate: '2025-05-01',
      isOffered: true,
      waqtStatus: WaqtStatus.AwwalAlWaqt,
      isJamaah: true,
    }

    const newId = await store.logPrayer(request)
    expect(newId).toBeDefined()
    expect(typeof newId).toBe('string')

    const stored = JSON.parse(localStorage.getItem('iqamah_prayer_logs') || '[]')
    expect(stored).toHaveLength(1)
    expect(stored[0].id).toBe(newId)
    expect(stored[0].prayerName).toBe(PrayerName.Fajr)
    expect(stored[0].isOffered).toBe(true)
    expect(stored[0].waqtStatus).toBe(WaqtStatus.AwwalAlWaqt)
    expect(stored[0].isJamaah).toBe(true)
  })

  it('logPrayer with Quran notes and Tasbih saves successfully', async () => {
    const store = usePrayerStore()
    const request = {
      prayerName: PrayerName.Asr,
      prayerDate: '2025-05-01',
      isOffered: true,
      waqtStatus: WaqtStatus.AwwalAlWaqt,
      quranNotes: 'Surah Ya-Sin',
      hasTasbih: true,
    }

    await store.logPrayer(request)
    const stored = JSON.parse(localStorage.getItem('iqamah_prayer_logs') || '[]')
    expect(stored[0].quranNotes).toBe('Surah Ya-Sin')
    expect(stored[0].hasTasbih).toBe(true)
  })

  it('logPrayer generates QazaLog for unexcused missed prayers', async () => {
    const store = usePrayerStore()
    const request = {
      prayerName: PrayerName.Dhuhr,
      prayerDate: '2025-05-01',
      isOffered: false,
      missedReason: MissedReason.UnexcusedLaziness,
    }

    await store.logPrayer(request)
    const stored = JSON.parse(localStorage.getItem('iqamah_prayer_logs') || '[]')
    expect(stored[0].isOffered).toBe(false)
    expect(stored[0].qazaLog).toBeDefined()
    expect(stored[0].qazaLog.state).toBe(QazaState.Pending)
    expect(stored[0].qazaLog.prayerName).toBe(PrayerName.Dhuhr)
  })

  it('fetchPendingQazas populates pendingQazas state from storage', async () => {
    const mockLogs = [
      {
        id: '11111111-2222-3333-4444-555555555555',
        userId: 1,
        prayerName: PrayerName.Asr,
        prayerDate: '2025-05-02',
        isOffered: false,
        waqtStatus: null,
        missedReason: MissedReason.UnexcusedLaziness,
        isJamaah: false,
        isTraveling: false,
        isJummah: false,
        isHome: false,
        loggedAt: '2025-05-02T16:00:00Z',
        qazaLog: {
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
      },
    ]
    localStorage.setItem('iqamah_prayer_logs', JSON.stringify(mockLogs))

    const store = usePrayerStore()
    await store.fetchPendingQazas()

    expect(store.pendingQazas).toHaveLength(1)
    expect(store.pendingQazas[0]!.id).toBe('99999999-8888-7777-6666-555555555555')
    expect(store.pendingQazas[0]!.state).toBe(QazaState.Pending)
  })

  it('fetchAnalytics successfully calculates analytics from LocalStorage logs', async () => {
    const mockLogs = [
      {
        id: '11111111-1',
        userId: 1,
        prayerName: PrayerName.Fajr,
        prayerDate: '2025-05-01',
        isOffered: true,
        waqtStatus: WaqtStatus.AwwalAlWaqt,
        missedReason: null,
        isJamaah: true,
        isTraveling: false,
        isJummah: false,
        isHome: false,
        loggedAt: '2025-05-01T05:00:00Z',
        qazaLog: null,
      },
      {
        id: '11111111-2',
        userId: 1,
        prayerName: PrayerName.Dhuhr,
        prayerDate: '2025-05-01',
        isOffered: false,
        waqtStatus: null,
        missedReason: MissedReason.UnexcusedLaziness,
        isJamaah: false,
        isTraveling: false,
        isJummah: false,
        isHome: false,
        loggedAt: '2025-05-01T12:00:00Z',
        qazaLog: {
          id: '22222222-2',
          prayerLogId: '11111111-2',
          userId: 1,
          prayerName: PrayerName.Dhuhr,
          originalPrayerDate: '2025-05-01',
          state: QazaState.Pending,
          createdAt: '2025-05-01T12:00:00Z',
          fulfilledAt: null,
          timeToResolutionSeconds: null,
        },
      },
    ]
    localStorage.setItem('iqamah_prayer_logs', JSON.stringify(mockLogs))

    const store = usePrayerStore()
    await store.fetchAnalytics('2025-05-01', '2025-05-02')

    expect(store.analytics).toBeDefined()
    expect(store.analytics?.totalLogged).toBe(2)
    expect(store.analytics?.totalObligated).toBe(2)
    expect(store.analytics?.totalOffered).toBe(1)
    expect(store.analytics?.offeredPercentage).toBe(50)
    expect(store.analytics?.missedReasons.unexcusedLazinessCount).toBe(1)
    expect(store.analytics?.qazaSummary.totalPending).toBe(1)
  })
})
