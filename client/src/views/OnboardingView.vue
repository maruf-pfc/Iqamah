<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useLocaleStore } from '@/stores/locale'

const router = useRouter()
const authStore = useAuthStore()
const localeStore = useLocaleStore()

const selectedGender = ref<'male' | 'female'>('male')
const selectedLanguage = ref<'en' | 'bn'>('en')
const username = ref('')

// Initialize from existing local state if any
const existingGender = localStorage.getItem('iqamah_user_g')
if (existingGender === 'm' || existingGender === 'f') {
  selectedGender.value = existingGender === 'f' ? 'female' : 'male'
}

const existingLang = localStorage.getItem('iqamah_locale')
if (existingLang === 'en' || existingLang === 'bn') {
  selectedLanguage.value = existingLang
  localeStore.setLocale(existingLang)
}

const selectLanguage = (lang: 'en' | 'bn') => {
  selectedLanguage.value = lang
  localeStore.setLocale(lang)
}

const selectGender = (gender: 'male' | 'female') => {
  selectedGender.value = gender
}

const handleStart = () => {
  authStore.completeOnboarding(selectedGender.value, selectedLanguage.value, username.value)
  router.push('/')
}
</script>

<template>
  <div class="px-6 py-10 min-h-[750px] flex flex-col justify-between max-w-md mx-auto">
    <!-- Top Header / Branding -->
    <div class="space-y-6 text-center mt-6">
      <div class="w-24 h-24 mx-auto rounded-[32px] bg-teal-500/10 dark:bg-teal-500/20 flex items-center justify-center text-teal-650 dark:text-teal-400 shadow-inner">
        <span class="material-symbols-rounded text-6xl">mosque</span>
      </div>
      <div class="space-y-2">
        <h1 class="text-4xl font-extrabold text-slate-900 dark:text-white font-serif flex items-center justify-center gap-3">
          <span class="font-arabic text-teal-650 dark:text-teal-400 text-5xl">إقامة</span>
          <span>ইকামা</span>
        </h1>
        <p class="text-xs text-slate-600 dark:text-slate-300 font-bold max-w-[290px] mx-auto leading-relaxed">
          {{ selectedLanguage === 'bn' 
            ? 'আপনার নামাজ ও কাজা সালাত ট্র্যাকিংয়ের মাধ্যমে অভ্যাস গড়ে তোলার ইসলামিক ডায়েরি।' 
            : 'Your personal Islamic diary to build consistent Salah habits and track make-up prayers.' }}
        </p>
      </div>
    </div>

    <!-- Onboarding Selection Card -->
    <div class="bg-white dark:bg-slate-900 p-6 rounded-[32px] border border-slate-200 dark:border-slate-700 shadow-lg space-y-6 mt-6">
      <!-- Title -->
      <h2 class="text-xl font-extrabold text-slate-900 dark:text-slate-100 text-center">
        {{ selectedLanguage === 'bn' ? 'আসুন শুরু করা যাক!' : 'Let\'s Get Started!' }}
      </h2>

      <!-- Language Selector -->
      <div class="space-y-2">
        <label class="text-[10px] font-extrabold text-slate-600 dark:text-slate-300 uppercase tracking-widest block">
          {{ selectedLanguage === 'bn' ? 'ভাষা নির্বাচন করুন' : 'Select Language' }}
        </label>
        <div class="grid grid-cols-2 gap-2 p-1 bg-slate-200 dark:bg-slate-950 rounded-2xl">
          <button 
            type="button"
            @click="selectLanguage('bn')"
            :class="[selectedLanguage === 'bn' 
              ? 'bg-teal-600 text-white dark:bg-teal-500 dark:text-slate-950 shadow-md font-bold' 
              : 'bg-transparent text-slate-700 dark:text-slate-200 hover:text-slate-900 dark:hover:text-white font-semibold']"
            class="py-2.5 text-xs rounded-xl transition-all duration-200 cursor-pointer"
          >
            বাংলা
          </button>
          <button 
            type="button"
            @click="selectLanguage('en')"
            :class="[selectedLanguage === 'en' 
              ? 'bg-teal-600 text-white dark:bg-teal-500 dark:text-slate-950 shadow-md font-bold' 
              : 'bg-transparent text-slate-700 dark:text-slate-200 hover:text-slate-900 dark:hover:text-white font-semibold']"
            class="py-2.5 text-xs rounded-xl transition-all duration-200 cursor-pointer"
          >
            English
          </button>
        </div>
      </div>

      <!-- Gender Selector -->
      <div class="space-y-2">
        <label class="text-[10px] font-extrabold text-slate-600 dark:text-slate-300 uppercase tracking-widest block">
          {{ selectedLanguage === 'bn' ? 'লিঙ্গ নির্বাচন করুন' : 'Select Gender' }}
        </label>
        <div class="grid grid-cols-2 gap-2">
          <button 
            type="button"
            @click="selectGender('male')"
            :class="[selectedGender === 'male' 
              ? 'bg-teal-600 text-white dark:bg-teal-500 dark:text-slate-950 font-bold shadow-md border border-teal-600 dark:border-teal-500' 
              : 'bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-slate-100 hover:bg-slate-200 dark:hover:bg-slate-700 border border-slate-300 dark:border-slate-600 font-semibold']"
            class="py-3 rounded-2xl flex items-center justify-center gap-2 transition-all duration-200 cursor-pointer text-xs"
          >
            <span class="material-symbols-rounded text-lg">man</span>
            <span>{{ selectedLanguage === 'bn' ? 'পুরুষ (মুজাক্কার)' : 'Male (Mudhakkar)' }}</span>
          </button>
          <button 
            type="button"
            @click="selectGender('female')"
            :class="[selectedGender === 'female' 
              ? 'bg-teal-600 text-white dark:bg-teal-500 dark:text-slate-950 font-bold shadow-md border border-teal-600 dark:border-teal-500' 
              : 'bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-slate-100 hover:bg-slate-200 dark:hover:bg-slate-700 border border-slate-300 dark:border-slate-600 font-semibold']"
            class="py-3 rounded-2xl flex items-center justify-center gap-2 transition-all duration-200 cursor-pointer text-xs"
          >
            <span class="material-symbols-rounded text-lg">woman</span>
            <span>{{ selectedLanguage === 'bn' ? 'নারী (মুআন্নাস)' : 'Female (Mu\'annath)' }}</span>
          </button>
        </div>
        <p class="text-[10px] text-slate-600 dark:text-slate-300 leading-normal italic px-1">
          * {{ selectedLanguage === 'bn' 
            ? 'মেয়েদের পিরিয়ড বা ওজরের দিনগুলোতে নামাজ ও কাজা হিসাব থেকে অব্যাহতি দেওয়ার জন্য এটি ব্যবহৃত হয়।' 
            : 'Menstruation exemption settings are tailored specifically based on this selection.' }}
        </p>
      </div>

      <!-- Optional Name Field -->
      <div class="space-y-2">
        <label for="username" class="text-[10px] font-extrabold text-slate-600 dark:text-slate-300 uppercase tracking-widest block">
          {{ selectedLanguage === 'bn' ? 'আপনার নাম (ঐচ্ছিক)' : 'Your Name (Optional)' }}
        </label>
        <div class="relative flex items-center">
          <span class="material-symbols-rounded absolute left-4 text-slate-500 dark:text-slate-300 text-xl">person</span>
          <input 
            id="username"
            v-model="username"
            type="text"
            :placeholder="selectedLanguage === 'bn' ? 'যেমন: আব্দুল্লাহ বা আয়েশা' : 'e.g., Abdullah or Ayesha'"
            class="w-full bg-slate-100 dark:bg-slate-800 border border-slate-300 dark:border-slate-600 text-slate-900 dark:text-slate-100 placeholder:text-slate-400 dark:placeholder:text-slate-500 text-xs pl-11 pr-4 py-3.5 rounded-2xl outline-none focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all duration-200"
          />
        </div>
      </div>

      <!-- Start Button -->
      <button 
        type="button"
        @click="handleStart"
        class="w-full bg-teal-600 dark:bg-teal-500 hover:bg-teal-700 dark:hover:bg-teal-400 text-white dark:text-slate-950 font-extrabold py-4 rounded-2xl shadow hover:scale-[1.01] active:scale-[0.99] transition-all duration-200 cursor-pointer text-sm flex items-center justify-center gap-2"
      >
        <span>{{ selectedLanguage === 'bn' ? 'যাত্রা শুরু করুন' : 'Start Journey' }}</span>
        <span class="material-symbols-rounded text-lg">arrow_forward</span>
      </button>
    </div>

    <!-- Footer Note -->
    <div class="text-center mt-6">
      <p class="text-[10px] text-slate-500 dark:text-slate-400 font-semibold tracking-wide">
        {{ selectedLanguage === 'bn' 
          ? '১০০% অফলাইন এবং নিরাপদ। আপনার সকল তথ্য ব্রাউজারে সংরক্ষিত থাকবে।' 
          : '100% Offline & Private. All your logs remain on this browser.' }}
      </p>
    </div>
  </div>
</template>
