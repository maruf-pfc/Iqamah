<script setup lang="ts">
import { nextTick, onMounted, ref, watch } from 'vue'
const open = defineModel<boolean>({ required: true })
defineProps<{ label: string }>()
const element = ref<HTMLDialogElement>()
const sync = async () => {
  await nextTick()
  if (open.value && !element.value?.open) element.value?.showModal()
  else if (!open.value && element.value?.open) element.value?.close()
}
watch(open, sync)
onMounted(sync)
</script>

<template>
  <dialog ref="element" class="iq-dialog" :aria-label="label" @cancel="open = false" @close="open = false" @click="event => { if (event.target === element) open = false }">
    <slot v-if="open" />
  </dialog>
</template>
