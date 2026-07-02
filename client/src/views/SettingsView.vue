<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useLocaleStore } from '@/stores/locale'
import { usePrayerStore } from '@/stores/prayer'

const props = defineProps<{
  isDark: boolean
}>()

const emit = defineEmits<{
  (e: 'toggle-theme'): void
}>()

const router = useRouter()
const authStore = useAuthStore()
const localeStore = useLocaleStore()
const store = usePrayerStore()

// Gender selection state
const isFemale = ref<boolean | null>(
  localStorage.getItem('iqamah_gender') === 'female'
    ? true
    : localStorage.getItem('iqamah_gender') === 'male'
      ? false
      : null
)

const setGender = (female: boolean) => {
  isFemale.value = female
  localStorage.setItem('iqamah_gender', female ? 'female' : 'male')
}

// Backup & Restore states
const isExporting = ref(false)
const isImporting = ref(false)
const importProgress = ref(0)
const importTotal = ref(0)
const fileInput = ref<HTMLInputElement | null>(null)
const statusMessage = ref<string | null>(null)
const isSuccessStatus = ref(true)

const triggerExport = async () => {
  isExporting.value = true
  statusMessage.value = null
  try {
    // Fetch logs for the past 5 years to ensure we get everything
    const todayStr = new Date().toISOString().split('T')[0] ?? ''
    await store.fetchPrayerLogs('2021-01-01', todayStr)
    await store.fetchPendingQazas()

    const backupData = {
      version: '1.1.0',
      exportedAt: new Date().toISOString(),
      username: authStore.user?.username || 'user',
      prayerLogs: store.prayerLogs,
      pendingQazas: store.pendingQazas,
      gender: isFemale.value ? 'female' : 'male'
    }

    const dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(backupData, null, 2))
    const downloadAnchor = document.createElement('a')
    downloadAnchor.setAttribute('href', dataStr)
    downloadAnchor.setAttribute('download', `iqamah_backup_${todayStr}.json`)
    document.body.appendChild(downloadAnchor)
    downloadAnchor.click()
    downloadAnchor.remove()

    statusMessage.value = localeStore.currentLocale === 'bn' ? 'ব্যাকআপ ফাইল সফলভাবে ডাউনলোড হয়েছে।' : 'Backup file downloaded successfully.'
    isSuccessStatus.value = true
  } catch (err) {
    statusMessage.value = localeStore.currentLocale === 'bn' ? 'ব্যাকআপ তৈরি ব্যর্থ হয়েছে।' : 'Export failed.'
    isSuccessStatus.value = false
  } finally {
    isExporting.value = false
  }
}

const triggerImportClick = () => {
  fileInput.value?.click()
}

const handleImportFile = async (event: Event) => {
  const target = event.target as HTMLInputElement
  if (!target.files || target.files.length === 0) return

  const file = target.files[0]
  if (!file) return
  const reader = new FileReader()

  isImporting.value = true
  importProgress.value = 0
  statusMessage.value = null

  reader.onload = async (e) => {
    try {
      const data = JSON.parse(e.target?.result as string)
      if (!data.prayerLogs || !Array.isArray(data.prayerLogs)) {
        throw new Error('Invalid backup file structure.')
      }

      const logsToImport = data.prayerLogs
      importTotal.value = logsToImport.length
      
      if (data.gender) {
        setGender(data.gender === 'female')
      }

      // Restore prayer logs sequentially
      for (let i = 0; i < logsToImport.length; i++) {
        const log = logsToImport[i]
        // Map data structures back to API payload format
        const payload = log.isOffered 
          ? {
              prayerName: log.prayerName,
              prayerDate: log.prayerDate,
              isOffered: true,
              waqtStatus: log.waqtStatus ?? 0,
              isJamaah: log.isJamaah || false,
              isTraveling: log.isTraveling || false,
              isJummah: log.isJummah || false,
              isHome: log.isHome || false,
              quranNotes: log.quranNotes || undefined,
              hasTasbih: log.hasTasbih || false,
            }
          : {
              prayerName: log.prayerName,
              prayerDate: log.prayerDate,
              isOffered: false,
              missedReason: log.missedReason ?? 4,
              isTraveling: log.isTraveling || false,
            }
        
        await store.logPrayer(payload)
        importProgress.value = i + 1
      }

      statusMessage.value = localeStore.currentLocale === 'bn' 
        ? `সফলভাবে ${importTotal.value}টি রেকর্ড রিস্টোর করা হয়েছে!` 
        : `Successfully restored ${importTotal.value} records!`
      isSuccessStatus.value = true
    } catch (err) {
      statusMessage.value = localeStore.currentLocale === 'bn' ? 'ফাইল ইম্পোর্ট ব্যর্থ হয়েছে। অনুগ্রহ করে সঠিক ফাইল নির্বাচন করুন।' : 'Import failed. Invalid file format.'
      isSuccessStatus.value = false
    } finally {
      isImporting.value = false
      target.value = '' // Clear input
    }
  }

  reader.readAsText(file)
}

