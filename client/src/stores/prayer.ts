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
      const response = await fetch(`/api/prayers?from=${from}&to=${to}`, {
        headers: getHeaders(),
      })
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

  const logPrayer = async (request: LogOfferedPrayerRequest | LogMissedPrayerRequest) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch('/api/prayers', {
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
      const response = await fetch('/api/qazas/pending', {
        headers: getHeaders(),
      })
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

  const fulfillQaza = async (qazaLogId: string) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`/api/qazas/${qazaLogId}/fulfill`, {
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
      const response = await fetch(`/api/analytics?from=${from}&to=${to}`, {
        headers: getHeaders(),
      })
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
