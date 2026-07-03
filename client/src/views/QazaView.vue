<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useLocaleStore } from '@/stores/locale'

const store = usePrayerStore()
const localeStore = useLocaleStore()

const PRAYER_ICONS = ['🌅', '☀️', '⛅', '🌇', '🌃']

const getLocalizedPrayerName = (prayer: number) => {
  const keys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'] as const
  const key = keys[prayer] || 'fajr'
  return localeStore.t(key)
}

const loadQazas = async () => {
  try {
    await store.fetchPendingQazas()
  } catch (err) {
    console.error('Failed to load pending Qazas', err)
  }
}

onMounted(() => {
  loadQazas()
})

const handleFulfillQaza = async (qazaLogId: string) => {
  try {
    await store.fulfillQaza(qazaLogId)
    await loadQazas()
  } catch (err) {
    console.error('Error fulfilling Qaza:', err)
  }
}

const getRelativeTime = (dateStr: string) => {
  const date = new Date(dateStr)
  const d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate())
  const today = new Date()
  const d2 = new Date(today.getFullYear(), today.getMonth(), today.getDate())
  const diffTime = d2.getTime() - d1.getTime()
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))
  
  if (diffDays <= 0) return 'আজ'
  if (diffDays === 1) return 'গতকাল'
  if (diffDays < 7) return `${diffDays} দিন আগে`
  return date.toLocaleDateString('bn-BD', { month: 'long', day: 'numeric', year: 'numeric' })
}

// Group pending Qaza logs by prayer name for summary
const qazaSummary = computed<Record<number, number>>(() => {
  const counts: Record<number, number> = {
    0: 0,
    1: 0,
    2: 0,
    3: 0,
    4: 0,
  }
  store.pendingQazas.forEach((q) => {
    const key = q.prayerName
    const val = counts[key] ?? 0
    counts[key] = val + 1
  })
  return counts
})

// Timeline grouping
const groupedQazas = computed(() => {
  const groups: Record<string, typeof store.pendingQazas> = {
    'আজ': [],
    'গতকাল': [],
    'এই সপ্তাহে': [],
    'পূর্বে': []
  }

  store.pendingQazas.forEach(q => {
    const date = new Date(q.originalPrayerDate)
    const d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate())
    const today = new Date()
    const d2 = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    const diffTime = d2.getTime() - d1.getTime()
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))

    if (diffDays <= 0) {
      groups['আজ']!.push(q)
    } else if (diffDays === 1) {
      groups['গতকাল']!.push(q)
    } else if (diffDays < 7) {
      groups['এই সপ্তাহে']!.push(q)
    } else {
      groups['পূর্বে']!.push(q)
    }
  })

  // Filter out empty groups
  return Object.entries(groups).filter((item) => item[1].length > 0)
})
</script>

