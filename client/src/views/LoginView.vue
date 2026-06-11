<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const isLoginMode = ref(true)
const username = ref('')
const email = ref('')
const password = ref('')

const formError = ref<string | null>(null)
const successMsg = ref<string | null>(null)
const isSubmitting = ref(false)

const toggleMode = () => {
  isLoginMode.value = !isLoginMode.value
  formError.value = null
  successMsg.value = null
  username.value = ''
  email.value = ''
  password.value = ''
}

const handleSubmit = async () => {
  formError.value = null
  successMsg.value = null

  if (!email.value || !password.value) {
    formError.value = 'Please fill out all required fields.'
    return
  }

  if (!isLoginMode.value && !username.value) {
    formError.value = 'Username is required for registration.'
    return
  }

  isSubmitting.value = true
  try {
    if (isLoginMode.value) {
      await authStore.login(email.value, password.value)
      successMsg.value = 'Logged in successfully!'
      setTimeout(() => {
        router.push('/')
      }, 500)
    } else {
      await authStore.register(username.value, email.value, password.value)
      successMsg.value = 'Account created successfully!'
      setTimeout(() => {
        router.push('/')
      }, 500)
    }
  } catch (err) {
    formError.value = err instanceof Error ? err.message : 'An error occurred.'
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div
    class="min-h-screen flex items-center justify-center bg-slate-950 p-4 relative overflow-hidden"
  >
    <!-- Ambient glowing backgrounds -->
    <div class="absolute top-1/4 left-1/4 w-96 h-96 bg-indigo-500/10 rounded-full blur-3xl"></div>
    <div
      class="absolute bottom-1/4 right-1/4 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl"
    ></div>

    <div
      class="w-full max-w-md bg-slate-900/40 border border-slate-800/80 backdrop-blur-md rounded-3xl p-8 shadow-2xl relative z-10 transition-all duration-300"
    >
      <!-- Title -->
      <div class="text-center mb-8">
        <h1 class="text-4xl font-extrabold text-slate-100 flex items-center justify-center gap-2">
          إقامة
          <span
            class="bg-gradient-to-r from-emerald-400 to-indigo-400 bg-clip-text text-transparent"
            >Iqamah</span
          >
        </h1>
        <p class="text-xs text-slate-400 mt-2 font-medium">
          {{
            isLoginMode
              ? 'Sign in to analyze and establish your prayer habits'
              : 'Create an account to start tracking your prayers'
          }}
        </p>
      </div>

      <!-- Errors/Success -->
      <div
        v-if="formError"
        class="mb-4 bg-rose-500/10 border border-rose-500/20 text-rose-400 text-sm px-4 py-3 rounded-2xl"
      >
        {{ formError }}
      </div>
      <div
        v-if="successMsg"
        class="mb-4 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-sm px-4 py-3 rounded-2xl"
      >
        {{ successMsg }}
      </div>

      <!-- Form -->
      <form @submit.prevent="handleSubmit" class="space-y-5">
        <div v-if="!isLoginMode" class="space-y-1">
          <label
            for="username"
            class="text-xs font-bold text-slate-300 uppercase tracking-wider block"
            >Username</label
          >
          <input
            id="username"
            v-model="username"
            type="text"
            required
            placeholder="e.g. Abdullah"
            class="w-full bg-slate-950/60 border border-slate-800 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 text-slate-100 text-sm px-4 py-3 rounded-xl outline-none transition-all duration-200"
          />
        </div>

        <div class="space-y-1">
          <label for="email" class="text-xs font-bold text-slate-300 uppercase tracking-wider block"
            >Email Address</label
          >
          <input
            id="email"
            v-model="email"
            type="email"
            required
            placeholder="abdullah@example.com"
            class="w-full bg-slate-950/60 border border-slate-800 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 text-slate-100 text-sm px-4 py-3 rounded-xl outline-none transition-all duration-200"
          />
        </div>

        <div class="space-y-1">
          <label
            for="password"
            class="text-xs font-bold text-slate-300 uppercase tracking-wider block"
            >Password</label
          >
          <input
            id="password"
            v-model="password"
            type="password"
            required
            placeholder="••••••••"
            class="w-full bg-slate-950/60 border border-slate-800 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 text-slate-100 text-sm px-4 py-3 rounded-xl outline-none transition-all duration-200"
          />
        </div>

        <button
          type="submit"
          :disabled="isSubmitting"
          class="w-full bg-gradient-to-r from-emerald-500 to-indigo-500 hover:from-emerald-400 hover:to-indigo-400 text-slate-950 font-bold py-3 rounded-xl shadow-lg transition-all duration-300 disabled:opacity-50 cursor-pointer"
        >
          <span v-if="isSubmitting">Please wait...</span>
          <span v-else>{{ isLoginMode ? 'Sign In' : 'Sign Up' }}</span>
        </button>
      </form>

      <!-- Toggle mode -->
      <div class="text-center mt-6">
        <button
          @click="toggleMode"
          class="text-xs font-bold text-slate-400 hover:text-slate-100 transition-colors"
        >
          {{ isLoginMode ? "Don't have an account? Sign Up" : 'Already have an account? Sign In' }}
        </button>
      </div>
    </div>
  </div>
</template>