const handleReset = () => {
  const confirmed = confirm(
    localeStore.currentLocale === 'bn'
      ? 'আপনি কি নিশ্চিত যে আপনি অ্যাপ্লিকেশন রিসেট করতে চান? আপনার সকল কাযা ও নামাজের রেকর্ড মুছে যাবে!'
      : 'Are you sure you want to reset the application? All your prayer logs and Qaza records will be permanently deleted!'
  )
  if (confirmed) {
    authStore.logout()
    localStorage.removeItem('iqamah_prayer_logs')
    router.push('/onboarding')
  }
}
</script>

<template>
  <div class="px-6 py-6 space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-bold font-sans tracking-tight text-slate-900 dark:text-white">
        {{ localeStore.currentLocale === 'bn' ? 'ব্যাকআপ ও সেটিংস' : 'Settings & Backup' }}
      </h1>
      <span class="text-xs px-2.5 py-1 rounded-full bg-teal-500/10 text-teal-700 dark:text-teal-300 border border-teal-500/20 font-bold">
        v1.1.0
      </span>
    </div>

    <!-- Status Alerts -->
    <div 
      v-if="statusMessage"
      :class="[isSuccessStatus ? 'bg-emerald-500/10 border-emerald-500/20 text-emerald-800 dark:text-emerald-300' : 'bg-rose-500/10 border-rose-500/20 text-rose-800 dark:text-rose-300']"
      class="p-4 rounded-2xl border text-sm font-medium transition-all"
    >
      {{ statusMessage }}
    </div>

    <!-- Backup Progress Bar -->
    <div v-if="isImporting" class="p-5 rounded-2xl bg-m3-surface dark:bg-m3-dark-surface border border-slate-200/50 dark:border-slate-800 space-y-3">
      <div class="flex justify-between text-xs font-bold text-slate-500 dark:text-slate-400">
        <span>{{ localeStore.currentLocale === 'bn' ? 'রিস্টোর করা হচ্ছে...' : 'Restoring logs...' }}</span>
        <span>{{ importProgress }} / {{ importTotal }}</span>
      </div>
      <div class="w-full h-2 bg-slate-200 dark:bg-slate-800 rounded-full overflow-hidden">
        <div 
          class="h-full bg-m3-primary dark:bg-m3-dark-primary transition-all duration-150"
          :style="{ width: `${(importProgress / importTotal) * 100}%` }"
        ></div>
      </div>
    </div>

    <!-- Preferences Group -->
    <div class="space-y-3">
      <h2 class="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 px-1">
        {{ localeStore.currentLocale === 'bn' ? 'ব্যবহারকারী সেটিংস' : 'User Preferences' }}
      </h2>

      <div class="rounded-3xl bg-m3-surface dark:bg-m3-dark-surface border border-slate-200/50 dark:border-slate-800/80 divide-y divide-slate-100 dark:divide-slate-800/80 overflow-hidden shadow-sm">
        
        <!-- Dark Mode Switch -->
        <div class="p-4 flex items-center justify-between">
          <div class="flex items-center gap-3">
            <span class="material-symbols-rounded text-slate-500 dark:text-slate-400 text-2xl">dark_mode</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'ডার্ক মোড' : 'Dark Mode' }}
              </span>
              <span class="text-xs text-slate-400 dark:text-slate-500 block">
                {{ localeStore.currentLocale === 'bn' ? 'চোখের সুরক্ষা এবং চার্জ সাশ্রয়' : 'Save battery & protect your eyes' }}
              </span>
            </div>
          </div>
          <button 
            @click="emit('toggle-theme')"
            class="w-12 h-6.5 rounded-full p-1 transition-colors duration-200 outline-none cursor-pointer"
            :class="[isDark ? 'bg-m3-primary dark:bg-m3-dark-primary' : 'bg-slate-300 dark:bg-slate-700']"
          >
            <div 
              class="w-4.5 h-4.5 rounded-full bg-white transition-transform duration-200 shadow-md"
              :class="[isDark ? 'translate-x-5.5' : 'translate-x-0']"
            ></div>
          </button>
        </div>

        <!-- Language Toggle -->
        <div class="p-4 flex items-center justify-between">
          <div class="flex items-center gap-3">
            <span class="material-symbols-rounded text-slate-500 dark:text-slate-400 text-2xl">translate</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'ভাষা / Language' : 'Language' }}
              </span>
              <span class="text-xs text-slate-400 dark:text-slate-500 block">
                {{ localeStore.currentLocale === 'bn' ? 'অ্যাপ্লিকেশন ভাষা পরিবর্তন করুন' : 'Change app interface language' }}
              </span>
            </div>
          </div>
          <button 
            @click="localeStore.toggleLocale"
            class="px-4 py-1.5 rounded-full border border-slate-200 dark:border-slate-700 text-xs font-bold text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer"
          >
            {{ localeStore.currentLocale === 'en' ? 'English' : 'বাংলা' }}
          </button>
        </div>

        <!-- Gender Settings -->
        <div class="p-4 space-y-3">
          <div class="flex items-center gap-3">
            <span class="material-symbols-rounded text-slate-500 dark:text-slate-400 text-2xl">wc</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'লিঙ্গ নির্ধারণ' : 'Gender Settings' }}
              </span>
              <span class="text-xs text-slate-400 dark:text-slate-500 block">
                {{ localeStore.currentLocale === 'bn' ? 'হায়েজ / নিফাস অপশনের জন্য প্রয়োজন' : 'Required for showing menstruation options' }}
              </span>
            </div>
          </div>
          <div class="flex gap-2">
            <button 
              @click="setGender(false)" 
              :class="[isFemale === false ? 'bg-m3-primary dark:bg-m3-dark-primary text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300']"
              class="flex-1 py-2 text-xs font-bold rounded-xl border border-slate-200/20 text-center cursor-pointer transition-colors"
            >
              {{ localeStore.currentLocale === 'bn' ? 'পুরুষ (মুজাক্কার)' : 'Male (Mudhakkar)' }}
            </button>
            <button 
              @click="setGender(true)" 
              :class="[isFemale === true ? 'bg-m3-primary dark:bg-m3-dark-primary text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300']"
              class="flex-1 py-2 text-xs font-bold rounded-xl border border-slate-200/20 text-center cursor-pointer transition-colors"
            >
              {{ localeStore.currentLocale === 'bn' ? 'নারী (মুআন্নাস)' : 'Female (Mu\'annath)' }}
            </button>
          </div>
        </div>

      </div>
    </div>

    <!-- Data Management Group -->
    <div class="space-y-3">
      <h2 class="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 px-1">
        {{ localeStore.currentLocale === 'bn' ? 'উপাত্ত ব্যবস্থাপনা' : 'Data Management' }}
      </h2>

      <div class="rounded-3xl bg-m3-surface dark:bg-m3-dark-surface border border-slate-200/50 dark:border-slate-800/80 divide-y divide-slate-100 dark:divide-slate-800/80 overflow-hidden shadow-sm">
        
        <!-- Export Backup -->
        <button 
          @click="triggerExport"
          :disabled="isExporting"
          class="w-full text-left p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-850 cursor-pointer disabled:opacity-50"
        >
          <div class="flex items-center gap-3">
            <span class="material-symbols-rounded text-slate-500 dark:text-slate-400 text-2xl">download_for_offline</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'ব্যাকআপ ডাউনলোড (JSON)' : 'Export Backup (JSON)' }}
              </span>
              <span class="text-xs text-slate-400 dark:text-slate-500 block">
                {{ localeStore.currentLocale === 'bn' ? 'আপনার নামাজের সকল রেকর্ড ফাইল হিসেবে সংরক্ষণ করুন' : 'Export your prayer records to local storage' }}
              </span>
            </div>
          </div>
          <span class="material-symbols-rounded text-slate-400">chevron_right</span>
        </button>

        <!-- Import Backup -->
        <button 
          @click="triggerImportClick"
          class="w-full text-left p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-850 cursor-pointer"
        >
          <div class="flex items-center gap-3">
            <span class="material-symbols-rounded text-slate-500 dark:text-slate-400 text-2xl">upload_file</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'ব্যাকআপ রিস্টোর করুন' : 'Restore Backup' }}
              </span>
              <span class="text-xs text-slate-400 dark:text-slate-500 block">
                {{ localeStore.currentLocale === 'bn' ? 'সংরক্ষিত ব্যাকআপ ফাইল থেকে ডাটা ইম্পোর্ট করুন' : 'Restore your prayer logs from a backup file' }}
              </span>
            </div>
          </div>
          <span class="material-symbols-rounded text-slate-400">chevron_right</span>
        </button>

        <!-- Hidden input -->
        <input 
          ref="fileInput"
          type="file" 
          accept=".json"
          class="hidden" 
          @change="handleImportFile"
        />

      </div>
    </div>

    <!-- Information & Guide Group -->
    <div class="space-y-3">
      <h2 class="text-xs font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 px-1">
        {{ localeStore.currentLocale === 'bn' ? 'তথ্য ও নির্দেশিকা' : 'Guides & Timings' }}
      </h2>

      <div class="rounded-3xl bg-m3-surface dark:bg-m3-dark-surface border border-slate-200/50 dark:border-slate-800/80 divide-y divide-slate-100 dark:divide-slate-800/80 overflow-hidden shadow-sm">
        
        <!-- Salah Times -->
        <RouterLink 
          to="/salah-time"
          class="p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-850"
        >
          <div class="flex items-center gap-3">
            <span class="material-symbols-rounded text-slate-500 dark:text-slate-400 text-2xl">schedule</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'সালাতের সময়সূচী' : 'Salah Timings' }}
              </span>
              <span class="text-xs text-slate-400 dark:text-slate-500 block">
                {{ localeStore.currentLocale === 'bn' ? 'ওয়াক্ত ও হারাম সময়সমূহের লাইভ হিসাব' : 'Live prayer timings & forbidden zones lookup' }}
              </span>
            </div>
          </div>
          <span class="material-symbols-rounded text-slate-400">chevron_right</span>
        </RouterLink>

        <!-- Islamic Guide -->
        <RouterLink 
          to="/guide"
          class="p-4 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-850"
        >
          <div class="flex items-center gap-3">
            <span class="material-symbols-rounded text-slate-500 dark:text-slate-400 text-2xl">import_contacts</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'সালাত ও কাজার নিয়মাবলী' : 'Salah & Qaza Rules' }}
              </span>
              <span class="text-xs text-slate-400 dark:text-slate-500 block">
                {{ localeStore.currentLocale === 'bn' ? 'ইকামা ট্র্যাকিংয়ের পেছনের ফিকহী নীতিমালা' : 'Islamic jurisprudence regarding missed prayers' }}
              </span>
            </div>
          </div>
          <span class="material-symbols-rounded text-slate-400">chevron_right</span>
        </RouterLink>

      </div>
    </div>

    <!-- Reset button -->
    <button 
      @click="handleReset"
      class="w-full py-4 rounded-3xl bg-rose-500/10 hover:bg-rose-500 text-rose-500 hover:text-white font-bold text-center border border-rose-500/20 hover:scale-[1.01] transition-all duration-200 cursor-pointer"
    >
      {{ localeStore.currentLocale === 'bn' ? 'অ্যাপ্লিকেশন রিসেট করুন' : 'Reset Application' }}
    </button>
  </div>
</template>
