import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import App from '../App.vue'
import router from '../router'
import { useAuthStore } from '../stores/auth'

describe('App', () => {
  beforeEach(() => {
    setActivePinia(createPinia())

    // Set authenticated state so navbar renders in tests
    const authStore = useAuthStore()
    authStore.token = 'test_token'
    authStore.user = { id: 1, username: 'Brother Ahmed', email: 'ahmed@example.com' }
  })

  it('mounts renders properly', () => {
    const wrapper = mount(App, {
      global: {
        plugins: [router],
      },
    })
    expect(wrapper.text()).toContain('Iqamah')
  })
})
