<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useLocaleStore } from '@/stores/locale'
import PrayerCalculationSettings from '@/components/PrayerCalculationSettings.vue'
import { readLogs, CURRENT_BACKUP_VERSION, APP_VERSION } from '@/services/backup'
import { previewRestore, restoreBackup } from '@/services/restore'
import { shareBackupFile } from '@/services/backupFile'
import { pickNativeBackup } from '@/services/backupPicker'
import AppDialog from '@/components/AppDialog.vue'
import { readPreference } from '@/services/preferences'
import { useTimingStore } from '@/stores/timing'
import notices from '@/data/notices'

const props = defineProps<{
  isDark: boolean
}>()

const emit = defineEmits<{
  (e: 'toggle-theme'): void
}>()

const router = useRouter()
const authStore = useAuthStore()
const localeStore = useLocaleStore()
const timing = useTimingStore()

// Gender selection state
const isFemale = ref<boolean | null>(
  readPreference('iqamah_user_g') === 'f'
    ? true
    : readPreference('iqamah_user_g') === 'm'
      ? false
      : null
)

const setGender = (female: boolean) => {
  try {
    localStorage.setItem('iqamah_user_g', female ? 'f' : 'm')
    isFemale.value = female
  } catch {
    statusMessage.value = localeStore.t('settings_error')
    isSuccessStatus.value = false
  }
}

// Backup & Restore states
const isExporting = ref(false)
const isImporting = ref(false)
const importProgress = ref(0)
const importTotal = ref(0)
const fileInput = ref<HTMLInputElement | null>(null)
const statusMessage = ref<string | null>(null)
const isSuccessStatus = ref(true)
const restoreOpen = ref(false)
const pendingBackup = ref<unknown>(null)
const restoreMode = ref<'merge' | 'replace'>('merge')
const lastBackup = ref(readPreference('iqamah_last_backup'))

const triggerExport = async () => {
  if (isExporting.value || isImporting.value) return
  isExporting.value = true
  statusMessage.value = null
  try {
    const logs = readLogs().sort((a, b) => a.prayerDate.localeCompare(b.prayerDate) || a.prayerName - b.prayerName)

    const backupData = {
      version: CURRENT_BACKUP_VERSION,
      exportedAt: new Date().toISOString(),
      appVersion: APP_VERSION,
      username: authStore.user?.username || 'user',
      prayerLogs: logs,
      pendingQazas: logs.flatMap(log => log.qazaLog?.state === 0 ? [log.qazaLog] : []),
      preferences: {
        username: readPreference('iqamah_user_name') ?? '',
        language: localeStore.currentLocale,
        theme: props.isDark ? 'dark' : 'light',
        ...(isFemale.value === null ? {} : { gender: isFemale.value ? 'female' : 'male' }),
        districtId: timing.districtId,
        method: timing.config?.method ?? 'Karachi',
        madhab: timing.config?.madhab ?? 'Hanafi',
      },
    }

    previewRestore(backupData, 'replace')
    const backupJson = JSON.stringify(backupData, null, 2)
    const fileName = `iqamah_backup_v${CURRENT_BACKUP_VERSION}_${backupData.exportedAt.replace(/[:]/g, '-')}.json`
    const result = await shareBackupFile(backupJson, fileName)
    if (result === 'success') {
      lastBackup.value = backupData.exportedAt
      try { localStorage.setItem('iqamah_last_backup', backupData.exportedAt) } catch { /* Metadata is optional. */ }
    }
    statusMessage.value = localeStore.currentLocale === 'bn'
      ? result === 'success' ? 'ব্যাকআপ শেয়ার করা হয়েছে। অ্যাপের বাইরে ফাইলটি রাখুন।' : result === 'cancelled' ? 'ব্যাকআপ শেয়ার বাতিল করা হয়েছে।' : 'ডাউনলোডের অনুরোধ করা হয়েছে। ফাইলটি সংরক্ষিত হয়েছে কিনা যাচাই করুন।'
      : result === 'success' ? 'Backup shared. Keep the file outside the app.' : result === 'cancelled' ? 'Backup sharing cancelled.' : 'Download requested. Check that the file was saved.'
    isSuccessStatus.value = true
  } catch {
    statusMessage.value = localeStore.currentLocale === 'bn' ? 'ব্যাকআপ তৈরি ব্যর্থ হয়েছে।' : 'Export failed.'
    isSuccessStatus.value = false
  } finally {
    isExporting.value = false
  }
}

const reviewBackup = (content: string) => {
  const data: unknown = JSON.parse(content)
  importTotal.value = previewRestore(data, 'replace').logs.length
  pendingBackup.value = data
  restoreMode.value = 'merge'
  restoreOpen.value = true
}

