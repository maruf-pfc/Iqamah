import { beforeEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import App from '@/App.vue'
import SettingsView from '@/views/SettingsView.vue'
import DashboardView from '@/views/DashboardView.vue'

beforeEach(() => {
  localStorage.clear()
  localStorage.setItem('iqamah_onboarding_completed', 'true')
  setActivePinia(createPinia())
})
async function router() {
  const instance = createRouter({ history: createMemoryHistory(), routes: ['/', '/settings', '/guide', '/qaza', '/analytics'].map(path => ({ path, component: { template: '<div />' } })) })
  await instance.push('/')
  await instance.isReady()
  return instance
}
describe('mobile navigation placement', () => {
  it('places guidance rather than analytics in the bottom navigation', async () => {
    const wrapper = mount(App, { global: { plugins: [await router()] } })
    expect(wrapper.find('nav a[href="/guide"]').exists()).toBe(true)
    expect(wrapper.find('nav a[href="/analytics"]').exists()).toBe(false)
    wrapper.unmount()
  })
  it('keeps Analytics in Settings without duplicate timetable and guide entries', async () => {
    const wrapper = mount(SettingsView, { props: { isDark: false }, global: { plugins: [await router()] } })
    expect(wrapper.find('a[href="/analytics"]').exists()).toBe(true)
    expect(wrapper.find('a[href="/salah-time"]').exists()).toBe(false)
    expect(wrapper.find('a[href="/guide"]').exists()).toBe(false)
    wrapper.unmount()
  })
  it('shows five daily prayer cards without the removed left-edge stripe', async () => {
    const wrapper = mount(DashboardView, { global: { plugins: [await router()] } })
    expect(wrapper.findAll('.prayer-log-row')).toHaveLength(5)
    expect(wrapper.find('.prayer-log-row > .absolute.left-0').exists()).toBe(false)
    wrapper.unmount()
  })
})
