<script setup lang="ts">
import { computed } from 'vue'
import { districts } from '@/data/districts'
import { useLocaleStore } from '@/stores/locale'
const model = defineModel<string>({ required: true })
const locale = useLocaleStore()
const options = computed(() => [...districts].sort((a, b) => locale.currentLocale === 'bn' ? a.bnName.localeCompare(b.bnName, 'bn') : a.name.localeCompare(b.name)))
</script>

<template>
  <label class="iq-field">{{ locale.t('district') }}
    <select v-model="model" required>
      <option value="" disabled>{{ locale.t('select_district') }}</option>
      <option v-for="entry in options" :key="entry.id" :value="entry.id">{{ locale.currentLocale === 'bn' ? entry.bnName : entry.name }}</option>
    </select>
  </label>
</template>