const triggerImportClick = async () => {
  if (isImporting.value || isExporting.value) return
  isImporting.value = true
  try {
    const content = await pickNativeBackup()
    if (content === undefined) fileInput.value?.click()
    else if (content !== null) reviewBackup(content)
  } catch {
    statusMessage.value = localeStore.currentLocale === 'bn' ? 'ব্যাকআপ পড়া যায়নি। বর্তমান ডেটা বদলায়নি।' : 'Unable to read backup. Current data is unchanged.'
    isSuccessStatus.value = false
  } finally { isImporting.value = false }
}

const handleImportFile = async (event: Event) => {
  const target = event.target as HTMLInputElement
  if (!target.files || target.files.length === 0) return

  const file = target.files[0]
  if (!file) return
  isImporting.value = true
  importProgress.value = 0
  statusMessage.value = null
    try {
      if (file.size > 20 * 1024 * 1024) throw new Error('Backup exceeds 20 MB.')
      reviewBackup(await file.text())
    } catch {
      statusMessage.value = localeStore.currentLocale === 'bn' ? 'ইম্পোর্ট ব্যর্থ। ফাইল অবৈধ, সংস্করণ অসমর্থিত অথবা বর্তমান রেকর্ডের সাথে বিরোধ আছে। আগের রেকর্ড রাখা হয়েছে।' : 'Import failed: invalid file, unsupported version, storage failure, or conflicting records. Existing records were preserved.'
      isSuccessStatus.value = false
    } finally {
      isImporting.value = false
      target.value = '' // Clear input
    }
}

