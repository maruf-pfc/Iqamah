<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useLocaleStore } from '@/stores/locale'

const router = useRouter()
const localeStore = useLocaleStore()
const activeTab = ref('qaza-rules')
</script>

<template>
  <div class="px-6 space-y-6">
    <!-- Header with Back Button -->
    <div class="flex items-center gap-3 pt-4">
      <button 
        @click="router.push('/settings')"
        class="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-700 dark:text-slate-300 cursor-pointer"
      >
        <span class="material-symbols-rounded">arrow_back</span>
      </button>
      <div>
        <h1 class="text-xl font-bold text-slate-900 dark:text-white">সালাত ও কাজার নিয়মাবলী</h1>
        <p class="text-[11px] text-slate-400 dark:text-slate-500 font-semibold">
          ইসলামী ফিকহ ও অ্যাপ ব্যবহার নির্দেশিকা
        </p>
      </div>
    </div>

    <!-- Segmented Tab Controls -->
    <div class="bg-m3-surface dark:bg-m3-dark-surface p-1 rounded-2xl border border-slate-200/50 dark:border-slate-800/80 shadow-sm flex">
      <button 
        @click="activeTab = 'qaza-rules'"
        :class="[activeTab === 'qaza-rules' ? 'bg-m3-primary dark:bg-m3-dark-primary text-white shadow' : 'text-slate-650 dark:text-slate-400']"
        class="flex-1 text-center py-2.5 text-xs font-bold rounded-xl transition-all cursor-pointer"
      >
        কাজা নীতিমালা
      </button>
      <button 
        @click="activeTab = 'punctuality'"
        :class="[activeTab === 'punctuality' ? 'bg-m3-primary dark:bg-m3-dark-primary text-white shadow' : 'text-slate-650 dark:text-slate-400']"
        class="flex-1 text-center py-2.5 text-xs font-bold rounded-xl transition-all cursor-pointer"
      >
        সময়ানুবর্তিতা
      </button>
      <button 
        @click="activeTab = 'app-usage'"
        :class="[activeTab === 'app-usage' ? 'bg-m3-primary dark:bg-m3-dark-primary text-white shadow' : 'text-slate-650 dark:text-slate-400']"
        class="flex-1 text-center py-2.5 text-xs font-bold rounded-xl transition-all cursor-pointer"
      >
        অ্যাপ ব্যবহার
      </button>
    </div>

    <!-- Content Panel -->
    <div class="bg-m3-surface dark:bg-m3-dark-surface rounded-[32px] p-6 border border-slate-200/50 dark:border-slate-800/80 shadow-sm space-y-6">
      
      <!-- TAB 1: QAZA RULES -->
      <div v-if="activeTab === 'qaza-rules'" class="space-y-5 animate-fade-in">
        <div class="flex items-center gap-3 border-b border-slate-100 dark:border-slate-800 pb-3">
          <span class="text-2xl">⚖️</span>
          <div>
            <h2 class="font-bold text-slate-900 dark:text-white text-base">সালাত কাজা হওয়ার শরয়ী হুকুম</h2>
            <p class="text-[11px] text-slate-400 dark:text-slate-500 font-semibold">কখন এবং কিভাবে কাজা সালাত আদায় করবেন</p>
          </div>
        </div>

        <p class="text-slate-600 dark:text-slate-350 text-xs leading-relaxed">
          ইসলামী বিধান অনুযায়ী সাময়িকভাবে ওজর বা অবহেলার কারণে ফরজ সালাত ছুটে গেলে তা পরবর্তীতে আদায় করাকে 'কাজা' বলা হয়। সালাত কাজা হওয়ার কারণসমূহ ফিকহী দৃষ্টিতে ৩টি শ্রেণীতে বিভক্ত:
        </p>

        <div class="space-y-3">
          <!-- Sleep -->
          <div class="p-4 rounded-2xl bg-amber-500/5 border border-amber-500/10">
            <span class="text-xs font-bold text-amber-700 dark:text-amber-400 flex items-center gap-1.5">
              <span>💤</span> ঘুম ও অসচেতনতা
            </span>
            <p class="text-slate-500 dark:text-slate-455 text-[11px] mt-1.5 leading-relaxed">
              যদি কেউ ঘুম বা অনিচ্ছাকৃত ভুলে যাওয়ার কারণে ওয়াক্ত পার করে ফেলে, তবে মনে পড়ার সাথে সাথেই সালাত আদায় করা ফরজ। এটি ক্ষমাযোগ্য ওজর হিসেবে গণ্য হলেও কাজা আদায় করা বাধ্যতামূলক।
            </p>
          </div>

          <!-- Laziness -->
          <div class="p-4 rounded-2xl bg-rose-500/5 border border-rose-500/10">
            <span class="text-xs font-bold text-rose-700 dark:text-rose-400 flex items-center gap-1.5">
              <span>⚠️</span> অলসতা বা অবহেলা
            </span>
            <p class="text-slate-500 dark:text-slate-455 text-[11px] mt-1.5 leading-relaxed">
              ইচ্ছাকৃতভাবে বা অবহেলা করে সালাত পরিত্যাগ করা একটি কবিরা গুনাহ। এর জন্য তাওবা ও ইস্তিগফার করার পাশাপাশি বকেয়া কাজা সালাত অতি দ্রুত আদায় করা ফরজ।
            </p>
          </div>

          <!-- Menstruation -->
          <div class="p-4 rounded-2xl bg-emerald-500/5 border border-emerald-500/10">
            <span class="text-xs font-bold text-emerald-700 dark:text-emerald-400 flex items-center gap-1.5">
              <span>🌸</span> হায়েজ ও নিফাস (নারীদের জন্য)
            </span>
            <p class="text-slate-500 dark:text-slate-455 text-[11px] mt-1.5 leading-relaxed">
              ঋতুস্রাব (হায়েজ) অথবা সন্তান প্রসব পরবর্তী অপবিত্রতার (নিফাস) দিনগুলোতে নারীদের জন্য নামাজ আদায় করা সম্পূর্ণ নিষেধ এবং এই সালাতসমূহের কোনো কাজা আদায় করতে হয় না।
            </p>
          </div>
        </div>
      </div>

      <!-- TAB 2: PUNCTUALITY -->
      <div v-if="activeTab === 'punctuality'" class="space-y-5 animate-fade-in">
        <div class="flex items-center gap-3 border-b border-slate-100 dark:border-slate-800 pb-3">
          <span class="text-2xl">⏳</span>
          <div>
            <h2 class="font-bold text-slate-900 dark:text-white text-base">ওয়াক্তের সময়ানুবর্তিতা</h2>
            <p class="text-[11px] text-slate-400 dark:text-slate-500 font-semibold">ওয়াক্তের মধ্যে নামাজ আদায়ে সময়ের গুরুত্ব</p>
          </div>
        </div>

        <p class="text-slate-600 dark:text-slate-350 text-xs leading-relaxed">
          ফরজ নামাজসমূহ নির্দিষ্ট সময়ে আদায় করা মুমিনদের জন্য অত্যন্ত গুরুত্বপূর্ণ। সালাত আদায়ে সময়ের অগ্রাধিকারে ৩টি স্তর রয়েছে:
        </p>

        <div class="relative border-l-2 border-slate-200 dark:border-slate-800 pl-6 ml-3 space-y-5 py-1">
          <!-- Awwal -->
          <div class="relative">
            <span class="absolute -left-[31px] top-1.5 flex h-4 w-4 rounded-full bg-teal-600 ring-4 ring-teal-500/10"></span>
            <span class="font-bold text-slate-850 dark:text-slate-200 text-sm block">আউয়াল ওয়াক্ত (প্রথম অংশ)</span>
            <p class="text-slate-500 dark:text-slate-455 text-[11px] mt-1 leading-relaxed">
              ওয়াক্ত শুরু হওয়ার প্রথম এক-তৃতীয়াংশের মধ্যে নামাজ আদায় করাকে আউয়াল ওয়াক্ত বলা হয়। এটি সর্বোত্তম সময় এবং সর্বাধিক সাওয়াব অর্জনের অন্যতম উপায়।
            </p>
          </div>

          <!-- Wast -->
          <div class="relative">
            <span class="absolute -left-[31px] top-1.5 flex h-4 w-4 rounded-full bg-amber-500 ring-4 ring-amber-500/10"></span>
            <span class="font-bold text-slate-850 dark:text-slate-200 text-sm block">ওয়াসাত ওয়াক্ত (মধ্যবর্তী অংশ)</span>
            <p class="text-slate-500 dark:text-slate-455 text-[11px] mt-1 leading-relaxed">
              ওয়াক্তের মধ্যবর্তী অংশে নামাজ আদায় করা। প্রথম অংশে আদায়ে ব্যর্থ হলে এই সময়ে আদায় করা উত্তম।
            </p>
          </div>

          <!-- Akhir -->
          <div class="relative">
            <span class="absolute -left-[31px] top-1.5 flex h-4 w-4 rounded-full bg-rose-500 ring-4 ring-rose-500/10"></span>
            <span class="font-bold text-slate-850 dark:text-slate-200 text-sm block">আখির ওয়াক্ত (শেষ অংশ)</span>
            <p class="text-slate-500 dark:text-slate-455 text-[11px] mt-1 leading-relaxed">
              ওয়াক্ত শেষ হওয়ার ঠিক পূর্ববর্তী সময়। মাকরূহ বা নিষিদ্ধ সময়ে নামাজ ঝুলিয়ে রাখা অনুচিত, তবে ওয়াক্ত শেষ হওয়ার পূর্বে আদায় করলে নামাজ আদায় হয়ে যাবে।
            </p>
          </div>
        </div>
      </div>

      <!-- TAB 3: APP USAGE -->
      <div v-if="activeTab === 'app-usage'" class="space-y-5 animate-fade-in">
        <div class="flex items-center gap-3 border-b border-slate-100 dark:border-slate-800 pb-3">
          <span class="text-2xl">📱</span>
          <div>
            <h2 class="font-bold text-slate-900 dark:text-white text-base">ইকামা প্ল্যাটফর্ম ব্যবহার নির্দেশিকা</h2>
            <p class="text-[11px] text-slate-400 dark:text-slate-500 font-semibold">কিভাবে অ্যাপ ব্যবহার করে সালাত অভ্যাস গড়বেন</p>
          </div>
        </div>

        <div class="space-y-4">
          <!-- Step 1 -->
          <div class="flex gap-3 items-start">
            <div class="h-6 w-6 rounded-lg bg-teal-500/10 border border-teal-500/25 text-teal-650 dark:text-teal-400 flex items-center justify-center font-bold text-xs flex-shrink-0 mt-0.5">
              ১
            </div>
            <div>
              <h4 class="text-slate-800 dark:text-slate-200 font-bold text-xs">আজকের ড্যাশবোর্ডে নামাজ ট্র্যাকিং</h4>
              <p class="text-slate-500 dark:text-slate-455 text-[11px] mt-1 leading-relaxed">
                প্রতিটি সালাত আদায়ের পর ড্যাশবোর্ডের কার্ডে একটি আলতো টোকা (Single Tap) দিয়ে দ্রুত তা আদায় হিসেবে চিহ্নিত করতে পারেন। আর বিস্তারিত এন্ট্রির জন্য ডানপাশে থাকা এডিট বাটনে ক্লিক করুন।
              </p>
            </div>
          </div>

          <!-- Step 2 -->
          <div class="flex gap-3 items-start">
            <div class="h-6 w-6 rounded-lg bg-teal-500/10 border border-teal-500/25 text-teal-650 dark:text-teal-400 flex items-center justify-center font-bold text-xs flex-shrink-0 mt-0.5">
              ২
            </div>
            <div>
              <h4 class="text-slate-800 dark:text-slate-200 font-bold text-xs">কাজা নামাজ সমাধান করা</h4>
              <p class="text-slate-500 dark:text-slate-455 text-[11px] mt-1 leading-relaxed">
                ছুটে যাওয়া সালাতগুলো স্বয়ংক্রিয়ভাবে কাজা খতিয়ানে জমা হয়। কাজা আদায়ের পর খতিয়ান বা 'রেকর্ড' ট্যাবে এসে 'আদায় করুন' বাটনে চাপ দিলে তা বকেয়া হিসাব থেকে বাদ যাবে।
              </p>
            </div>
          </div>

          <!-- Step 3 -->
          <div class="flex gap-3 items-start">
            <div class="h-6 w-6 rounded-lg bg-teal-500/10 border border-teal-500/25 text-teal-650 dark:text-teal-400 flex items-center justify-center font-bold text-xs flex-shrink-0 mt-0.5">
              ৩
            </div>
            <div>
              <h4 class="text-slate-800 dark:text-slate-200 font-bold text-xs">অগ্রগতি পর্যবেক্ষণ করা</h4>
              <p class="text-slate-500 dark:text-slate-455 text-[11px] mt-1 leading-relaxed">
                'অগ্রগতি' বা অ্যানালিটিক্স ট্যাব ব্যবহার করে আপনার বিগত ১ সপ্তাহ বা ১ মাসের নামাজের অনুপাত ও সময়ানুবর্তিতা গ্রাফে দেখে অভ্যাস উন্নত করতে পারেন।
              </p>
            </div>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

<style scoped>
.animate-fade-in {
  animation: fadeIn 0.25s ease-out forwards;
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
