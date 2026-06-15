import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import type {
  PrayerLogDto,
  QazaLogDto,
  AnalyticsResponseDto,
  LogOfferedPrayerRequest,
  LogMissedPrayerRequest,
} from '@/types/prayer.types'

const PRAYER_NAME_MAP: Record<string, number> = {
  Fajr: 0,
  Dhuhr: 1,
  Asr: 2,
  Maghrib: 3,
  Isha: 4,
}

const WAQT_STATUS_MAP: Record<string, number> = {
  AwwalAlWaqt: 0,
  WastAlWaqt: 1,
  AkhirAlWaqt: 2,
}

const MISSED_REASON_MAP: Record<string, number> = {
  ExcusedImpurity: 0,
  ExcusedSleep: 1,
  ExcusedForgetfulness: 2,
  UnexcusedSituational: 3,
  UnexcusedLaziness: 4,
  UnexcusedDistraction: 5,
}

const QAZA_STATE_MAP: Record<string, number> = {
  Pending: 0,
  Offered: 1,
}

/* eslint-disable @typescript-eslint/no-explicit-any */
const normalizeQazaLog = (qaza: any): any => {
  if (!qaza) return null
  return {
    ...qaza,
    prayerName:
      typeof qaza.prayerName === 'string' ? PRAYER_NAME_MAP[qaza.prayerName] : qaza.prayerName,
    state: typeof qaza.state === 'string' ? QAZA_STATE_MAP[qaza.state] : qaza.state,
  }
}

const normalizePrayerLog = (log: any): any => {
  if (!log) return null
  return {
    ...log,
    prayerName:
      typeof log.prayerName === 'string' ? PRAYER_NAME_MAP[log.prayerName] : log.prayerName,
    waqtStatus:
      log.waqtStatus !== null && log.waqtStatus !== undefined
        ? typeof log.waqtStatus === 'string'
          ? WAQT_STATUS_MAP[log.waqtStatus]
          : log.waqtStatus
        : null,
    missedReason:
      log.missedReason !== null && log.missedReason !== undefined
        ? typeof log.missedReason === 'string'
          ? MISSED_REASON_MAP[log.missedReason]
          : log.missedReason
        : null,
    qazaLog: normalizeQazaLog(log.qazaLog),
  }
}

const normalizeAnalytics = (data: any): any => {
  if (!data) return null
  const normalizedStats: Record<number, any> = {}
  if (data.prayerStats) {
    for (const [key, val] of Object.entries(data.prayerStats)) {
      const numKey = PRAYER_NAME_MAP[key] ?? Number(key)
      normalizedStats[numKey] = val
    }
  }
  return {
    ...data,
    prayerStats: normalizedStats,
  }
}
/* eslint-enable @typescript-eslint/no-explicit-any */

const API_BASE_URL = (import.meta.env.VITE_API_URL || '').replace(/\/$/, '') || '/api'

export const usePrayerStore = defineStore('prayer', () => {
  const authStore = useAuthStore()
  const prayerLogs = ref<PrayerLogDto[]>([])
  const pendingQazas = ref<QazaLogDto[]>([])
  const analytics = ref<AnalyticsResponseDto | null>(null)

  const loading = ref(false)
  const error = ref<string | null>(null)

  const clearError = () => {
    error.value = null
  }

  const getHeaders = (headers: Record<string, string> = {}) => {
    const baseHeaders: Record<string, string> = { ...headers }
    if (authStore.token) {
      baseHeaders['Authorization'] = `Bearer ${authStore.token}`
    }
    return baseHeaders
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  const fetchPrayerLogs = async (from: string, to: string) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_BASE_URL}/prayers?from=${from}&to=${to}`, {
        headers: getHeaders(),
      })
      if (!response.ok) {
        const errData = await response.json().catch(() => ({}))
        throw new Error(errData.detail || 'Failed to fetch prayer logs.')
      }
      const data = await response.json()
      prayerLogs.value = (data || []).map(normalizePrayerLog)
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : 'An error occurred while fetching prayer logs.'
      throw err
    } finally {
      loading.value = false
    }
  }

  const logPrayer = async (request: LogOfferedPrayerRequest | LogMissedPrayerRequest) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_BASE_URL}/prayers`, {
        method: 'POST',
        headers: getHeaders({
          'Content-Type': 'application/json',
        }),
        body: JSON.stringify(request),
      })

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}))
        throw new Error(errData.detail || 'Failed to log prayer.')
      }

      const resultId = await response.json()
      return resultId as string
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
      const response = await fetch(`${API_BASE_URL}/qazas/pending`, {
        headers: getHeaders(),
      })
      if (!response.ok) {
        const errData = await response.json().catch(() => ({}))
        throw new Error(errData.detail || 'Failed to fetch pending Qaza logs.')
      }
      const data = await response.json()
      pendingQazas.value = (data || []).map(normalizeQazaLog)
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : 'An error occurred while fetching Qaza logs.'
      throw err
    } finally {
      loading.value = false
    }
  }

  const fulfillQaza = async (qazaLogId: string) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_BASE_URL}/qazas/${qazaLogId}/fulfill`, {
        method: 'POST',
        headers: getHeaders({
          'Content-Type': 'application/json',
        }),
      })

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}))
        throw new Error(errData.detail || 'Failed to fulfill Qaza obligation.')
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
      const response = await fetch(`${API_BASE_URL}/analytics?from=${from}&to=${to}`, {
        headers: getHeaders(),
      })
      if (!response.ok) {
        const errData = await response.json().catch(() => ({}))
        throw new Error(errData.detail || 'Failed to fetch analytics.')
      }
      const data = await response.json()
      analytics.value = normalizeAnalytics(data)
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : 'An error occurred while fetching analytics.'
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