const commitRestore = () => {
  try {
    restoreBackup(pendingBackup.value, restoreMode.value)
    window.location.reload()
  } catch {
    statusMessage.value = localeStore.currentLocale === 'bn' ? 'রিস্টোর ব্যর্থ। আগের ডেটা বা পুনরুদ্ধারের কপি রাখা হয়েছে।' : 'Restore failed. Previous data or its recovery journal has been retained.'
    isSuccessStatus.value = false
    restoreOpen.value = false
    if (readPreference('iqamah_restore_journal')) window.location.reload()
  }
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
    localStorage.removeItem('iqamah_onboarding_completed')
    localStorage.removeItem('iqamah_user_name')
    localStorage.removeItem('iqamah_user_g')
    localStorage.removeItem('iqamah_locale')
    localStorage.removeItem('iqamah_theme')
    localStorage.removeItem('iqamah_last_backup')
    useTimingStore().reset()
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
        v{{ APP_VERSION }}
      </span>
    </div>

    <!-- Status Alerts -->
    <div 
      v-if="statusMessage"
      :class="[isSuccessStatus ? 'bg-emerald-500/10 border-emerald-500/20 text-emerald-800 dark:text-emerald-300' : 'bg-rose-500/10 border-rose-500/20 text-rose-800 dark:text-rose-300']"
      class="p-4 rounded-2xl border text-sm font-medium transition-all" role="status"
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
      <h2 class="text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-slate-400 px-1">
        {{ localeStore.currentLocale === 'bn' ? 'ব্যবহারকারী সেটিংস' : 'User Preferences' }}
      </h2>

      <div class="rounded-3xl bg-m3-surface dark:bg-m3-dark-surface border border-slate-200/50 dark:border-slate-800/80 divide-y divide-slate-100 dark:divide-slate-800/80 overflow-hidden shadow-sm">
        
        <!-- Dark Mode Switch -->
        <div class="p-4 flex items-center justify-between">
          <div class="flex items-center gap-3">
            <span class="material-symbols-rounded text-slate-600 dark:text-slate-300 text-2xl">dark_mode</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'ডার্ক মোড' : 'Dark Mode' }}
              </span>
              <span class="text-xs text-slate-500 dark:text-slate-300 block">
                {{ localeStore.currentLocale === 'bn' ? 'চোখের সুরক্ষা এবং চার্জ সাশ্রয়' : 'Save battery & protect your eyes' }}
              </span>
            </div>
          </div>
          <button 
            @click="emit('toggle-theme')"
            role="switch" :aria-checked="isDark" :aria-label="localeStore.t('toggle_theme')"
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
            <span class="material-symbols-rounded text-slate-600 dark:text-slate-300 text-2xl">translate</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'ভাষা / Language' : 'Language' }}
              </span>
              <span class="text-xs text-slate-500 dark:text-slate-300 block">
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
            <span class="material-symbols-rounded text-slate-600 dark:text-slate-300 text-2xl">wc</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'লিঙ্গ নির্ধারণ' : 'Gender Settings' }}
              </span>
              <span class="text-xs text-slate-500 dark:text-slate-300 block">
                {{ localeStore.currentLocale === 'bn' ? 'হায়েজ / নিফাস অপশনের জন্য প্রয়োজন' : 'Required for showing menstruation options' }}
              </span>
            </div>
          </div>
          <div class="flex gap-2">
            <button 
              @click="setGender(false)" 
              :class="[isFemale === false ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900' : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300']"
              class="flex-1 py-2 text-xs font-bold rounded-xl border border-slate-200/20 text-center cursor-pointer transition-colors"
            >
              {{ localeStore.currentLocale === 'bn' ? 'পুরুষ (মুজাক্কার)' : 'Male (Mudhakkar)' }}
            </button>
            <button 
              @click="setGender(true)" 
              :class="[isFemale === true ? 'bg-teal-700 dark:bg-teal-500 text-white dark:text-slate-900' : 'bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300']"
              class="flex-1 py-2 text-xs font-bold rounded-xl border border-slate-200/20 text-center cursor-pointer transition-colors"
            >
              {{ localeStore.currentLocale === 'bn' ? 'নারী (মুআন্নাস)' : 'Female (Mu\'annath)' }}
            </button>
          </div>
        </div>

      </div>
    </div>

    <PrayerCalculationSettings />

    <!-- Data Management Group -->
    <div class="space-y-3">
      <h2 class="text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-slate-400 px-1">
        {{ localeStore.currentLocale === 'bn' ? 'উপাত্ত ব্যবস্থাপনা' : 'Data Management' }}
      </h2>

      <div class="rounded-3xl bg-m3-surface dark:bg-m3-dark-surface border border-slate-200/50 dark:border-slate-800/80 divide-y divide-slate-100 dark:divide-slate-800/80 overflow-hidden shadow-sm">
        
        <!-- Export Backup -->
        <button 
          @click="triggerExport"
          :disabled="isExporting"
          class="w-full text-left p-4 flex items-center justify-between hover:bg-teal-50 dark:hover:bg-teal-900/20 cursor-pointer disabled:opacity-50 transition-colors duration-150"
        >
          <div class="flex items-center gap-3">
            <span class="material-symbols-rounded text-slate-600 dark:text-slate-300 text-2xl">download_for_offline</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'আমার ডেটার ব্যাকআপ নিন' : 'Back Up My Data' }}
              </span>
              <span class="text-xs text-slate-500 dark:text-slate-300 block">
                {{ localeStore.currentLocale === 'bn' ? 'আপনার নামাজের সকল রেকর্ড ফাইল হিসেবে সংরক্ষণ করুন' : 'Export your prayer records to local storage' }}
              </span>
            </div>
          </div>
          <span class="material-symbols-rounded text-slate-500 dark:text-slate-300">chevron_right</span>
        </button>

        <!-- Import Backup -->
        <button 
          @click="triggerImportClick" :disabled="isImporting || isExporting"
          class="w-full text-left p-4 flex items-center justify-between hover:bg-teal-50 dark:hover:bg-teal-900/20 cursor-pointer transition-colors duration-150"
        >
          <div class="flex items-center gap-3">
            <span class="material-symbols-rounded text-slate-600 dark:text-slate-300 text-2xl">upload_file</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.currentLocale === 'bn' ? 'ব্যাকআপ রিস্টোর করুন' : 'Restore Backup' }}
              </span>
              <span class="text-xs text-slate-500 dark:text-slate-300 block">
                {{ localeStore.currentLocale === 'bn' ? 'সংরক্ষিত ব্যাকআপ ফাইল থেকে ডাটা ইম্পোর্ট করুন' : 'Restore your prayer logs from a backup file' }}
              </span>
            </div>
          </div>
          <span class="material-symbols-rounded text-slate-500 dark:text-slate-300">chevron_right</span>
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
      <h2 class="text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-slate-400 px-1">
        {{ localeStore.currentLocale === 'bn' ? 'ইতিহাস ও পরিসংখ্যান' : 'History & Insights' }}
      </h2>

      <div class="rounded-3xl bg-m3-surface dark:bg-m3-dark-surface border border-slate-200/50 dark:border-slate-800/80 divide-y divide-slate-100 dark:divide-slate-800/80 overflow-hidden shadow-sm">
        
        <!-- Analytics is available here instead of the bottom navigation. -->
        <RouterLink 
          to="/analytics"
          class="p-4 flex items-center justify-between hover:bg-teal-50 dark:hover:bg-teal-900/20 transition-colors duration-150"
        >
          <div class="flex items-center gap-3">
            <span class="material-symbols-rounded text-slate-600 dark:text-slate-300 text-2xl">insights</span>
            <div>
              <span class="font-semibold block text-slate-800 dark:text-slate-200">
                {{ localeStore.t('analytics') }}
              </span>
              <span class="text-xs text-slate-500 dark:text-slate-300 block">
                {{ localeStore.currentLocale === 'bn' ? 'আপনার সালাতের ইতিহাস ও পরিসংখ্যান দেখুন' : 'View your prayer history and statistics' }}
              </span>
            </div>
          </div>
          <span class="material-symbols-rounded text-slate-500 dark:text-slate-300">chevron_right</span>
        </RouterLink>

      </div>
    </div>

    <details class="iq-surface">
      <summary class="cursor-pointer font-semibold">{{ localeStore.t('third_party_notices') }}</summary>
      <pre class="whitespace-pre-wrap break-words text-sm mt-4 font-sans">{{ notices }}</pre>
    </details>

    <!-- Reset button -->
    <button 
      @click="handleReset"
      class="w-full py-4 rounded-3xl bg-rose-500/10 hover:bg-rose-500 text-rose-500 hover:text-white font-bold text-center border border-rose-500/20 hover:scale-[1.01] transition-all duration-200 cursor-pointer"
    >
      {{ localeStore.currentLocale === 'bn' ? 'অ্যাপ্লিকেশন রিসেট করুন' : 'Reset Application' }}
    </button>

    <!-- App Version & Release Info -->
    <div class="text-center space-y-1.5 py-4 iq-secondary">
      <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[var(--iq-secondary-surface)] font-semibold text-[var(--iq-text)]">
        <span>Iqamah · v{{ APP_VERSION }}</span>
      </div>
      <p>
        {{ localeStore.currentLocale === 'bn' ? 'অফলাইন-ফার্স্ট সালাত ও কাজা ট্র্যাকার' : 'Offline-first Salah & Qaza Habit Companion' }}
      </p>
      <p>
        {{ localeStore.currentLocale === 'bn' ? '৬৪ জেলার আনুমানিক হিসাব; সরকারি সময়সূচি হিসেবে যাচাইকৃত নয়' : 'Estimates for 64 districts; not verified as official timetables' }}
      </p>
    </div>
    <p class="iq-secondary">{{ localeStore.currentLocale === 'bn' ? 'ব্যাকআপে ব্যক্তিগত নোট থাকতে পারে। অ্যাপ আনইনস্টল করলে স্থানীয় ডেটা হারাতে পারে।' : 'Backups may contain private notes. Uninstalling can destroy local data.' }}</p>
    <p v-if="lastBackup" class="iq-secondary">{{ localeStore.currentLocale === 'bn' ? 'সর্বশেষ নিশ্চিত শেয়ার:' : 'Last confirmed share:' }} {{ lastBackup }}</p>
    <AppDialog v-model="restoreOpen" :label="localeStore.currentLocale === 'bn' ? 'ব্যাকআপ পর্যালোচনা' : 'Review backup'">
      <div class="space-y-4 p-5">
        <h2 class="iq-section-heading">{{ localeStore.currentLocale === 'bn' ? 'ব্যাকআপ পর্যালোচনা' : 'Review backup' }} · {{ importTotal }}</h2>
        <label class="iq-field">{{ localeStore.currentLocale === 'bn' ? 'রিস্টোর পদ্ধতি' : 'Restore mode' }}
          <select v-model="restoreMode">
            <option value="merge">{{ localeStore.currentLocale === 'bn' ? 'বিরোধহীন রেকর্ড যোগ করুন' : 'Merge compatible records' }}</option>
            <option value="replace">{{ localeStore.currentLocale === 'bn' ? 'রেকর্ড প্রতিস্থাপন করুন' : 'Replace all prayer records' }}</option>
          </select>
        </label>
        <p class="iq-secondary">{{ localeStore.currentLocale === 'bn' ? 'প্রতিস্থাপনে সব নামাজের রেকর্ড ও ব্যাকআপে থাকা সেটিংস বদলাবে। অনুপস্থিত পুরোনো সেটিংস রাখা হবে। মার্জে সেটিংস বদলাবে না; বিরোধ থাকলে বাতিল হবে। আগে বর্তমান ডেটার ব্যাকআপ নিন।' : 'Replace changes all prayer records and settings present in the backup; absent historical settings are retained. Merge keeps your settings and rejects conflicting records. Back up your current data first.' }}</p>
        <button class="iq-button-secondary" :disabled="isExporting" @click="triggerExport">{{ localeStore.currentLocale === 'bn' ? 'আগে বর্তমান ডেটার ব্যাকআপ নিন' : 'Back up current data first' }}</button>
        <div class="flex flex-wrap gap-3">
          <button class="iq-button" :disabled="isExporting" @click="commitRestore">{{ localeStore.currentLocale === 'bn' ? 'নিশ্চিত করে রিস্টোর করুন' : 'Confirm restore' }}</button>
          <button class="iq-button-secondary" @click="restoreOpen = false">{{ localeStore.currentLocale === 'bn' ? 'বাতিল' : 'Cancel' }}</button>
        </div>
      </div>
    </AppDialog>
  </div>
</template>
