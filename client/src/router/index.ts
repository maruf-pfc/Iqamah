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
      meta: { 
        requiresAuth: true,
        title: 'Dashboard | Iqamah — Salah Habit Tracker',
        description: 'Log and monitor your daily Salah punctuality, track waqt status, and manage excused reasons including Hayd / Nifas.'
      },
    },
    {
      path: '/qaza',
      name: 'qaza',
      component: QazaView,
      meta: { 
        requiresAuth: true,
        title: 'Qaza Ledger | Iqamah',
        description: 'Track and resolve your missed prayers. A smart Islamic make-up ledger to establish complete consistency.'
      },
    },
    {
      path: '/analytics',
      name: 'analytics',
      component: AnalyticsView,
      meta: { 
        requiresAuth: true,
        title: 'Analytics & Insights | Iqamah',
        description: 'Explore comprehensive weekly, monthly, and yearly visualizations of your prayer habits.'
      },
    },
    {
      path: '/salah-time',
      name: 'salah-time',
      component: SalahTimeView,
      meta: { 
        requiresAuth: true,
        title: 'Salah Timings & Forbidden Zone Countdown | Iqamah',
        description: 'Live prayer times and forbidden (Makruh) periods lookup with offline calculation support.'
      },
    },
    {
      path: '/guide',
      name: 'guide',
      component: GuideView,
      meta: { 
        requiresAuth: true,
        title: 'Islamic Fiqh & Salah Guide | Iqamah',
        description: 'Learn the rules of prayer exemption (Hayd/Nifas vs. Janabah), Qaza calculations, and method configurations.'
      },
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
      meta: {
        title: 'Sign In | Iqamah — Establish Your Salah',
        description: 'Access your secure personal Salah logging account to monitor prayer metrics and analytics.'
      }
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

router.afterEach((to) => {
  // Dynamic Page Title
  const title = (to.meta.title as string) || 'Iqamah | Islamic Salah & Qaza Tracker'
  document.title = title

  // Dynamic Meta Description
  const description = (to.meta.description as string) || 'Iqamah helps Muslims establish, track, and analyze their daily Salah habits.'
  let metaDesc = document.querySelector('meta[name="description"]')
  if (metaDesc) {
    metaDesc.setAttribute('content', description)
  } else {
    metaDesc = document.createElement('meta')
    metaDesc.setAttribute('name', 'description')
    metaDesc.setAttribute('content', description)
    document.head.appendChild(metaDesc)
  }
})

export default router