<template>
  <div class="px-6 space-y-6">
    
    <!-- Header -->
    <div class="pt-4">
      <h1 class="text-2xl font-bold text-slate-900 dark:text-white">
        কাজা খতিয়ান (قضاء)
      </h1>
      <p class="text-xs font-semibold text-slate-600 dark:text-slate-300 mt-1">
        ছুটে যাওয়া সালাতের দায় হিসাব করুন এবং অপেক্ষমান কাজা আদায় করুন।
      </p>
    </div>

    <!-- Summary Statistics Grid -->
    <div class="grid grid-cols-5 gap-2">
      <div 
        v-for="pName in [0, 1, 2, 3, 4]"
        :key="pName"
        class="bg-m3-surface dark:bg-m3-dark-surface p-3 rounded-2xl border border-slate-200/50 dark:border-slate-800/80 text-center shadow-sm"
      >
        <span class="text-[10px] font-bold text-slate-600 dark:text-slate-300 block mb-1">
          {{ getLocalizedPrayerName(pName) }}
        </span>
        <span 
          :class="[(qazaSummary[pName] ?? 0) > 0 ? 'text-m3-primary dark:text-m3-dark-primary font-black text-2xl' : 'text-slate-300 dark:text-slate-700 font-bold text-xl']"
          class="block transition-all duration-300"
        >
          {{ qazaSummary[pName] ?? 0 }}
        </span>
      </div>
    </div>

    <!-- Pending Qazas Ledger List -->
    <div class="bg-m3-surface dark:bg-m3-dark-surface rounded-[32px] p-6 border border-slate-200/50 dark:border-slate-800/80 shadow-sm space-y-6">
      
      <!-- List Title -->
      <div class="flex items-center justify-between">
        <h2 class="font-bold text-base text-slate-800 dark:text-slate-200">বকেয়া কাজা সালাতসমূহ</h2>
        <span class="text-xs font-bold bg-m3-primary-container dark:bg-m3-dark-primary-container text-m3-primary dark:text-m3-dark-primary px-3 py-1 rounded-full border border-m3-primary/10">
          {{ store.pendingQazas.length }}টি সালাত বাকি
        </span>
      </div>

      <!-- Loading State -->
      <div v-if="store.loading && store.pendingQazas.length === 0" class="flex flex-col items-center py-12">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-m3-primary mb-2"></div>
        <p class="text-slate-400 text-xs font-semibold">কাজা তথ্য লোড করা হচ্ছে...</p>
      </div>

      <!-- Empty State -->
      <div v-else-if="store.pendingQazas.length === 0" class="text-center py-12 space-y-4">
        <div class="inline-flex items-center justify-center w-16 h-16 rounded-full bg-emerald-500/10 text-m3-success border border-emerald-500/20 shadow-sm animate-pulse">
          <span class="material-symbols-rounded text-3xl font-bold">done_all</span>
        </div>
        <div>
          <h3 class="font-bold text-slate-800 dark:text-slate-200 text-base">কোনো কাজা বাকি নেই!</h3>
          <p class="text-slate-400 dark:text-slate-500 text-xs mt-1 leading-relaxed max-w-xs mx-auto">
            আলহামদুলিল্লাহ, আপনার সব কাজা সালাত সফলভাবে আদায় করা হয়েছে। আপনার ধারাবাহিকতা বজায় রাখুন!
          </p>
        </div>
      </div>

      <!-- Timeline List -->
      <div v-else class="space-y-6">
        <div v-for="[groupName, qazas] in groupedQazas" :key="groupName" class="space-y-3">
          <!-- Timeline Header -->
          <h3 class="text-xs font-black uppercase tracking-wider text-teal-600 dark:text-teal-400 bg-teal-500/5 px-3 py-1 rounded-md inline-block">
            {{ groupName }}
          </h3>

          <!-- Group List -->
          <div class="divide-y divide-slate-100 dark:divide-slate-800/80">
            <div 
              v-for="qaza in qazas" 
              :key="qaza.id" 
              class="flex items-center justify-between py-4.5 first:pt-2 last:pb-2 group transition-all duration-300"
            >
              <div class="flex items-center gap-4">
                <div class="w-10 h-10 rounded-xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-lg shadow-sm">
                  {{ PRAYER_ICONS[qaza.prayerName] }}
                </div>
                <div>
                  <span class="font-bold text-slate-900 dark:text-slate-100 block">
                    {{ getLocalizedPrayerName(qaza.prayerName) }} সালাত
                  </span>
                  <div class="flex items-center gap-1.5 mt-1 text-[11px] text-slate-400 dark:text-slate-500 font-semibold">
                    <span>{{ qaza.originalPrayerDate }}</span>
                    <span>•</span>
                    <span class="text-teal-600 dark:text-teal-400">{{ getRelativeTime(qaza.originalPrayerDate) }}</span>
                  </div>
                </div>
              </div>

              <button 
                @click="handleFulfillQaza(qaza.id)"
                class="bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 font-bold text-xs px-4 py-2.5 rounded-2xl shadow hover:scale-105 active:scale-95 transition-all cursor-pointer"
              >
                আদায় করুন
              </button>
            </div>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>
