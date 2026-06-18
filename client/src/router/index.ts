import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import DashboardView from '../views/DashboardView.vue'
import QazaView from '../views/QazaView.vue'
import AnalyticsView from '../views/AnalyticsView.vue'
import SalahTimeView from '../views/SalahTimeView.vue'
import GuideView from '../views/GuideView.vue'
import LoginView from '../views/LoginView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'dashboard',
      component: DashboardView,
      meta: { requiresAuth: true },
    },
    {
      path: '/qaza',
      name: 'qaza',
      component: QazaView,
      meta: { requiresAuth: true },
    },
    {
      path: '/analytics',
      name: 'analytics',
      component: AnalyticsView,
      meta: { requiresAuth: true },
    },
    {
      path: '/salah-time',
      name: 'salah-time',
      component: SalahTimeView,
      meta: { requiresAuth: true },
    },
    {
      path: '/guide',
      name: 'guide',
      component: GuideView,
      meta: { requiresAuth: true },
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
    },
  ],
})

router.beforeEach(async (to) => {
  const authStore = useAuthStore()

  // Try to load current user if authenticated but state is empty
  if (authStore.token && !authStore.user) {
    try {
      await authStore.fetchCurrentUser()
    } catch {
      // Token invalid or expired
    }
  }

  const isAuth = authStore.isAuthenticated

  if (to.meta.requiresAuth && !isAuth) {
    return '/login'
  } else if (to.name === 'login' && isAuth) {
    return '/'
  }
})

export default router
