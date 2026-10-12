<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useLocaleStore } from '@/stores/locale'

const router = useRouter()
const locale = useLocaleStore()
const activeTab = ref<'qaza-rules' | 'timing-accuracy' | 'punctuality' | 'app-usage' | 'data-privacy'>('qaza-rules')
</script>

<template>
  <div class="iq-help px-6 space-y-6 pb-12">
    <!-- Header with Back Button -->
    <div class="flex items-center gap-3 pt-4">
      <button 
        @click="router.push('/settings')"
        class="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-700 dark:text-slate-300 cursor-pointer"
        :aria-label="locale.currentLocale === 'bn' ? 'ফিরে যান' : 'Go back'"
      >
        <span class="material-symbols-rounded">arrow_back</span>
      </button>
      <div>
        <h1 class="text-xl font-bold text-slate-900 dark:text-white">
          {{ locale.currentLocale === 'bn' ? 'সালাত ও কাজার পূর্ণাঙ্গ নির্দেশিকা' : 'Salah & Qaza Complete Guide' }}
        </h1>
        <p class="text-[11px] text-slate-400 dark:text-slate-500 font-semibold">
          {{ locale.currentLocale === 'bn' ? 'ইসলামী ফিকহ, নামাজের সময় ও তথ্য সুরক্ষা' : 'Islamic Fiqh, Prayer Timings & Data Privacy' }}
        </p>
      </div>
    </div>

    <!-- Segmented Tab Controls -->
    <div class="bg-m3-surface dark:bg-m3-dark-surface p-1 rounded-2xl border border-slate-200/50 dark:border-slate-800/80 shadow-sm flex flex-wrap gap-1">
      <button 
        @click="activeTab = 'qaza-rules'"
        :class="[activeTab === 'qaza-rules' ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 shadow font-bold' : 'text-slate-700 dark:text-slate-200']"
        class="flex-1 min-w-[100px] text-center py-2.5 text-xs font-bold rounded-xl transition-all cursor-pointer"
      >
        {{ locale.currentLocale === 'bn' ? 'কাজা নীতিমালা' : 'Qaza Rules' }}
      </button>
      <button 
        @click="activeTab = 'timing-accuracy'"
        :class="[activeTab === 'timing-accuracy' ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 shadow font-bold' : 'text-slate-700 dark:text-slate-200']"
        class="flex-1 min-w-[100px] text-center py-2.5 text-xs font-bold rounded-xl transition-all cursor-pointer"
      >
        {{ locale.currentLocale === 'bn' ? 'সময় ও নির্ভুলতা' : 'Timings & Accuracy' }}
      </button>
      <button 
        @click="activeTab = 'punctuality'"
        :class="[activeTab === 'punctuality' ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 shadow font-bold' : 'text-slate-700 dark:text-slate-200']"
        class="flex-1 min-w-[100px] text-center py-2.5 text-xs font-bold rounded-xl transition-all cursor-pointer"
      >
        {{ locale.currentLocale === 'bn' ? 'ওয়াক্তের স্তর' : 'Waqt Stages' }}
      </button>
      <button 
        @click="activeTab = 'app-usage'"
        :class="[activeTab === 'app-usage' ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 shadow font-bold' : 'text-slate-700 dark:text-slate-200']"
        class="flex-1 min-w-[100px] text-center py-2.5 text-xs font-bold rounded-xl transition-all cursor-pointer"
      >
        {{ locale.currentLocale === 'bn' ? 'ব্যবহারবিধি' : 'How to Use' }}
      </button>
      <button 
        @click="activeTab = 'data-privacy'"
        :class="[activeTab === 'data-privacy' ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900 shadow font-bold' : 'text-slate-700 dark:text-slate-200']"
        class="flex-1 min-w-[100px] text-center py-2.5 text-xs font-bold rounded-xl transition-all cursor-pointer"
      >
        {{ locale.currentLocale === 'bn' ? 'ব্যাকআপ ও নিরাপত্তা' : 'Data & Backups' }}
      </button>
    </div>

    <!-- Content Panel -->
    <div class="bg-m3-surface dark:bg-m3-dark-surface rounded-[32px] p-6 border border-slate-200/50 dark:border-slate-800/80 shadow-sm space-y-6">
      
      <!-- TAB 1: QAZA RULES -->
      <div v-if="activeTab === 'qaza-rules'" class="space-y-5 animate-fade-in">
        <div class="flex items-center gap-3 border-b border-slate-100 dark:border-slate-800 pb-3">
          <span class="text-2xl">⚖️</span>
          <div>
            <h2 class="font-bold text-slate-900 dark:text-white text-base">
              {{ locale.currentLocale === 'bn' ? 'সালাত কাজা হওয়ার শরয়ী হুকুম' : 'Islamic Rulings on Missed Prayers (Qaza)' }}
            </h2>
            <p class="text-[11px] text-slate-400 dark:text-slate-500 font-semibold">
              {{ locale.currentLocale === 'bn' ? 'কখন এবং কিভাবে কাজা সালাত আদায় করবেন' : 'When and how to fulfill missed obligations' }}
            </p>
          </div>
        </div>

        <p class="text-slate-600 dark:text-slate-350 text-xs leading-relaxed">
          {{ locale.currentLocale === 'bn' 
            ? 'ইসলামী ফিকহ অনুযায়ী ওজর বা অনবধানতার কারণে ফরজ সালাতের ওয়াক্ত পার হয়ে গেলে তা পরবর্তীতে আদায় করাকে \'কাজা\' বলা হয়। ক্ষমাযোগ্য ওজরের ক্ষেত্রে গুনাহ না হলেও সালাত আদায় করার আবশ্যকতা রহিত হয় না।' 
            : 'According to Islamic jurisprudence, performing an obligatory prayer after its designated time has expired is known as Qaza. An unintentional excuse removes sin but does not remove the obligation to perform the prayer.' }}
        </p>

        <div class="space-y-3">
          <!-- Sleep & Forgetfulness -->
          <div class="p-4 rounded-2xl bg-amber-500/5 border border-amber-500/10">
            <span class="text-xs font-bold text-amber-700 dark:text-amber-400 flex items-center gap-1.5">
              <span>💤</span> {{ locale.currentLocale === 'bn' ? 'ঘুম ও অনিচ্ছাকৃত ভুল' : 'Sleep & Unintentional Forgetfulness' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1.5 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'রাসূলুল্লাহ ﷺ বলেছেন: "যে ব্যক্তি নামাজের কথা ভুলে যায় বা ঘুমিয়ে থাকে, তার কাফফারা হলো স্মরণ হওয়ামাত্রই তা আদায় করা" (সহীহ বুখারী ৫৯৭)। এটি ক্ষমাযোগ্য ওজর হলেও সালাতের কাজা আদায় করা ফরজ।'
                : 'The Prophet ﷺ said: "Whoever forgets a prayer or sleeps through it, its expiation is that he prays it when he remembers it" (Sahih al-Bukhari 597). While blameless, Qaza remains strictly obligatory.' }}
            </p>
          </div>

          <!-- Laziness & Situational -->
          <div class="p-4 rounded-2xl bg-rose-500/5 border border-rose-500/10">
            <span class="text-xs font-bold text-rose-700 dark:text-rose-400 flex items-center gap-1.5">
              <span>⚠️</span> {{ locale.currentLocale === 'bn' ? 'অলসতা বা জাগতিক ব্যস্ততা' : 'Laziness & Situational Delays' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1.5 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'ইচ্ছাকৃতভাবে সালাত বিলম্বিত করা গুরুতর অন্যায়। এর জন্য খাঁটি মনে তাওবা ও ক্ষমা প্রার্থনার পাশাপাশি দ্রুততম সময়ে বকেয়া কাজা সালাত আদায় করা চার মাজহাবের সর্বসম্মত ফতোয়া।'
                : 'Intentionally delaying prayer without an excuse is a serious sin. Sincere repentance is required alongside immediate make-up (Qaza) according to the consensus of Sunni jurisprudence.' }}
            </p>
          </div>

          <!-- Hayd & Nifas -->
          <div class="p-4 rounded-2xl bg-emerald-500/5 border border-emerald-500/10">
            <span class="text-xs font-bold text-emerald-700 dark:text-emerald-400 flex items-center gap-1.5">
              <span>🌸</span> {{ locale.currentLocale === 'bn' ? 'হায়েজ ও নিফাস (মহিলাদের জন্য)' : 'Hayd & Nifas (For Women)' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1.5 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'ঋতুস্রাব (হায়েজ) বা প্রসবোত্তর অপবিত্রতার (নিফাস) দিনগুলোতে নামাজ আদায় সম্পূর্ণ নিষেধ এবং এই সময়ের সালাতসমূহের কোনো কাজা আদায় করতে হয় না।'
                : 'During menstruation (Hayd) and postnatal bleeding (Nifas), prayers are exempted entirely and no Qaza is required (Sahih Muslim 335).' }}
            </p>
          </div>
        </div>
      </div>

      <!-- TAB 2: TIMINGS & ACCURACY -->
      <div v-if="activeTab === 'timing-accuracy'" class="space-y-5 animate-fade-in">
        <div class="flex items-center gap-3 border-b border-slate-100 dark:border-slate-800 pb-3">
          <span class="text-2xl">🧭</span>
          <div>
            <h2 class="font-bold text-slate-900 dark:text-white text-base">
              {{ locale.currentLocale === 'bn' ? 'নামাজের সময় ও হিসাবের ভিত্তি' : 'Prayer Times & Calculation Methodology' }}
            </h2>
            <p class="text-[11px] text-slate-400 dark:text-slate-500 font-semibold">
              {{ locale.currentLocale === 'bn' ? 'অফলাইন জ্যোতির্বৈজ্ঞানিক আনুমানিক হিসাব' : 'Offline astronomical estimates' }}
            </p>
          </div>
        </div>

        <p class="text-slate-600 dark:text-slate-350 text-xs leading-relaxed">
          {{ locale.currentLocale === 'bn'
            ? 'ইকামা ৬৪ জেলার কমিউনিটি-উৎসের রেফারেন্স স্থানাঙ্ক দিয়ে অফলাইনে আনুমানিক সময় হিসাব করে। সরকারি উৎসের সাথে সব স্থানাঙ্ক ও সময় যাচাই এখনও সম্পূর্ণ হয়নি।'
            : 'Iqamah calculates offline estimates using community-sourced reference coordinates for 64 districts. Official coordinate and timetable verification is not complete.' }}
        </p>

        <div class="space-y-3">
          <div class="p-4 rounded-2xl bg-teal-500/5 border border-teal-500/15">
            <span class="text-xs font-bold text-teal-700 dark:text-teal-400">
              {{ locale.currentLocale === 'bn' ? '১. হিসাব পদ্ধতি (Calculation Method)' : '1. Calculation Conventions' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'ডিফল্ট করাচি পদ্ধতিতে ফজর ও ইশার জন্য ১৮° কোণ এবং হানাফী আসরের জন্য ছায়ার গুণক ২ ব্যবহৃত হয়। সেটিংসে পদ্ধতি বদলানো যায়। এটি IFB অনুমোদিত বা সরকারি সময়সূচির সাথে মিলেছে—এমন দাবি করা হচ্ছে না।'
                : 'The default Karachi method uses 18° for Fajr and Isha; Hanafi Asr uses shadow factor 2. Settings can change the method. IFB approval or agreement with official timetables has not been established.' }}
            </p>
          </div>

          <div class="p-4 rounded-2xl bg-amber-500/5 border border-amber-500/15">
            <span class="text-xs font-bold text-amber-700 dark:text-amber-400">
              {{ locale.currentLocale === 'bn' ? '২. আনুমানিক সতর্কতার সময়' : '2. Approximate caution windows' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'সূর্যোদয়ের পর ১৫ মিনিট, হিসাবকৃত যোহরের আগে ১০ মিনিট এবং সূর্যাস্তের আগে ২০ মিনিট দেখানো হয়। এগুলো অ্যাপের আনুমানিক সতর্কতার ব্যবধান, সর্বসম্মত ধর্মীয় সীমা নয়। বিভিন্ন সালাতের বিধান জানতে যোগ্য আলেমের পরামর্শ নিন।'
                : 'The app shows 15 minutes after sunrise, 10 minutes before calculated Dhuhr and 20 minutes before sunset. These are approximate advisory intervals, not universally agreed religious boundaries. Ask a qualified scholar about the rulings for different prayers.' }}
            </p>
          </div>

          <div class="p-4 rounded-2xl bg-slate-500/5 border border-slate-500/15">
            <span class="text-xs font-bold text-slate-700 dark:text-slate-300">
              {{ locale.currentLocale === 'bn' ? '৩. স্থানীয় মসজিদের সাথে ব্যবধান' : '3. Variance with Local Mosques' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'আপনার সঠিক অবস্থান, হিসাব পদ্ধতি ও প্রকাশিত সময়সূচির কারণে পার্থক্য হতে পারে। পার্থক্যের সর্বোচ্চ সীমা এখনও যাচাই করা হয়নি। স্থানীয় নির্ভরযোগ্য সময়সূচির সাথে মিলিয়ে নিন।'
                : 'Exact location, calculation convention and publication rules can cause differences. No verified maximum difference has been established. Compare with a trusted local timetable.' }}
            </p>
          </div>
        </div>
      </div>

      <!-- TAB 3: WAQT STAGES -->
      <div v-if="activeTab === 'punctuality'" class="space-y-5 animate-fade-in">
        <div class="flex items-center gap-3 border-b border-slate-100 dark:border-slate-800 pb-3">
          <span class="text-2xl">⏳</span>
          <div>
            <h2 class="font-bold text-slate-900 dark:text-white text-base">
              {{ locale.currentLocale === 'bn' ? 'ওয়াক্তের সময়ানুবর্তিতা ও স্তর' : 'Punctuality & Waqt Stages' }}
            </h2>
            <p class="text-[11px] text-slate-400 dark:text-slate-500 font-semibold">
              {{ locale.currentLocale === 'bn' ? 'ওয়াক্তের মধ্যে নামাজ আদায়ে সময়ের গুরুত্ব' : 'The merit of offering prayer in its early interval' }}
            </p>
          </div>
        </div>

        <div class="relative border-l-2 border-slate-200 dark:border-slate-800 pl-6 ml-3 space-y-5 py-1">
          <div>
            <span class="font-bold text-slate-800 dark:text-slate-200 text-sm block">
              {{ locale.currentLocale === 'bn' ? 'আউয়াল ওয়াক্ত (প্রথম অংশ)' : 'Awwal al-Waqt (Early Interval)' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'অ্যাপে এটি আপনার নির্বাচিত শুরুর দিকের সময়ানুবর্তিতার লেবেল। কোনো নির্দিষ্ট মিনিটকে সর্বোচ্চ সাওয়াবের সর্বজনীন সীমা হিসেবে ধরা হয় না; সালাতভেদে উপযুক্ত সময়ের জন্য আলেমের নির্দেশনা নিন।'
                : 'This is your selected early punctuality label. The app does not define a universal minute cutoff or measure religious reward; seek scholarly guidance about preferred times for each prayer.' }}
            </p>
          </div>

          <div>
            <span class="font-bold text-slate-800 dark:text-slate-200 text-sm block">
              {{ locale.currentLocale === 'bn' ? 'ওয়াসাত ওয়াক্ত (মধ্যবর্তী অংশ)' : 'Wast al-Waqt (Middle Interval)' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'ওয়াক্তের মধ্যবর্তী সময়ে আদায়। কোনো বিশেষ প্রয়োজনে প্রথম অংশে সম্ভব না হলে এ সময়ে আদায় করা যায়।'
                : 'Offering prayer in the middle of the window when delayed by legitimate daily responsibilities.' }}
            </p>
          </div>

          <div>
            <span class="font-bold text-slate-800 dark:text-slate-200 text-sm block">
              {{ locale.currentLocale === 'bn' ? 'আখির ওয়াক্ত (শেষ অংশ)' : 'Akhir al-Waqt (Final Interval)' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'ওয়াক্ত শেষ হওয়ার পূর্ববর্তী সময়। অকারণে শেষ সময় পর্যন্ত নামাজ ঝুলিয়ে রাখা উচিত নয়, তবে ওয়াক্ত থাকাকালীন আদায় করলে তা আদায় হিসেবেই গণ্য হবে।'
                : 'The period nearing the end of the Waqt. While valid as an in-time prayer, unexcused delay is strongly discouraged.' }}
            </p>
          </div>
        </div>
      </div>

      <!-- TAB 4: APP USAGE -->
      <div v-if="activeTab === 'app-usage'" class="space-y-5 animate-fade-in">
        <div class="flex items-center gap-3 border-b border-slate-100 dark:border-slate-800 pb-3">
          <span class="text-2xl">📱</span>
          <div>
            <h2 class="font-bold text-slate-900 dark:text-white text-base">
              {{ locale.currentLocale === 'bn' ? 'ইকামা ব্যবহারের নিয়মাবলী' : 'How to Use Iqamah Daily' }}
            </h2>
            <p class="text-[11px] text-slate-400 dark:text-slate-500 font-semibold">
              {{ locale.currentLocale === 'bn' ? 'সালাত ট্র্যাকিং, জামা\'আত, তাসবীহ ও কুরআন নোট' : 'Logging prayers, Jama\'ah, Tasbih & Quran reflections' }}
            </p>
          </div>
        </div>

        <div class="space-y-4 text-xs">
          <div class="flex gap-3">
            <div class="w-6 h-6 rounded-full bg-teal-500/20 text-teal-600 dark:text-teal-400 flex items-center justify-center font-bold text-xs shrink-0">1</div>
            <div>
              <h4 class="font-bold text-slate-800 dark:text-slate-200">
                {{ locale.currentLocale === 'bn' ? 'হোম ড্যাশবোর্ডে সালাত ট্র্যাকিং' : 'Daily Dashboard Logging' }}
              </h4>
              <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
                {{ locale.currentLocale === 'bn'
                  ? 'নামাজ আদায়ের পর ড্যাশবোর্ডের কার্ডে এক ট্যাপে আদায় চিহ্নিত করুন অথবা এডিট বাটনে চেপে জামা\'আত, মুসাফির অবস্থা ও কুরআন পড়ার নোট সংরক্ষণ করুন।'
                  : 'Tap any prayer card to log completion, or click Edit to record congregation (Jama\'ah), travel status, Tasbih, and Quran reading notes.' }}
              </p>
            </div>
          </div>

          <div class="flex gap-3">
            <div class="w-6 h-6 rounded-full bg-teal-500/20 text-teal-600 dark:text-teal-400 flex items-center justify-center font-bold text-xs shrink-0">2</div>
            <div>
              <h4 class="font-bold text-slate-800 dark:text-slate-200">
                {{ locale.currentLocale === 'bn' ? 'কাজা সালাত পরিশোধ' : 'Resolving Qaza Debts' }}
              </h4>
              <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
                {{ locale.currentLocale === 'bn'
                  ? 'ছুটে যাওয়া সালাতগুলো স্বয়ংক্রিয়ভাবে কাজা খতিয়ানে জমা হয়। কাজা আদায়ের পর \'আদায় করুন\' বোতামে চাপ দিলে তা বকেয়া তালিকা থেকে নিষ্পত্তি হবে।'
                  : 'Missed prayers requiring compensation automatically generate entries in the Qaza ledger. Fulfill them with a single tap as you make them up.' }}
              </p>
            </div>
          </div>

          <div class="flex gap-3">
            <div class="w-6 h-6 rounded-full bg-teal-500/20 text-teal-600 dark:text-teal-400 flex items-center justify-center font-bold text-xs shrink-0">3</div>
            <div>
              <h4 class="font-bold text-slate-800 dark:text-slate-200">
                {{ locale.currentLocale === 'bn' ? 'সকল ৬৪ জেলার লাইভ ট্র্যাকার' : 'All-64 Districts Live Tracker' }}
              </h4>
              <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
                {{ locale.currentLocale === 'bn'
                  ? 'সালাত টাইম পেজ থেকে বাংলাদেশের যেকোনো জেলার বর্তমান ওয়াক্ত ও অবশিষ্ট সময় এক পলকে পর্যবেক্ষণ করতে পারবেন।'
                  : 'Inspect real-time active Waqts and remaining time across all 64 districts with division filters and dual search.' }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- TAB 5: DATA & PRIVACY -->
      <div v-if="activeTab === 'data-privacy'" class="space-y-5 animate-fade-in">
        <div class="flex items-center gap-3 border-b border-slate-100 dark:border-slate-800 pb-3">
          <span class="text-2xl">🔒</span>
          <div>
            <h2 class="font-bold text-slate-900 dark:text-white text-base">
              {{ locale.currentLocale === 'bn' ? 'তথ্য সুরক্ষা, ব্যাকআপ ও অ্যাপ আপডেট' : 'Data Privacy, Backups & App Updates' }}
            </h2>
            <p class="text-[11px] text-slate-400 dark:text-slate-500 font-semibold">
              {{ locale.currentLocale === 'bn' ? 'আপনার ব্যক্তিগত তথ্যের নিরাপত্তা শতভাগ আপনার ডিভাইসে' : 'Your spiritual records remain 100% on your device' }}
            </p>
          </div>
        </div>

        <div class="space-y-3">
          <div class="p-4 rounded-2xl bg-teal-500/5 border border-teal-500/15">
            <span class="text-xs font-bold text-teal-700 dark:text-teal-400">
              {{ locale.currentLocale === 'bn' ? '১. শূন্য ট্র্যাকিং ও অফলাইন নিশ্চয়তা' : '1. Zero Tracking & Offline Guarantee' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'ইকামা কোনো ক্লাউড সার্ভারে আপনার তথ্য পাঠায় না। কোনো ট্র্যাকিং SDK, বিজ্ঞাপন বা অ্যানালিটিক্স নেই।'
                : 'Iqamah collects zero telemetry, shows zero ads, and never transmits your prayer history or personal notes to any remote server.' }}
            </p>
          </div>

          <div class="p-4 rounded-2xl bg-amber-500/5 border border-amber-500/15">
            <span class="text-xs font-bold text-amber-700 dark:text-amber-400">
              {{ locale.currentLocale === 'bn' ? '২. নিয়মিত ব্যাকআপ নেওয়া আবশ্যক' : '2. Creating & Storing Backups' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'সেটিংসে “আমার ডেটার ব্যাকআপ নিন” চাপুন। মোবাইলে শেয়ার মেনু দিয়ে ফাইলটি অ্যাপের বাইরে নিরাপদ স্থানে রাখুন। ওয়েবে ডাউনলোড সম্পন্ন হয়েছে কিনা যাচাই করুন। ব্যাকআপে ব্যক্তিগত নোট থাকে; অনলাইন সেবা ব্যবহার সম্পূর্ণ আপনার পছন্দ।'
                : 'In Settings, tap “Back Up My Data”. On mobile, use the share sheet to keep the file safely outside the app. On web, check the download completed. Backups include private notes; using an online service is entirely your choice.' }}
            </p>
          </div>

          <div class="p-4 rounded-2xl bg-sky-500/5 border border-sky-500/15">
            <span class="text-xs font-bold text-sky-700 dark:text-sky-400">
              {{ locale.currentLocale === 'bn' ? '৩. আনইনস্টল ছাড়া সাধারণ আপডেট' : '3. Upgrading Without Uninstalling' }}
            </span>
            <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1 leading-relaxed">
              {{ locale.currentLocale === 'bn'
                ? 'সামঞ্জস্যপূর্ণ আপডেটে অ্যাপ আনইনস্টল করার কথা নয়। একই প্যাকেজ ও সাইনিং পরিচয় দরকার; এই বেটার প্রকৃত আপগ্রেড পরীক্ষা এখনও হয়নি। আগে ব্যাকআপ নিন। সেটিংসে সংস্করণ দেখুন। পুনরুদ্ধার ত্রুটি হলে ডেটা মুছবেন না; স্টোরেজ খালি করে আবার খুলুন।'
                : 'Compatible updates should not require uninstalling. The same package and signing identity are required; an actual upgrade test for this beta is still pending. Back up first and check the version in Settings. On recovery errors, do not clear app data; free storage and reopen.' }}
            </p>
          </div>
        </div>

        <!-- Scholarly Disclaimer -->
        <div class="iq-surface space-y-3">
          <h3 class="iq-section-heading">{{ locale.currentLocale === 'bn' ? 'ডেটা কোথায় থাকে ও কীভাবে রিস্টোর করবেন' : 'Storage and restoration' }}</h3>
          <p>{{ locale.currentLocale === 'bn' ? 'বর্তমান মোবাইল অ্যাপের ডেটা WebView LocalStorage-এ থাকে; পুরোনো SQLite ডেটা স্বয়ংক্রিয়ভাবে একত্র করা হয় না। আনইনস্টল, ডিভাইস রিসেট বা হারিয়ে গেলে ডেটা নষ্ট হতে পারে।' : 'The active mobile app stores data in WebView LocalStorage. Historical SQLite data is not automatically merged. Uninstalling, device reset or device loss can destroy local records.' }}</p>
          <p>{{ locale.currentLocale === 'bn' ? 'সেটিংসে ব্যাকআপ রিস্টোর করুন চাপুন, JSON ফাইল বেছে নিন ও পর্যালোচনা করুন। মার্জে বিরোধহীন রেকর্ড যোগ হয়। প্রতিস্থাপন সব নামাজের রেকর্ড বদলায়; আগে বর্তমান ডেটার ব্যাকআপ নিন। নিশ্চিত করার পর অ্যাপ আবার লোড হবে।' : 'Tap Restore Backup in Settings, select the JSON file and review it. Merge adds compatible records; Replace changes all prayer records. Back up current data before replacement. After confirmation, the app reloads.' }}</p>
        </div>
        <div class="p-4 rounded-2xl bg-slate-500/10 border border-slate-500/20 mt-4">
          <span class="text-xs font-bold text-slate-800 dark:text-slate-200 flex items-center gap-1.5">
            <span>📖</span> {{ locale.currentLocale === 'bn' ? 'শরয়ী ও আইনি সতর্কতা' : 'Scholarly & Religious Disclaimer' }}
          </span>
          <p class="text-slate-500 dark:text-slate-400 text-[11px] mt-1.5 leading-relaxed">
            {{ locale.currentLocale === 'bn'
              ? 'ইকামা একটি সহায়ক অভ্যাস ট্র্যাকিং ও হিসাব টুল। এটি কোনো ফতোয়া বা বিজ্ঞ আলেমের বিকল্প নয়। আপনার বিশেষ কোনো দ্বীনি মাসআলা বা জটিল কাজা হিসাবের ক্ষেত্রে আপনার স্থানীয় বিশ্বস্ত উলামায়ে কেরামের সাথে পরামর্শ করুন।'
              : 'Iqamah is a calculation and personal accountability aid, not a religious authority or substitute for scholarly fatwas. Consult local scholars for complex religious queries.' }}
          </p>
        </div>
      </div>

    </div>
  </div>
</template>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.2s ease-out forwards;
}
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
