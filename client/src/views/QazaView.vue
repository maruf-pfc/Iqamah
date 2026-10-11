<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { usePrayerStore } from '@/stores/prayer'
import { useLocaleStore } from '@/stores/locale'
import { prayerKeys } from '@/services/prayerTimes'

const store = usePrayerStore()
const locale = useLocaleStore()
const prayerFilter = ref('all')
const stateFilter = ref<0 | 1>(0)
const feedback = ref<'qaza_saved' | 'data_error' | null>(null)
const busyId = ref<string | null>(null)
const records = computed(() => store.qazaLogs
  .filter(q => q.state === stateFilter.value && (prayerFilter.value === 'all' || q.prayerName === Number(prayerFilter.value)))
  .sort((a, b) => b.originalPrayerDate.localeCompare(a.originalPrayerDate)))
const load = async () => {
  try { await store.fetchPendingQazas() } catch { feedback.value = 'data_error' }
}
onMounted(load)
const fulfill = async (id: string) => {
  if (busyId.value) return
  busyId.value = id
  feedback.value = null
  try {
    await store.fulfillQaza(id)
    await load()
    feedback.value = 'qaza_saved'
  } catch { feedback.value = 'data_error' }
  finally { busyId.value = null }
}
const formatDate = (value: string) => new Date(`${value}T12:00:00+06:00`).toLocaleDateString(locale.currentLocale === 'bn' ? 'bn-BD' : 'en', { timeZone: 'Asia/Dhaka', day: 'numeric', month: 'long', year: 'numeric' })
</script>

<template>
  <div class="px-6 py-6 space-y-5">
    <header>
      <h1 class="text-2xl font-bold">{{ locale.t('qaza_ledger') }}</h1>
      <p class="iq-secondary mt-2">{{ locale.t('qaza_tagline') }}</p>
    </header>
    <div class="iq-surface flex justify-between gap-4 flex-wrap">
      <p>{{ locale.t('total_pending') }} <strong>{{ store.pendingQazas.length }}</strong></p>
      <p>{{ locale.t('qaza_made_up') }} <strong>{{ store.qazaLogs.filter(q => q.state === 1).length }}</strong></p>
    </div>
    <div class="grid sm:grid-cols-2 gap-4">
      <label class="iq-field">{{ locale.t('prayer_name') }}
        <select v-model="prayerFilter"><option value="all">{{ locale.t('all_prayers') }}</option><option v-for="(key, index) in prayerKeys" :key="key" :value="String(index)">{{ locale.t(key) }}</option></select>
      </label>
      <label class="iq-field">{{ locale.t('qaza_status') }}
        <select v-model="stateFilter"><option :value="0">{{ locale.t('pending') }}</option><option :value="1">{{ locale.t('qaza_made_up') }}</option></select>
      </label>
    </div>
    <p v-if="feedback" :role="feedback === 'data_error' ? 'alert' : 'status'" class="iq-secondary">{{ locale.t(feedback) }}</p>
    <p v-if="store.loading && !busyId" role="status">{{ locale.t('loading_records') }}</p>
    <section v-else-if="!store.error" class="iq-surface">
      <h2 class="iq-section-heading">{{ locale.t(stateFilter === 0 ? 'outstanding_debt' : 'qaza_made_up') }}</h2>
      <p v-if="!records.length" class="iq-secondary mt-4">{{ locale.t('no_matching_records') }}</p>
      <ul v-else class="divide-y divide-current/10">
        <li v-for="qaza in records" :key="qaza.id" class="flex items-center justify-between gap-4 flex-wrap py-4">
          <div>
            <h3 class="font-semibold">{{ locale.t(prayerKeys[qaza.prayerName]!) }}</h3>
            <p class="iq-secondary">{{ formatDate(qaza.originalPrayerDate) }}</p>
            <p v-if="qaza.fulfilledAt" class="iq-secondary">{{ locale.t('fulfilled_on') }} {{ new Date(qaza.fulfilledAt).toLocaleString(locale.currentLocale === 'bn' ? 'bn-BD' : 'en', { timeZone: 'Asia/Dhaka' }) }}</p>
          </div>
          <button v-if="qaza.state === 0" class="iq-button" :disabled="busyId !== null" @click="fulfill(qaza.id)">{{ locale.t('fulfill') }}</button>
          <span v-else>{{ locale.t('qaza_made_up') }}</span>
        </li>
      </ul>
    </section>
  </div>
</template>
