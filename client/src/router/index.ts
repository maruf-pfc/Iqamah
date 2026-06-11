import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'
import QazaView from '../views/QazaView.vue'
import AnalyticsView from '../views/AnalyticsView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'dashboard',
      component: DashboardView,
    },
    {
      path: '/qaza',
      name: 'qaza',
      component: QazaView,
    },
    {
      path: '/analytics',
      name: 'analytics',
      component: AnalyticsView,
    },
  ],
})

export default router
