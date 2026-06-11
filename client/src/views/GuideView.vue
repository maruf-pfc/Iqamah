<script setup lang="ts">
import { ref } from 'vue'

interface Section {
  id: string
  title: string
  icon: string
  tagline: string
}

const activeTab = ref('qaza-rules')

const sections: Section[] = [
  {
    id: 'qaza-rules',
    title: 'Qaza (Make-up) Rules',
    icon: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4',
    tagline: 'Familiarize yourself with jurisprudence regarding missed prayers.',
  },
  {
    id: 'punctuality',
    title: 'Waqt & Punctuality',
    icon: 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z',
    tagline: 'Understanding Awwal, Wast, and Akhir al-Waqt.',
  },
  {
    id: 'app-usage',
    title: 'Using the Platform',
    icon: 'M9.75 9.75l4.5 4.5m0-4.5l-4.5 4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
    tagline: 'How to log Salah modifiers, track debts, and read charts.',
  },
]
</script>

<template>
  <div class="min-h-screen py-10 px-4 sm:px-6 lg:px-8">
    <div class="max-w-5xl mx-auto">
      <!-- Page Header -->
      <div class="text-center mb-10">
        <h1
          class="text-3xl sm:text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 via-teal-300 to-indigo-400 tracking-tight"
        >
          Salah Guide & Documentation
        </h1>
        <p class="mt-2 text-slate-400 text-sm sm:text-base max-w-xl mx-auto">
          Learn the jurisprudential framework behind Iqamah's tracking system and get the most out
          of your analytical reports.
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
                <h2 class="text-xl font-bold text-slate-100">Qaza (Make-up) Islamic Rules</h2>
                <p class="text-xs text-slate-500">
                  Legal classifications of missed prayers in Fiqh.
                </p>
              </div>
            </div>

            <p class="text-slate-300 text-sm leading-relaxed">
              In Islamic jurisprudence, daily prayers (Salawat) are strictly bound to their set
              times. If a prayer is missed, it becomes an outstanding obligation (Debt / Dayn) that
              remains due upon the individual until performed as a
              <span class="text-teal-400 font-semibold">Qaza</span>.
            </p>

            <!-- Grid Classifications -->
            <div class="space-y-4">
              <!-- Category 1: Excused but Obligatory -->
              <div class="p-4 rounded-2xl bg-indigo-500/5 border border-indigo-500/10">
                <div class="flex items-center gap-2 text-indigo-400 font-bold text-sm">
                  <span>💤</span>
                  <span>Excused (Ma'dhur) — Sleep & Forgetfulness</span>
                </div>
                <p class="text-slate-400 text-xs mt-2 leading-relaxed">
                  If you miss a prayer due to unintentional sleep (<span
                    class="font-semibold text-slate-300"
                    >Nawm</span
                  >) or genuine forgetfulness (<span class="font-semibold text-slate-300"
                    >Nisyan</span
                  >), you are not sinful for missing the time. However, the Prophet ﷺ stated:
                  <em
                    >"Whoever forgets a prayer or sleeps through it, let him pray it when he
                    remembers it."</em
                  >
                  Thus, making up the prayer (Qaza) remains obligatory.
                </p>
              </div>

              <!-- Category 2: Unexcused & Obligatory -->
              <div class="p-4 rounded-2xl bg-rose-500/5 border border-rose-500/10">
                <div class="flex items-center gap-2 text-rose-400 font-bold text-sm">
                  <span>⚠️</span>
                  <span>Unexcused (Ghayr Ma'dhur) — Neglect & Distraction</span>
                </div>
                <p class="text-slate-400 text-xs mt-2 leading-relaxed">
                  Missing a prayer due to worldly preoccupation (<span
                    class="font-semibold text-slate-300"
                    >Shughl</span
                  >), laziness (<span class="font-semibold text-slate-300">Kasl</span>), or
                  distraction/heedlessness (<span class="font-semibold text-slate-300">Ghaflah</span
                  >) is a major sin. In addition to sincere repentance (Tawbah), the prayer must
                  still be made up as Qaza as soon as possible.
                </p>
              </div>

              <!-- Category 3: Lifted Obligation -->
              <div class="p-4 rounded-2xl bg-emerald-500/5 border border-emerald-500/10">
                <div class="flex items-center gap-2 text-emerald-400 font-bold text-sm">
                  <span>✨</span>
                  <span>Excused Absence — Ritual Impurity</span>
                </div>
                <p class="text-slate-400 text-xs mt-2 leading-relaxed">
                  During menstruation (<span class="font-semibold text-slate-300">Hayd</span>) or
                  post-natal bleeding (<span class="font-semibold text-slate-300">Nifas</span>),
                  women are legally exempted from praying. No sin is incurred, and
                  <strong>no Qaza is required</strong>. The platform automatically excludes these
                  days from obligated prayer ratios.
                </p>
              </div>
            </div>
          </div>

          <!-- TAB 2: PUNCTUALITY -->
          <div v-if="activeTab === 'punctuality'" class="space-y-6 animate-fade-in">
            <div class="flex items-center gap-3 border-b border-slate-800/80 pb-4">
              <span class="text-2xl">⏳</span>
              <div>
                <h2 class="text-xl font-bold text-slate-100">Waqt & Punctuality Windows</h2>
                <p class="text-xs text-slate-500">The classification of prayer timings.</p>
              </div>
            </div>

            <p class="text-slate-300 text-sm leading-relaxed">
              Praying at the beginning of its time is highly beloved in Islam. The platform lets you
              log your punctuality based on the three classical segments of a prayer's Waqt:
            </p>

            <div class="relative border-l-2 border-slate-800 pl-6 ml-3 space-y-6 py-2">
              <!-- Waqt 1 -->
              <div class="relative">
                <span
                  class="absolute -left-[31px] top-1.5 flex h-4 w-4 rounded-full bg-emerald-500 ring-4 ring-emerald-950"
                ></span>
                <h3 class="text-emerald-400 font-bold text-sm sm:text-base">
                  Awwal al-Waqt (First Part)
                </h3>
                <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                  Offered within the first 15 to 20 minutes following the Adhan. This reflects
                  maximum zeal, follows the Sunnah closely, and carries the highest spiritual
                  reward.
                </p>
              </div>

              <!-- Waqt 2 -->
              <div class="relative">
                <span
                  class="absolute -left-[31px] top-1.5 flex h-4 w-4 rounded-full bg-indigo-500 ring-4 ring-indigo-950"
                ></span>
                <h3 class="text-indigo-400 font-bold text-sm sm:text-base">
                  Wast al-Waqt (Middle Part)
                </h3>
                <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                  Offered during the middle portion of the prayer window. It represents timely
                  compliance before busy periods take over.
                </p>
              </div>

              <!-- Waqt 3 -->
              <div class="relative">
                <span
                  class="absolute -left-[31px] top-1.5 flex h-4 w-4 rounded-full bg-amber-500 ring-4 ring-amber-950"
                ></span>
                <h3 class="text-amber-400 font-bold text-sm sm:text-base">
                  Akhir al-Waqt (Late Part)
                </h3>
                <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                  Offered near the end of the prayer window, just before the next prayer's time
                  begins (or before solar thresholds like Makruh times). Valid but discouraged to
                  make a habit of delaying.
                </p>
              </div>
            </div>
          </div>

          <!-- TAB 3: APP USAGE -->
          <div v-if="activeTab === 'app-usage'" class="space-y-6 animate-fade-in">
            <div class="flex items-center gap-3 border-b border-slate-800/80 pb-4">
              <span class="text-2xl">📱</span>
              <div>
                <h2 class="text-xl font-bold text-slate-100">Using the Iqamah Platform</h2>
                <p class="text-xs text-slate-500">How to navigate and log your prayer data.</p>
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
                  <h4 class="text-slate-200 font-semibold text-sm">Logging Daily Salah</h4>
                  <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                    On the main Dashboard, select a date from the calendar strip, then click **Log**
                    next to any prayer. Mark whether you offered it, congregation status
                    (**Jamaah**), travel status (**Musafir**), or if it was missed, pick a
                    situational **Missed Reason**.
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
                  <h4 class="text-slate-200 font-semibold text-sm">Paying Off Qaza Debts</h4>
                  <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                    Any missed prayer (except for Ritual Impurity) creates a pending entry in the
                    **Qaza** page. Once you make up that prayer, click **Fulfill** in the ledger to
                    mark it as offered, automatically updating your charts.
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
                    Understanding Analytics & Ratios
                  </h4>
                  <p class="text-slate-400 text-xs mt-1 leading-relaxed">
                    The Dial Gauge on the **Analytics** page calculates your Offered Ratio
                    mathematically:
                    <br />
                    <code
                      class="text-indigo-300 text-[10px] block mt-1 bg-slate-900/60 p-2 rounded-lg border border-slate-800"
                    >
                      Offered % = Total Offered / (Total Obligated - Impurity Days)
                    </code>
                    This ensures you always get jurisprudentially accurate percentages matching your
                    actual religious obligations.
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
