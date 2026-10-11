import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { readPreference } from '@/services/preferences'

export interface User {
  id: number
  username: string
  email: string
}

export const useAuthStore = defineStore('auth', () => {
  const getStoredUser = (): User | null => {
    const completed = readPreference('iqamah_onboarding_completed') === 'true'
    if (!completed) return null
    const name = readPreference('iqamah_user_name') || 'Iqamah'
    return {
      id: 1,
      username: name,
      email: 'local@iqamah.local'
    }
  }

  const user = ref<User | null>(getStoredUser())
  const token = ref<string | null>(readPreference('iqamah_onboarding_completed') === 'true' ? 'local_offline_token' : null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const isAuthenticated = computed(() => !!token.value)

  const login = async (email: string, _password: string) => {
    // No-op local fallback
    token.value = 'local_offline_token'
    user.value = { id: 1, username: 'Brother Ahmed', email }
  }

  const register = async (username: string, email: string, _password: string) => {
    // No-op local fallback
    token.value = 'local_offline_token'
    user.value = { id: 1, username, email }
  }

  const logout = () => {
    user.value = null
    token.value = null
    localStorage.removeItem('iqamah_onboarding_completed')
    localStorage.removeItem('iqamah_user_name')
    localStorage.removeItem('iqamah_user_g')
  }

  const completeOnboarding = (userGender: 'male' | 'female', lang: 'en' | 'bn', customName?: string) => {
    localStorage.setItem('iqamah_user_g', userGender === 'female' ? 'f' : 'm')
    localStorage.setItem('iqamah_locale', lang)
    
    let displayName = customName?.trim()
    if (!displayName) {
      displayName = userGender === 'female' ? 'Sister Ayesha' : 'Brother Ahmed'
    }
    localStorage.setItem('iqamah_user_name', displayName)
    localStorage.setItem('iqamah_onboarding_completed', 'true')
    
    user.value = {
      id: 1,
      username: displayName,
      email: 'local@iqamah.local'
    }
    token.value = 'local_offline_token'
  }

  const fetchCurrentUser = async () => {
    // No-op
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
    completeOnboarding,
    fetchCurrentUser,
  }
})
