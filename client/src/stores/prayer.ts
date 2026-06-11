import { defineStore } from 'pinia'
import { ref } from 'vue'
import type {
  PrayerLogDto,
  QazaLogDto,
  AnalyticsResponseDto,
  LogOfferedPrayerRequest,
  LogMissedPrayerRequest,
} from '@/types/prayer.types'

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

  const fetchPrayerLogs = async (userId: number, from: string, to: string) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`/api/prayers?userId=${userId}&from=${from}&to=${to}`)
      if (!response.ok) {
        const errData = await response.json().catch(() => ({}))
        throw new Error(errData.detail || 'Failed to fetch prayer logs.')
      }
      const data = await response.json()
      prayerLogs.value = data
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : 'An error occurred while fetching prayer logs.'
      throw err
    } finally {
      loading.value = false
    }
  }

  const logPrayer = async (
    userId: number,
    request: LogOfferedPrayerRequest | LogMissedPrayerRequest,
  ) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch('/api/prayers', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId,
          ...request,
        }),
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

  const fetchPendingQazas = async (userId: number) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`/api/qazas/pending?userId=${userId}`)
      if (!response.ok) {
        const errData = await response.json().catch(() => ({}))
        throw new Error(errData.detail || 'Failed to fetch pending Qaza logs.')
      }
      const data = await response.json()
      pendingQazas.value = data
    } catch (err) {
      error.value =
        err instanceof Error ? err.message : 'An error occurred while fetching Qaza logs.'
      throw err
    } finally {
      loading.value = false
    }
  }

  const fulfillQaza = async (qazaLogId: string, userId: number) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`/api/qazas/${qazaLogId}/fulfill`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId,
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

  const fetchAnalytics = async (userId: number, from: string, to: string) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`/api/analytics?userId=${userId}&from=${from}&to=${to}`)
      if (!response.ok) {
        const errData = await response.json().catch(() => ({}))
        throw new Error(errData.detail || 'Failed to fetch analytics.')
      }
      const data = await response.json()
      analytics.value = data
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
