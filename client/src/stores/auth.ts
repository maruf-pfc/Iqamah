import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface User {
  id: number
  username: string
  email: string
}

export interface AuthResponse {
  id: number
  username: string
  email: string
  token: string
}

let rawApiUrl = (import.meta.env.VITE_API_URL || '').replace(/\/$/, '')
if (rawApiUrl && !rawApiUrl.endsWith('/api')) {
  rawApiUrl = `${rawApiUrl}/api`
}
const API_BASE_URL = rawApiUrl || '/api'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const token = ref<string | null>(localStorage.getItem('iqamah_token'))
  const loading = ref(false)
  const error = ref<string | null>(null)

  const isAuthenticated = computed(() => !!token.value)

  const login = async (email: string, password: string) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      })

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}))
        throw new Error(errData.detail || 'Invalid email or password.')
      }

      const data: AuthResponse = await response.json()
      user.value = { id: data.id, username: data.username, email: data.email }
      token.value = data.token
      localStorage.setItem('iqamah_token', data.token)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Login failed.'
      throw err
    } finally {
      loading.value = false
    }
  }

  const register = async (username: string, email: string, password: string) => {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_BASE_URL}/auth/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, email, password }),
      })

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}))
        throw new Error(errData.detail || 'Registration failed.')
      }

      const data: AuthResponse = await response.json()
      user.value = { id: data.id, username: data.username, email: data.email }
      token.value = data.token
      localStorage.setItem('iqamah_token', data.token)
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Registration failed.'
      throw err
    } finally {
      loading.value = false
    }
  }

  const logout = () => {
    user.value = null
    token.value = null
    localStorage.removeItem('iqamah_token')
  }

  const fetchCurrentUser = async () => {
    if (!token.value) return
    loading.value = true
    error.value = null
    try {
      const response = await fetch(`${API_BASE_URL}/auth/me`, {
        headers: {
          Authorization: `Bearer ${token.value}`,
        },
      })

      if (!response.ok) {
        logout()
        throw new Error('Session expired.')
      }

      const data: User = await response.json()
      user.value = data
    } catch (err) {
      logout()
      throw err
    } finally {
      loading.value = false
    }
  }

  return {
    user,
    token,
    loading,
    error,
    isAuthenticated,
    login,
    register,
    logout,
    fetchCurrentUser,
  }
})
