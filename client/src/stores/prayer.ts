import { defineStore } from 'pinia'
import { ref } from 'vue'
import type {
  PrayerLogDto,
  QazaLogDto,
  AnalyticsResponseDto,
  LogOfferedPrayerRequest,
  LogMissedPrayerRequest,
} from '@/types/prayer.types'

const generateUUID = (): string => {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID()
  }
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0
    const v = c === 'x' ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

const loadLogsFromStorage = (): PrayerLogDto[] => {
  try {
    const data = localStorage.getItem('iqamah_prayer_logs')
    return data ? JSON.parse(data) : []
  } catch {
    return []
  }
}

const saveLogsToStorage = (logs: PrayerLogDto[]) => {
  localStorage.setItem('iqamah_prayer_logs', JSON.stringify(logs))
}

export const usePrayerStore = defineStore('prayer', () => {
  const prayerLogs = ref<PrayerLogDto[]>([])
  const pendingQazas = ref<QazaLogDto[]>([])
  const analytics = ref<AnalyticsResponseDto | null>(null)

  const loading = ref(false)
  const error = ref<string | null>(null)

  const clearError = () => {
    error.value = null
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  const fetchPrayerLogs = async (from: string, to: string) => {
    loading.value = true
    error.value = null
    try {
      const allLogs = loadLogsFromStorage()
      const filtered = allLogs.filter(
        (log) => log.prayerDate >= from && log.prayerDate <= to
      )
      filtered.sort((a, b) => {
        if (a.prayerDate !== b.prayerDate) {
          return a.prayerDate.localeCompare(b.prayerDate)
        }
        return a.prayerName - b.prayerName
      })
      prayerLogs.value = filtered
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to fetch prayer logs.'
      throw err
    } finally {
      loading.value = false
    }
  }

  const logPrayer = async (request: LogOfferedPrayerRequest | LogMissedPrayerRequest) => {
    loading.value = true
    error.value = null
    try {
      const allLogs = loadLogsFromStorage()
      const existingIndex = allLogs.findIndex(
        (log) => log.prayerDate === request.prayerDate && log.prayerName === request.prayerName
      )

      let resultId: string

      if (existingIndex > -1) {
        const oldLog = allLogs[existingIndex]!
        resultId = oldLog.id

        // Build updated log
        let updatedQazaLog = oldLog.qazaLog
        if (request.isOffered) {
          updatedQazaLog = null
        } else {
          const missedReq = request as LogMissedPrayerRequest
          const requiresQ = missedReq.missedReason !== 0 // MissedReason.ExcusedImpurity is 0
          if (requiresQ) {
            if (!updatedQazaLog || updatedQazaLog.state === 1) {
              updatedQazaLog = {
                id: generateUUID(),
                prayerLogId: resultId,
                userId: 1,
                prayerName: request.prayerName,
                originalPrayerDate: request.prayerDate,
                state: 0, // QazaState.Pending
                createdAt: new Date().toISOString(),
                fulfilledAt: null,
                timeToResolutionSeconds: null,
              }
            }
          } else {
            updatedQazaLog = null
          }
        }

        const updatedLog: PrayerLogDto = {
          id: resultId,
          userId: 1,
          prayerName: request.prayerName,
          prayerDate: request.prayerDate,
          isOffered: request.isOffered,
          waqtStatus: request.isOffered ? (request as LogOfferedPrayerRequest).waqtStatus : null,
          missedReason: !request.isOffered ? (request as LogMissedPrayerRequest).missedReason : null,
          isJamaah: request.isOffered ? ((request as LogOfferedPrayerRequest).isJamaah ?? false) : false,
          isTraveling: request.isTraveling ?? false,
          isJummah: request.isOffered ? ((request as LogOfferedPrayerRequest).isJummah ?? false) : false,
          isHome: request.isOffered ? ((request as LogOfferedPrayerRequest).isHome ?? false) : false,
          quranNotes: request.isOffered ? ((request as LogOfferedPrayerRequest).quranNotes ?? undefined) : undefined,
          hasTasbih: request.isOffered ? ((request as LogOfferedPrayerRequest).hasTasbih ?? false) : false,
          loggedAt: oldLog.loggedAt,
          qazaLog: updatedQazaLog,
        }
        allLogs[existingIndex] = updatedLog
      } else {
        resultId = generateUUID()
        let qazaLog: QazaLogDto | null = null

        if (!request.isOffered) {
          const missedReq = request as LogMissedPrayerRequest
          const requiresQ = missedReq.missedReason !== 0
          if (requiresQ) {
            qazaLog = {
              id: generateUUID(),
              prayerLogId: resultId,
              userId: 1,
              prayerName: request.prayerName,
              originalPrayerDate: request.prayerDate,
              state: 0, // QazaState.Pending
              createdAt: new Date().toISOString(),
              fulfilledAt: null,
              timeToResolutionSeconds: null,
            }
          }
        }

        const newLog: PrayerLogDto = {
          id: resultId,
          userId: 1,
          prayerName: request.prayerName,
          prayerDate: request.prayerDate,
          isOffered: request.isOffered,
          waqtStatus: request.isOffered ? (request as LogOfferedPrayerRequest).waqtStatus : null,
          missedReason: !request.isOffered ? (request as LogMissedPrayerRequest).missedReason : null,
          isJamaah: request.isOffered ? ((request as LogOfferedPrayerRequest).isJamaah ?? false) : false,
          isTraveling: request.isTraveling ?? false,
          isJummah: request.isOffered ? ((request as LogOfferedPrayerRequest).isJummah ?? false) : false,
          isHome: request.isOffered ? ((request as LogOfferedPrayerRequest).isHome ?? false) : false,
          quranNotes: request.isOffered ? ((request as LogOfferedPrayerRequest).quranNotes ?? undefined) : undefined,
          hasTasbih: request.isOffered ? ((request as LogOfferedPrayerRequest).hasTasbih ?? false) : false,
          loggedAt: new Date().toISOString(),
          qazaLog,
        }
        allLogs.push(newLog)
      }

      saveLogsToStorage(allLogs)
      return resultId
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'An error occurred while logging prayer.'
      throw err
    } finally {
      loading.value = false
    }
  }

  const fetchPendingQazas = async () => {
    loading.value = true
    error.value = null
    try {
      const allLogs = loadLogsFromStorage()
      const pending: QazaLogDto[] = []
      for (const log of allLogs) {
        if (log.qazaLog && log.qazaLog.state === 0) {
          pending.push(log.qazaLog)
        }
      }
      pending.sort((a, b) => b.originalPrayerDate.localeCompare(a.originalPrayerDate))
      pendingQazas.value = pending
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'An error occurred while fetching Qaza logs.'
      throw err
    } finally {
      loading.value = false
    }
  }

  const fulfillQaza = async (qazaLogId: string) => {
    loading.value = true
    error.value = null
    try {
      const allLogs = loadLogsFromStorage()
      const existingIndex = allLogs.findIndex(
        (log) => log.qazaLog && log.qazaLog.id === qazaLogId
      )

      if (existingIndex > -1) {
        const log = allLogs[existingIndex]!
        if (log.qazaLog) {
          const nowStr = new Date().toISOString()
          const createdTime = new Date(log.qazaLog.createdAt).getTime()
          const fulfilledTime = new Date(nowStr).getTime()
          const timeToResolutionSeconds = Math.max(0, Math.floor((fulfilledTime - createdTime) / 1000))

          const updatedQaza: QazaLogDto = {
            ...log.qazaLog,
            state: 1, // QazaState.Offered
            fulfilledAt: nowStr,
            timeToResolutionSeconds,
          }

          const updatedLog: PrayerLogDto = {
            id: log.id,
            userId: log.userId,
            prayerName: log.prayerName,
            prayerDate: log.prayerDate,
            isOffered: log.isOffered,
            waqtStatus: log.waqtStatus,
            missedReason: log.missedReason,
            isJamaah: log.isJamaah,
            isTraveling: log.isTraveling,
            isJummah: log.isJummah,
            isHome: log.isHome,
            quranNotes: log.quranNotes,
            hasTasbih: log.hasTasbih,
            loggedAt: log.loggedAt,
            qazaLog: updatedQaza,
          }

          allLogs[existingIndex] = updatedLog
          saveLogsToStorage(allLogs)
        }
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'An error occurred while fulfilling Qaza.'
      throw err
    } finally {
      loading.value = false
    }
  }

  const fetchAnalytics = async (from: string, to: string) => {
    loading.value = true
    error.value = null
    try {
      const allLogs = loadLogsFromStorage()
      const rangeLogs = allLogs.filter((log) => log.prayerDate >= from && log.prayerDate <= to)

      const totalLogged = rangeLogs.length
      const obligatedLogs = rangeLogs.filter((log) => log.missedReason !== 0)
      const totalObligated = obligatedLogs.length
      const offeredLogs = rangeLogs.filter((log) => log.isOffered)
      const totalOffered = offeredLogs.length
      const totalMissed = totalObligated - totalOffered
      const offeredPercentage = totalObligated > 0 ? Math.round((totalOffered / totalObligated) * 100) : 0

      let awwalAlWaqtCount = 0
      let wastAlWaqtCount = 0
      let akhirAlWaqtCount = 0
      for (const log of offeredLogs) {
        if (log.waqtStatus === 0) awwalAlWaqtCount++
        else if (log.waqtStatus === 1) wastAlWaqtCount++
        else if (log.waqtStatus === 2) akhirAlWaqtCount++
      }

      const punctuality = {
        awwalAlWaqtCount,
        wastAlWaqtCount,
        akhirAlWaqtCount,
        awwalAlWaqtPercentage: totalOffered > 0 ? Math.round((awwalAlWaqtCount / totalOffered) * 100) : 0,
        wastAlWaqtPercentage: totalOffered > 0 ? Math.round((wastAlWaqtCount / totalOffered) * 100) : 0,
        akhirAlWaqtPercentage: totalOffered > 0 ? Math.round((akhirAlWaqtCount / totalOffered) * 100) : 0,
      }

      let excusedImpurityCount = 0
      let excusedSleepCount = 0
      let excusedForgetfulnessCount = 0
      let unexcusedSituationalCount = 0
      let unexcusedLazinessCount = 0
      let unexcusedDistractionCount = 0

      for (const log of rangeLogs) {
        if (!log.isOffered) {
          if (log.missedReason === 0) excusedImpurityCount++
          else if (log.missedReason === 1) excusedSleepCount++
          else if (log.missedReason === 2) excusedForgetfulnessCount++
          else if (log.missedReason === 3) unexcusedSituationalCount++
          else if (log.missedReason === 4) unexcusedLazinessCount++
          else if (log.missedReason === 5) unexcusedDistractionCount++
        }
      }

      const totalExcused = excusedImpurityCount + excusedSleepCount + excusedForgetfulnessCount
      const totalUnexcused = unexcusedSituationalCount + unexcusedLazinessCount + unexcusedDistractionCount

      const missedReasons = {
        excusedImpurityCount,
        excusedSleepCount,
        excusedForgetfulnessCount,
        unexcusedSituationalCount,
        unexcusedLazinessCount,
        unexcusedDistractionCount,
        totalExcused,
        totalUnexcused,
      }

      const prayerNamesList = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']
      /* eslint-disable @typescript-eslint/no-explicit-any */
      const prayerStats: Record<string, any> = {}

      for (let i = 0; i < 5; i++) {
        const pNameStr = prayerNamesList[i] || 'fajr'
        const pLogs = rangeLogs.filter((log) => log.prayerName === i)
        const pObligated = pLogs.filter((log) => log.missedReason !== 0)
        const pOffered = pLogs.filter((log) => log.isOffered)

        const totalObligatedCount = pObligated.length
        const totalOfferedCount = pOffered.length

        const stats = {
          totalObligated: totalObligatedCount,
          totalOffered: totalOfferedCount,
          offeredPercentage: totalObligatedCount > 0 ? Math.round((totalOfferedCount / totalObligatedCount) * 100) : 0,
          jamaahCount: pOffered.filter((log) => log.isJamaah).length,
          jamaahPercentage: totalOfferedCount > 0 ? Math.round((pOffered.filter((log) => log.isJamaah).length / totalOfferedCount) * 100) : 0,
          travelingCount: pLogs.filter((log) => log.isTraveling).length,
          homeCount: pOffered.filter((log) => log.isHome).length,
        }

        prayerStats[i] = stats
        prayerStats[pNameStr] = stats
        prayerStats[pNameStr.charAt(0).toUpperCase() + pNameStr.slice(1)] = stats
      }

      const allQazaLogs = allLogs
        .map((log) => log.qazaLog)
        .filter((qaza): qaza is QazaLogDto => qaza !== null)

      const totalPending = allQazaLogs.filter((qaza) => qaza.state === 0).length
      const totalFulfilled = allQazaLogs.filter((qaza) => qaza.state === 1).length
      const totalIncurred = totalPending + totalFulfilled

      let totalResolutionTimeSeconds = 0
      let resolvedCount = 0
      for (const qaza of allQazaLogs) {
        if (qaza.state === 1 && qaza.timeToResolutionSeconds !== null) {
          totalResolutionTimeSeconds += qaza.timeToResolutionSeconds
          resolvedCount++
        }
      }

      const averageResolutionTimeHours = resolvedCount > 0
        ? parseFloat((totalResolutionTimeSeconds / (3600 * resolvedCount)).toFixed(2))
        : 0

      const qazaSummary = {
        totalPending,
        totalFulfilled,
        totalIncurred,
        averageResolutionTimeHours,
      }

      analytics.value = {
        totalLogged,
        totalObligated,
        totalOffered,
        totalMissed,
        offeredPercentage,
        punctuality,
        missedReasons,
        prayerStats,
        qazaSummary,
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'An error occurred while fetching analytics.'
      throw err
    } finally {
      loading.value = false
    }
  }

  return {
    prayerLogs,
    pendingQazas,
    analytics,
    loading,
    error,
    clearError,
    fetchPrayerLogs,
    logPrayer,
    fetchPendingQazas,
    fulfillQaza,
    fetchAnalytics,
  }
})
