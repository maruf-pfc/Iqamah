<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useLocaleStore } from '@/stores/locale'

const store = usePrayerStore()
const localeStore = useLocaleStore()

const getLocalizedPrayerNameStr = (pName: string) => {
  const keys: Record<string, string> = {
    fajr: 'ফজর',
    dhuhr: 'যোহর',
    asr: 'আসর',
    maghrib: 'মাগরিব',
    isha: 'ইশা'
  }
  return keys[pName.toLowerCase()] || pName
}

const PRAYER_ICONS: Record<string, string> = {
  fajr: '🌅',
  dhuhr: '☀️',
  asr: '⛅',
  maghrib: '🌇',
  isha: '🌃'
}

// Date Range selection
const activeRange = ref<'7d' | '30d' | '365d' | 'custom'>('30d')
const fromDate = ref('')
const toDate = ref('')

const setRange = (range: '7d' | '30d' | '365d') => {
  activeRange.value = range
  const today = new Date()
  const from = new Date()

  if (range === '7d') {
    from.setDate(today.getDate() - 6)
  } else if (range === '30d') {
    from.setDate(today.getDate() - 29)
  } else if (range === '365d') {
    from.setDate(today.getDate() - 364)
  }

  fromDate.value = from.toISOString().split('T')[0] ?? ''
  toDate.value = today.toISOString().split('T')[0] ?? ''
}

// Initial range
setRange('30d')

const loadAnalytics = async () => {
  try {
    await store.fetchAnalytics(fromDate.value, toDate.value)
  } catch (err) {
    console.error('Failed to load analytics', err)
  }
}

watch(
  [fromDate, toDate],
  () => {
    loadAnalytics()
  },
  { immediate: true },
)
</script>

