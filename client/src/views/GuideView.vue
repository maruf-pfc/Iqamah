<script setup lang="ts">
import { ref, computed } from 'vue'
import { useLocaleStore } from '@/stores/locale'

interface Section {
  id: string
  title: string
  icon: string
  tagline: string
}

const activeTab = ref('qaza-rules')
const localeStore = useLocaleStore()

const sections = computed<Section[]>(() => [
  {
    id: 'qaza-rules',
    title: localeStore.t('qaza_rules'),
    icon: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4',
    tagline: localeStore.t('qaza_rules_tagline'),
  },
  {
    id: 'punctuality',
    title: localeStore.t('waqt_punctuality_title'),
    icon: 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z',
    tagline: localeStore.t('waqt_tagline'),
  },
  {
    id: 'app-usage',
    title: localeStore.t('app_usage'),
    icon: 'M9.75 9.75l4.5 4.5m0-4.5l-4.5 4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
    tagline: localeStore.t('app_usage_tagline'),
  },
])
</script>

<template>
  <div class="min-h-screen py-10 px-4 sm:px-6 lg:px-8">
    <div class="max-w-5xl mx-auto">
      <!-- Page Header -->
      <div class="text-center mb-10">
        <h1
          class="text-3xl sm:text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 via-teal-300 to-indigo-400 tracking-tight"
        >
          {{ localeStore.t('guide_title') }}
        </h1>
        <p class="mt-2 text-slate-400 text-sm sm:text-base max-w-xl mx-auto">
          {{ localeStore.t('guide_tagline') }}
        </p>
      </div>

      <!-- Main Layout -->
      <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        <!-- Sidebar Navigation -->
        <div class="lg:col-span-4 space-y-3">
          <button
            v-for="section in sections"
            :key="section.id"
            @click="activeTab = section.id"
            class="w-full text-left p-4 rounded-2xl transition-all duration-300 border flex items-start gap-4 group cursor-pointer"
            :class="
              activeTab === section.id
                ? 'bg-gradient-to-r from-emerald-500/10 to-teal-500/10 border-emerald-500/30 text-emerald-400 shadow-md shadow-emerald-950/20'
                : 'bg-slate-900/40 border-slate-800/80 text-slate-400 hover:text-slate-200 hover:bg-slate-900/60'
            "
          >
            <div
              class="p-2.5 rounded-xl transition-all duration-300 flex-shrink-0"
              :class="
                activeTab === section.id
                  ? 'bg-emerald-500/20 text-emerald-300'
                  : 'bg-slate-800/50 text-slate-500 group-hover:text-slate-400'
              "
            >
              <svg
                class="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                stroke-width="2"
              >
                <path stroke-linecap="round" stroke-linejoin="round" :d="section.icon" />
              </svg>
            </div>
            <div>
              <h3
                class="font-bold text-sm sm:text-base transition-colors duration-200"
                :class="
                  activeTab === section.id
                    ? 'text-slate-100'
                    : 'text-slate-300 group-hover:text-slate-200'
                "
              >
                {{ section.title }}
              </h3>
              <p class="text-xs text-slate-500 mt-1 line-clamp-2">
                {{ section.tagline }}
              </p>
            </div>
          </button>
        </div>

        <!-- Content Panel -->
        <div
          class="lg:col-span-8 bg-slate-900/40 backdrop-blur-md border border-slate-800/80 rounded-3xl p-6 sm:p-8 min-h-[450px] transition-all duration-300"
        >
          <!-- TAB 1: QAZA RULES -->
          <div v-if="activeTab === 'qaza-rules'" class="space-y-6 animate-fade-in">
            <div class="flex items-center gap-3 border-b border-slate-800/80 pb-4">
              <span class="text-2xl">⚖️</span>
              <div>
                <h2 class="text-xl font-bold text-slate-100">{{ localeStore.t('qaza_rules_heading') }}</h2>
                <p class="text-xs text-slate-500">
                  {{ localeStore.t('qaza_rules_sub') }}
                </p>
              </div>
            </div>

            <p class="text-slate-300 text-sm leading-relaxed">
              {{ localeStore.t('qaza_rules_desc') }}
            </p>

            <!-- Grid Classifications -->
            <div class="space-y-4">
              <!-- Category 1: Excused but Obligatory -->
              <div class="p-4 rounded-2xl bg-indigo-500/5 border border-indigo-500/10">
                <div class="flex items-center gap-2 text-indigo-400 font-bold text-sm">
                  <span>💤</span>
                  <span>{{ localeStore.t('excused_sleep_title') }}</span>
                </div>
                <p class="text-slate-400 text-xs mt-2 leading-relaxed">
                  {{ localeStore.t('excused_sleep_desc') }}
                </p>
              </div>

              <!-- Category 2: Unexcused & Obligatory -->
              <div class="p-4 rounded-2xl bg-rose-500/5 border border-rose-500/10">
                <div class="flex items-center gap-2 text-rose-400 font-bold text-sm">
                  <span>⚠️</span>
                  <span>{{ localeStore.t('unexcused_laziness_title') }}</span>
                </div>
                <p class="text-slate-400 text-xs mt-2 leading-relaxed">
                  {{ localeStore.t('unexcused_laziness_desc') }}
                </p>
              </div>

              <!-- Category 3: Lifted Obligation -->
              <div class="p-4 rounded-2xl bg-emerald-500/5 border border-emerald-500/10">
                <div class="flex items-center gap-2 text-emerald-400 font-bold text-sm">
                  <span>✨</span>
                  <span>{{ localeStore.t('excused_impurity_title') }}</span>
                </div>
                <p class="text-slate-400 text-xs mt-2 leading-relaxed">
                  {{ localeStore.t('excused_impurity_desc') }}
                </p>
              </div>
            </div>
          </div>

          <!-- TAB 2: PUNCTUALITY -->
          <div v-if="activeTab === 'punctuality'" class="space-y-6 animate-fade-in">
            <div class="flex items-center gap-3 border-b border-slate-800/80 pb-4">
              <span class="text-2xl">⏳</span>
              <div>
                <h2 class="text-xl font-bold text-slate-100">{{ localeStore.t('punctuality_title') }}</h2>
                <p class="text-xs text-slate-500">{{ localeStore.t('punctuality_sub') }}</p>
              </div>
            </div>

            <p class="text-slate-300 text-sm leading-relaxed">
              {{ localeStore.t('punctuality_desc') }}
            </p>

            <div class="relative border-l-2 border-slate-800 pl-6 ml-3 space-y-6 py-2">
              <!-- Waqt 1 -->
              <div class="relative">
                <span
                  class="absolute -left-[31px] top-1.5 flex h-4 w-4 rounded-full bg-emerald-500 ring-4 ring-emerald-950"
                ></span>
                <h3 class="text-emerald-400 font-bold text-sm sm:text-base">
                  {{ localeStore.t('awwal_waqt_title') }}
                </h3>
                <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                  {{ localeStore.t('awwal_waqt_desc') }}
                </p>
              </div>

              <!-- Waqt 2 -->
              <div class="relative">
                <span
                  class="absolute -left-[31px] top-1.5 flex h-4 w-4 rounded-full bg-indigo-500 ring-4 ring-indigo-950"
                ></span>
                <h3 class="text-indigo-400 font-bold text-sm sm:text-base">
                  {{ localeStore.t('wast_waqt_title') }}
                </h3>
                <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                  {{ localeStore.t('wast_waqt_desc') }}
                </p>
              </div>

              <!-- Waqt 3 -->
              <div class="relative">
                <span
                  class="absolute -left-[31px] top-1.5 flex h-4 w-4 rounded-full bg-amber-500 ring-4 ring-amber-950"
                ></span>
                <h3 class="text-amber-400 font-bold text-sm sm:text-base">
                  {{ localeStore.t('akhir_waqt_title') }}
                </h3>
                <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                  {{ localeStore.t('akhir_waqt_desc') }}
                </p>
              </div>
            </div>
          </div>

          <!-- TAB 3: APP USAGE -->
          <div v-if="activeTab === 'app-usage'" class="space-y-6 animate-fade-in">
            <div class="flex items-center gap-3 border-b border-slate-800/80 pb-4">
              <span class="text-2xl">📱</span>
              <div>
                <h2 class="text-xl font-bold text-slate-100">{{ localeStore.t('using_platform_title') }}</h2>
                <p class="text-xs text-slate-500">{{ localeStore.t('using_platform_sub') }}</p>
              </div>
            </div>

            <div class="space-y-4">
              <!-- Log daily -->
              <div class="flex gap-3 items-start">
                <div
                  class="h-6 w-6 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center font-bold text-xs flex-shrink-0 mt-0.5"
                >
                  1
                </div>
                <div>
                  <h4 class="text-slate-200 font-semibold text-sm">{{ localeStore.t('establish_salah') }}</h4>
                  <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                    {{ localeStore.t('using_platform_desc_1') }}
                  </p>
                </div>
              </div>

              <!-- Qaza Ledger -->
              <div class="flex gap-3 items-start">
                <div
                  class="h-6 w-6 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center font-bold text-xs flex-shrink-0 mt-0.5"
                >
                  2
                </div>
                <div>
                  <h4 class="text-slate-200 font-semibold text-sm">{{ localeStore.t('qaza_ledger') }}</h4>
                  <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                    {{ localeStore.t('using_platform_desc_2') }}
                  </p>
                </div>
              </div>

              <!-- Analytics Denominator -->
              <div class="flex gap-3 items-start">
                <div
                  class="h-6 w-6 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 flex items-center justify-center font-bold text-xs flex-shrink-0 mt-0.5"
                >
                  3
                </div>
                <div>
                  <h4 class="text-slate-200 font-semibold text-sm">
                    {{ localeStore.t('waqt_punctuality_title') }} & {{ localeStore.t('offered_ratio') }}
                  </h4>
                  <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                    {{ localeStore.t('using_platform_desc_3') }}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.35s ease-out forwards;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(6px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