<template>
  <div class="px-6 space-y-6">
    <!-- Header -->
    <div class="pt-4">
      <h1 class="text-2xl font-bold text-slate-900 dark:text-white">
        সালাত অগ্রগতি
      </h1>
      <p class="text-xs font-semibold text-slate-400 dark:text-slate-500 mt-1">
        আপনার আদায়কৃত নামাজ, সময়ানুবর্তিতা এবং কাজা সমাধানের বিস্তারিত বিবরণ।
      </p>
    </div>

    <!-- Range Selector Toolbar (Material 3 Segmented Control) -->
    <div class="flex flex-wrap items-center justify-between gap-3 bg-m3-surface dark:bg-m3-dark-surface p-2 rounded-3xl border border-slate-200/50 dark:border-slate-800/80 shadow-sm">
      <div class="flex bg-slate-100 dark:bg-slate-850 p-1 rounded-2xl w-full">
        <button 
          v-for="r in ['7d', '30d', '365d'] as const"
          :key="r"
          @click="setRange(r)"
          :class="[activeRange === r ? 'bg-m3-primary dark:bg-m3-dark-primary text-white shadow' : 'text-slate-650 dark:text-slate-400']"
          class="flex-1 text-center py-2 text-xs font-bold rounded-xl transition-all cursor-pointer"
        >
          {{ r === '7d' ? '৭ দিন' : r === '30d' ? '৩০ দিন' : '১ বছর' }}
        </button>
        <button 
          @click="activeRange = 'custom'"
          :class="[activeRange === 'custom' ? 'bg-m3-primary dark:bg-m3-dark-primary text-white shadow' : 'text-slate-650 dark:text-slate-400']"
          class="flex-1 text-center py-2 text-xs font-bold rounded-xl transition-all cursor-pointer"
        >
          কাস্টম
        </button>
      </div>

      <!-- Custom Date Pickers inside -->
      <div v-if="activeRange === 'custom'" class="flex items-center gap-2 w-full pt-1 px-1">
        <input 
          type="date"
          v-model="fromDate"
          class="flex-1 bg-slate-100 dark:bg-slate-800 border border-slate-200/35 dark:border-slate-700 text-xs font-bold text-slate-800 dark:text-slate-200 rounded-lg px-2 py-1.5 outline-none"
        />
        <span class="text-slate-400 text-xs font-bold">থেকে</span>
        <input 
          type="date"
          v-model="toDate"
          class="flex-1 bg-slate-100 dark:bg-slate-800 border border-slate-200/35 dark:border-slate-700 text-xs font-bold text-slate-800 dark:text-slate-200 rounded-lg px-2 py-1.5 outline-none"
        />
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="store.loading" class="flex flex-col items-center py-16">
      <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-m3-primary mb-3"></div>
      <p class="text-slate-400 text-xs font-bold">বিশ্লেষণ প্রস্তুত করা হচ্ছে...</p>
    </div>

    <!-- Empty State -->
    <div v-else-if="!store.analytics" class="text-center py-16 bg-m3-surface dark:bg-m3-dark-surface rounded-3xl border border-slate-200/50 dark:border-slate-800">
      <span class="material-symbols-rounded text-4xl text-slate-300 dark:text-slate-700">bar_chart</span>
      <p class="text-slate-400 dark:text-slate-500 text-sm font-bold mt-2">বিশ্লেষণ করার মতো পর্যাপ্ত ডাটা নেই</p>
    </div>

    <!-- Main Content -->
    <div v-else class="space-y-6">
      
      <!-- Key Metric Dial Card & Quick Metrics -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        
        <!-- Offered Ratio Dial -->
        <div class="bg-m3-surface dark:bg-m3-dark-surface p-6 rounded-[32px] border border-slate-200/50 dark:border-slate-800/80 shadow-sm flex flex-col items-center justify-center text-center">
          <div class="relative w-32 h-32 flex items-center justify-center">
            <svg class="w-full h-full transform -rotate-90">
              <circle cx="64" cy="64" r="50" fill="transparent" stroke="#E2E8F0" class="dark:stroke-slate-800" stroke-width="10" />
              <circle cx="64" cy="64" r="50" fill="transparent" stroke="#0F766E" class="dark:stroke-[#5EEAD4] transition-all duration-1000" stroke-width="10" :stroke-dasharray="2 * Math.PI * 50" :stroke-dashoffset="2 * Math.PI * 50 - (store.analytics.offeredPercentage / 100) * 2 * Math.PI * 50" stroke-linecap="round" />
            </svg>
            <div class="absolute flex flex-col items-center">
              <span class="text-2xl font-black text-slate-900 dark:text-white">{{ store.analytics.offeredPercentage }}%</span>
              <span class="text-[9px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider">আদায়কৃত অনুপাত</span>
            </div>
          </div>
          <span class="text-xs font-semibold text-slate-400 dark:text-slate-500 mt-4">নির্ধারিত ফরজ সালাত আদায়ের সামগ্রিক গড় হার।</span>
        </div>

        <!-- Quick 2x2 Metric Cards Grid -->
        <div class="md:col-span-2 grid grid-cols-2 gap-4">
          <!-- Total Logged -->
          <div class="bg-m3-surface dark:bg-m3-dark-surface p-4.5 rounded-[24px] border border-slate-200/50 dark:border-slate-800/80 shadow-sm flex flex-col justify-between">
            <span class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">মোট ট্র্যাকিং</span>
            <span class="text-2xl font-black text-slate-800 dark:text-slate-100 mt-2">{{ store.analytics.totalLogged }}</span>
            <span class="text-[10px] text-slate-500 dark:text-slate-400 font-semibold mt-1">সালাত এন্ট্রি লিপিবদ্ধ</span>
          </div>

          <!-- Total Offered -->
          <div class="bg-m3-surface dark:bg-m3-dark-surface p-4.5 rounded-[24px] border border-slate-200/50 dark:border-slate-800/80 shadow-sm flex flex-col justify-between">
            <span class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">আদায়কৃত</span>
            <span class="text-2xl font-black text-emerald-600 dark:text-emerald-400 mt-2">{{ store.analytics.totalOffered }}</span>
            <span class="text-[10px] text-slate-500 dark:text-slate-400 font-semibold mt-1">সময়মতো আদায় করেছেন</span>
          </div>

          <!-- Total Missed -->
          <div class="bg-m3-surface dark:bg-m3-dark-surface p-4.5 rounded-[24px] border border-slate-200/50 dark:border-slate-800/80 shadow-sm flex flex-col justify-between">
            <span class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">ছুটে গেছে</span>
            <span class="text-2xl font-black text-rose-500 dark:text-rose-450 mt-2">{{ store.analytics.totalMissed }}</span>
            <span class="text-[10px] text-slate-500 dark:text-slate-400 font-semibold mt-1">কাজা তৈরি হয়েছে</span>
          </div>

          <!-- Qaza Made Up -->
          <div class="bg-m3-surface dark:bg-m3-dark-surface p-4.5 rounded-[24px] border border-slate-200/50 dark:border-slate-800/80 shadow-sm flex flex-col justify-between">
            <span class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">কাজা সম্পন্ন</span>
            <span class="text-2xl font-black text-teal-600 dark:text-teal-400 mt-2">{{ store.analytics.qazaSummary.totalFulfilled }}</span>
            <span class="text-[10px] text-slate-500 dark:text-slate-400 font-semibold mt-1">আদায়কৃত কাজা সালাত</span>
          </div>
        </div>

      </div>

      <!-- Waqt Punctuality Breakdown Card -->
      <div class="bg-m3-surface dark:bg-m3-dark-surface p-6 rounded-[32px] border border-slate-200/50 dark:border-slate-800/80 shadow-sm space-y-4">
        <h3 class="font-bold text-base text-slate-800 dark:text-slate-200">সালাতের সময়ানুবর্তিতা</h3>
        
        <div class="space-y-4">
          <!-- Awwal Al Waqt -->
          <div>
            <div class="flex justify-between text-xs font-bold text-slate-650 dark:text-slate-350 mb-1.5">
              <span>আউয়াল ওয়াক্ত (শুরুতে)</span>
              <span>{{ store.analytics.punctuality.awwalAlWaqtCount }}টি ({{ store.analytics.punctuality.awwalAlWaqtPercentage }}%)</span>
            </div>
            <div class="w-full bg-slate-100 dark:bg-slate-800 h-2.5 rounded-full overflow-hidden">
              <div 
                class="bg-m3-primary dark:bg-m3-dark-primary h-full rounded-full transition-all duration-700"
                :style="{ width: `${store.analytics.punctuality.awwalAlWaqtPercentage}%` }"
              ></div>
            </div>
          </div>

          <!-- Wast Al Waqt -->
          <div>
            <div class="flex justify-between text-xs font-bold text-slate-650 dark:text-slate-350 mb-1.5">
              <span>ওয়াসাত ওয়াক্ত (মাঝামাঝি)</span>
              <span>{{ store.analytics.punctuality.wastAlWaqtCount }}টি ({{ store.analytics.punctuality.wastAlWaqtPercentage }}%)</span>
            </div>
            <div class="w-full bg-slate-100 dark:bg-slate-800 h-2.5 rounded-full overflow-hidden">
              <div 
                class="bg-teal-500 h-full rounded-full transition-all duration-700"
                :style="{ width: `${store.analytics.punctuality.wastAlWaqtPercentage}%` }"
              ></div>
            </div>
          </div>

          <!-- Akhir Al Waqt -->
          <div>
            <div class="flex justify-between text-xs font-bold text-slate-650 dark:text-slate-350 mb-1.5">
              <span>আখির ওয়াক্ত (শেষের দিকে)</span>
              <span>{{ store.analytics.punctuality.akhirAlWaqtCount }}টি ({{ store.analytics.punctuality.akhirAlWaqtPercentage }}%)</span>
            </div>
            <div class="w-full bg-slate-100 dark:bg-slate-800 h-2.5 rounded-full overflow-hidden">
              <div 
                class="bg-amber-500 h-full rounded-full transition-all duration-700"
                :style="{ width: `${store.analytics.punctuality.akhirAlWaqtPercentage}%` }"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Missed Reasons Breakdown Card -->
      <div class="bg-m3-surface dark:bg-m3-dark-surface p-6 rounded-[32px] border border-slate-200/50 dark:border-slate-800/80 shadow-sm space-y-4">
        <h3 class="font-bold text-base text-slate-800 dark:text-slate-200">ছুটে যাওয়ার কারণসমূহ</h3>
        <div class="flex gap-4 text-xs font-bold text-slate-400 dark:text-slate-500 border-b border-slate-100 dark:border-slate-800 pb-3">
          <span>ক্ষমাযোগ্য ওজর: <b class="text-teal-600 dark:text-teal-400 font-serif">{{ store.analytics.missedReasons.totalExcused }}টি</b></span>
          <span>•</span>
          <span>ক্ষমা অযোগ্য: <b class="text-rose-500 dark:text-rose-400">{{ store.analytics.missedReasons.totalUnexcused }}টি</b></span>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <!-- Sleep -->
          <div class="bg-slate-50 dark:bg-slate-850 p-3 rounded-2xl border border-slate-100 dark:border-slate-800/50">
            <span class="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider block">ঘুমের কারণে</span>
            <span class="text-lg font-bold text-slate-800 dark:text-slate-250 mt-1 block">{{ store.analytics.missedReasons.excusedSleepCount }} বার</span>
          </div>
          <!-- Forget -->
          <div class="bg-slate-50 dark:bg-slate-850 p-3 rounded-2xl border border-slate-100 dark:border-slate-800/50">
            <span class="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider block">ভুলে যাওয়ার কারণে</span>
            <span class="text-lg font-bold text-slate-800 dark:text-slate-250 mt-1 block">{{ store.analytics.missedReasons.excusedForgetfulnessCount }} বার</span>
          </div>
          <!-- Laziness -->
          <div class="bg-slate-50 dark:bg-slate-850 p-3 rounded-2xl border border-slate-100 dark:border-slate-800/50">
            <span class="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider block">অলসতায়</span>
            <span class="text-lg font-bold text-rose-500 dark:text-rose-400 mt-1 block">{{ store.analytics.missedReasons.unexcusedLazinessCount }} বার</span>
          </div>
          <!-- Distraction -->
          <div class="bg-slate-50 dark:bg-slate-850 p-3 rounded-2xl border border-slate-100 dark:border-slate-800/50">
            <span class="text-[10px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider block">উদাসীনতায়</span>
            <span class="text-lg font-bold text-rose-500 dark:text-rose-400 mt-1 block">{{ store.analytics.missedReasons.unexcusedDistractionCount }} বার</span>
          </div>
        </div>
      </div>

      <!-- Prayer Specific Breakdown: Native Cards instead of Giant Table -->
      <div class="space-y-3">
        <h3 class="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 px-1">ওয়াক্ত ভিত্তিক বিশ্লেষণ</h3>
        
        <div class="grid grid-cols-1 gap-3">
          <div 
            v-for="pName in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']"
            :key="pName"
            class="bg-m3-surface dark:bg-m3-dark-surface p-4.5 rounded-[24px] border border-slate-200/50 dark:border-slate-800/80 shadow-sm flex items-center justify-between"
          >
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-lg">
                {{ PRAYER_ICONS[pName] }}
              </div>
              <div>
                <span class="font-bold text-slate-850 dark:text-slate-200 block">
                  {{ getLocalizedPrayerNameStr(pName) }} সালাত
                </span>
                <div class="flex items-center gap-2 mt-1 text-[11px] text-slate-400 dark:text-slate-500 font-semibold">
                  <span>ফরজ: {{ store.analytics.prayerStats[pName]?.totalObligated ?? 0 }}</span>
                  <span>•</span>
                  <span>আদায়: {{ store.analytics.prayerStats[pName]?.totalOffered ?? 0 }}</span>
                  <span>•</span>
                  <span>জামায়াত: {{ store.analytics.prayerStats[pName]?.jamaahCount ?? 0 }}</span>
                </div>
              </div>
            </div>

            <!-- Percentage badge -->
            <span 
              :class="[
                (store.analytics.prayerStats[pName]?.offeredPercentage ?? 0) >= 90
                  ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20'
                  : (store.analytics.prayerStats[pName]?.offeredPercentage ?? 0) >= 70
                    ? 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20'
                    : 'bg-rose-500/10 text-rose-500 dark:text-rose-450 border border-rose-500/20'
              ]"
              class="px-3 py-1.5 rounded-full font-bold text-xs"
            >
              {{ store.analytics.prayerStats[pName]?.offeredPercentage ?? 0 }}% আদায়
            </span>
          </div>
        </div>
      </div>

      <!-- Qaza Lifecycle Analysis Card -->
      <div class="bg-m3-surface dark:bg-m3-dark-surface p-6 rounded-[32px] border border-slate-200/50 dark:border-slate-800/80 shadow-sm space-y-4">
        <h3 class="font-bold text-base text-slate-800 dark:text-slate-200">কাজা সমাধানের লাইফসাইকেল</h3>
        
        <div class="grid grid-cols-3 gap-3">
          <div class="bg-slate-50 dark:bg-slate-850 p-3 rounded-2xl text-center border border-slate-100 dark:border-slate-800/50">
            <span class="text-[9px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider block">সমাধানের গড় সময়</span>
            <span class="text-base font-black text-teal-600 dark:text-teal-400 block mt-2">
              {{ store.analytics.qazaSummary.averageResolutionTimeHours }} ঘণ্টা
            </span>
          </div>

          <div class="bg-slate-50 dark:bg-slate-850 p-3 rounded-2xl text-center border border-slate-100 dark:border-slate-800/50">
            <span class="text-[9px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider block">মোট কাজা সালাত</span>
            <span class="text-base font-black text-slate-800 dark:text-slate-200 block mt-2">
              {{ store.analytics.qazaSummary.totalIncurred }} বার
            </span>
          </div>

          <div class="bg-slate-50 dark:bg-slate-850 p-3 rounded-2xl text-center border border-slate-100 dark:border-slate-800/50">
            <span class="text-[9px] text-slate-400 dark:text-slate-500 font-bold uppercase tracking-wider block">অপেক্ষমান কাজা</span>
            <span class="text-base font-black text-rose-500 dark:text-rose-400 block mt-2">
              {{ store.analytics.qazaSummary.totalPending }} বার
            </span>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>
