import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export type Locale = 'en' | 'bn'

export const useLocaleStore = defineStore('locale', () => {
  const currentLocale = ref<Locale>((localStorage.getItem('iqamah_locale') as Locale) || 'en')

  const setLocale = (locale: Locale) => {
    currentLocale.value = locale
    localStorage.setItem('iqamah_locale', locale)
  }

  const toggleLocale = () => {
    setLocale(currentLocale.value === 'en' ? 'bn' : 'en')
  }

  const translations = {
    en: {
      // Navbar
      dashboard: 'Dashboard',
      qaza: 'Qaza',
      analytics: 'Analytics',
      salah_time: 'Salah Time',
      guide: 'Guide',
      logout: 'Logout',
      
      // Dashboard
      establish_salah: 'Establish Salah (إقامة)',
      salah_tagline: 'Track punctuality, log situational absences, and fulfill obligations.',
      select_date: 'Select Date',
      not_logged: 'Not Logged',
      log: 'Log',
      edit: 'Edit',
      
      // Logging Modal
      log_salah: 'Log {salah}',
      offered: 'Offered',
      missed: 'Missed',
      waqt_punctuality: 'Waqt Punctuality',
      options: 'Options',
      congregation: 'Congregation (Jamaah)',
      traveling: 'Traveling (Musafir)',
      friday_prayer: 'Friday Jumu\'ah Prayer',
      prayed_at_home: 'Prayed at Home',
      reason_missed: 'Reason for Missed Salah',
      quran_notes: 'Quran Reading Note',
      quran_notes_placeholder: 'e.g., Surah Al-Baqarah 1-10, Page 5',
      track_tasbih: 'TASBIH after Salah',
      period_hayd: 'Hayd / Nifas',
      save: 'Save Log',
      cancel: 'Cancel',
      no_qaza_required: 'No Qaza required',
      qaza_generated: 'Qaza Generated',
      excused_optgroup: 'Excused (No Sin, No Qaza)',
      unexcused_optgroup: 'Unexcused (Qaza Required)',

      // Gender preference
      gender_setting: 'Gender Setting',
      gender_male: 'Male (Mudhakkar)',
      gender_female: 'Female (Mu\'annath)',
      gender_note: 'Hayd / Nifas option is only shown for female users.',
      
      // Qaza Ledger
      qaza_ledger: 'Qaza Ledger (قضاء)',
      qaza_tagline: 'Rectify missed obligations. Fulfill pending make-up prayers.',
      outstanding_debt: 'Outstanding Qaza Debt',
      no_pending: 'No Pending Qaza!',
      no_pending_desc: 'Praise be to Allah, all your missed prayers are cleared.',
      fulfill: 'Fulfill',
      prayers_due: '{count} Prayers Due',
      days_ago: '{count} days ago',
      today: 'Today',
      yesterday: 'Yesterday',
      pending: 'Pending',
      
      // Analytics
      salah_analytics: 'Salah Analytics (تحليل)',
      analytics_tagline: 'Deep analytics on prayer habits, punctuality, and make-up progression.',
      offered_ratio: 'Offered Ratio',
      total_logged: 'Total Logged',
      obligation_rate: 'Obligation Rate',
      qaza_made_up: 'Qaza Made-Up',
      missed_count: 'Missed Count',
      waqt_distribution: 'Waqt Distribution',
      missed_reasons_dist: 'Missed Reasons Distribution',
      lifetime_resolution: 'Lifetime Qaza Resolution',
      total_incurred: 'Total Incurred',
      total_pending: 'Pending Debts',
      average_resolution: 'Avg. Resolution Time',
      salah_performance: 'Salah Performance Breakdown',
      prayer_name: 'Prayer Name',
      obligated: 'Obligated',
      performance: 'Performance',
      jamaah: 'Jamaah',
      days_7: '7 Days',
      days_30: '30 Days',
      year_1: '1 Year',
      custom: 'Custom',
      to: 'to',
      salahs_entries: 'Salah entries',
      salahs_performed: 'Salahs performed',
      salahs_missed: 'Salahs missed',
      makeup_prayers_logged: 'Make-up prayers logged',
      processing_analytics: 'Processing multi-year analytics...',
      no_analytics_data: 'No analytics data available for the selected range.',
      offered_percentage_desc: 'Excludes Excused Impurity',
      situational_absences: 'Situational Absences',
      excused_total: 'Excused Total',
      unexcused_total: 'Unexcused Total',
      salah_breakdown_metrics: 'Salah Breakdown Metrics',
      jamaah_count: 'Jamaah Count',
      jamaah_rate: 'Jamaah Rate',
      travel_count: 'Travel (Musafir)',
      home_count: 'Home Count',
      from_missed_to_makeup: 'From missed to make-up',
      total_lifetime_missed: 'Total lifetime missed',
      pending_in_current_ledger: 'Pending in current ledger',
      hours_abbr: '{hours} hrs',
      
      // Guide
      guide_title: 'Salah Guide & Documentation',
      guide_tagline: 'Learn the jurisprudential framework behind Iqamah\'s tracking system and get the most out of your analytical reports.',
      qaza_rules: 'Qaza (Make-up) Rules',
      qaza_rules_tagline: 'Familiarize yourself with jurisprudence regarding missed prayers.',
      waqt_punctuality_title: 'Waqt & Punctuality',
      waqt_tagline: 'Understanding Awwal, Wast, and Akhir al-Waqt.',
      app_usage: 'Using the Platform',
      app_usage_tagline: 'How to log Salah modifiers, track debts, and read charts.',
      qaza_rules_heading: 'Qaza (Make-up) Islamic Rules',
      qaza_rules_sub: 'Legal classifications of missed prayers in Fiqh.',
      qaza_rules_desc: 'In Islamic jurisprudence, daily prayers (Salawat) are strictly bound to their set times. If a prayer is missed, it becomes an outstanding obligation (Debt / Dayn) that remains due upon the individual until performed as a Qaza.',
      excused_sleep_title: 'Excused (Ma\'dhur) — Sleep & Forgetfulness',
      excused_sleep_desc: 'If you miss a prayer due to unintentional sleep (Nawm) or genuine forgetfulness (Nisyan), you are not sinful for missing the time. However, making up the prayer (Qaza) remains obligatory.',
      unexcused_laziness_title: 'Unexcused (Ghayr Ma\'dhur) — Neglect & Distraction',
      unexcused_laziness_desc: 'Missing a prayer due to worldly preoccupation (Shughl), laziness (Kasl), or distraction (Ghaflah) is a major sin. In addition to sincere repentance (Tawbah), the prayer must still be made up as Qaza.',
      excused_impurity_title: 'Excused Absence — Hayd / Nifas',
      excused_impurity_desc: 'During menstruation (Hayd) or post-natal bleeding (Nifas), women are legally exempt from praying. No sin is incurred, and no Qaza is required. Note: Janabah (major ritual impurity from marital relations, discharge, etc.) does NOT exempt from prayer — prayer remains obligatory and creates a Qaza debt if missed. The platform automatically excludes Hayd/Nifas days from obligated ratios.',
      punctuality_title: 'Waqt & Punctuality Windows',
      punctuality_sub: 'The classification of prayer timings.',
      punctuality_desc: 'Praying at the beginning of its time is highly beloved in Islam. The platform lets you log your punctuality based on the three classical segments of a prayer\'s Waqt:',
      awwal_waqt_title: 'Awwal al-Waqt (First Part)',
      awwal_waqt_desc: 'Offered within the first 15 to 20 minutes following the Adhan. This reflects maximum zeal, follows the Sunnah closely, and carries the highest spiritual reward.',
      wast_waqt_title: 'Wast al-Waqt (Middle Part)',
      wast_waqt_desc: 'Offered during the middle portion of the prayer window. It represents timely compliance before busy periods take over.',
      akhir_waqt_title: 'Akhir al-Waqt (Late Part)',
      akhir_waqt_desc: 'Offered near the end of the prayer window, just before the next prayer\'s time begins. Valid but discouraged to make a habit of delaying.',
      using_platform_title: 'Using the Iqamah Platform',
      using_platform_sub: 'How to navigate and log your prayer data.',
      using_platform_desc_1: 'On the main Dashboard, select a date from the calendar strip, then click Log next to any prayer. Mark whether you offered it, congregation status (Jamaah), travel status (Musafir), or if it was missed, pick a situational Missed Reason.',
      using_platform_desc_2: 'Any missed prayer (except Hayd / Nifas) creates a pending entry in the Qaza page. Once you make up that prayer, click Fulfill in the ledger to mark it as offered, automatically updating your charts.',
      using_platform_desc_3: 'The Dial Gauge on the Analytics page calculates your Offered Ratio mathematically: Offered % = Total Offered / (Total Obligated − Hayd/Nifas Days). This ensures jurisprudentially accurate percentages matching your actual religious obligations.',
      
      // Waqts & Reasons
      awwal: 'First (Awwal)',
      wast: 'Middle (Wast)',
      akhir: 'Late (Akhir)',
      impurity: 'Hayd / Nifas',
      sleep: 'Sleep',
      forgetfulness: 'Forgetfulness',
      situational: 'Busy / Situational',
      laziness: 'Laziness',
      distraction: 'Distraction',
      
      // Prayers
      fajr: 'Fajr',
      dhuhr: 'Dhuhr',
      asr: 'Asr',
      maghrib: 'Maghrib',
      isha: 'Isha\''
    },
    bn: {
      // Navbar
      dashboard: 'ড্যাশবোর্ড',
      qaza: 'কাজা',
      analytics: 'অ্যানালিটিক্স',
      salah_time: 'সালাতের সময়',
      guide: 'নির্দেশিকা',
      logout: 'লগআউট',
      
      // Dashboard
      establish_salah: 'সালাত কায়েম করুন (إقامة)',
      salah_tagline: 'সময়ানুবর্তিতা ট্র্যাক করুন, পরিস্থিতিগত অনুপস্থিতি নথিভুক্ত করুন এবং কাজা আদায় করুন।',
      select_date: 'তারিখ নির্বাচন করুন',
      not_logged: 'লিপিবদ্ধ করা হয়নি',
      log: 'লগ করুন',
      edit: 'সম্পাদনা',
      
      // Logging Modal
      log_salah: '{salah} সালাত লিপিবদ্ধ করুন',
      offered: 'আদায় করা হয়েছে',
      missed: 'ছুটে গেছে',
      waqt_punctuality: 'ওয়াক্তের সময়ানুবর্তিতা',
      options: 'বিকল্পসমূহ',
      congregation: 'জামায়াত (জামাতে)',
      traveling: 'সফররত (মুসাফির)',
      friday_prayer: 'জুমু\'আহর সালাত',
      prayed_at_home: 'বাসায় পড়েছেন',
      reason_missed: 'ছুটে যাওয়ার কারণ',
      quran_notes: 'কোরআন পাঠের নোট',
      quran_notes_placeholder: 'যেমন, সূরা আল-বাকারাহ ১-১০, পৃষ্ঠা ৫',
      track_tasbih: 'সালাতের পর তাসবীহ',
      period_hayd: 'হায়েজ / নিফাস (Hayd / Nifas)',
      save: 'লগ সংরক্ষণ করুন',
      cancel: 'বাতিল',
      no_qaza_required: 'কাজার প্রয়োজন নেই',
      qaza_generated: 'কাজা তৈরি হয়েছে',
      excused_optgroup: 'ক্ষমাযোগ্য ওজর (Excused)',
      unexcused_optgroup: 'ক্ষমা অযোগ্য (Unexcused)',
      
      // Qaza Ledger
      qaza_ledger: 'কাজা খতিয়ান (قضاء)',
      qaza_tagline: 'ছুটে যাওয়া সালাতের দায় সংশোধন করুন। অপেক্ষমান কাজা সালাত আদায় করুন।',
      outstanding_debt: 'বকেয়া কাজা সালাতসমূহ',
      no_pending: 'কোনো কাজা বাকি নেই!',
      no_pending_desc: 'আলহামদুলিল্লাহ, আপনার সব কাজা সালাত আদায় করা হয়েছে।',
      fulfill: 'আদায় করুন',
      prayers_due: '{count}টি সালাত বাকি',
      days_ago: '{count} দিন আগে',
      today: 'আজ',
      yesterday: 'গতকাল',
      pending: 'অপেক্ষমান',
      
      // Analytics
      salah_analytics: 'সালাত বিশ্লেষণ (تحليل)',
      analytics_tagline: 'সালাতের অভ্যাস, সময়ানুবর্তিতা এবং কাজা আদায়ের অগ্রগতির গভীর বিশ্লেষণ।',
      offered_ratio: 'আদায়ের হার',
      total_logged: 'মোট লিপিবদ্ধ',
      obligation_rate: 'বাধ্যতামূলক সালাতের হার',
      qaza_made_up: 'আদায়কৃত কাজা',
      missed_count: 'ছুটে যাওয়ার সংখ্যা',
      waqt_distribution: 'ওয়াক্ত বন্টন',
      missed_reasons_dist: 'ছুটে যাওয়ার কারণসমূহ',
      lifetime_resolution: 'আজীবন কাজা সমাধানের হিসাব',
      total_incurred: 'মোট সংঘটিত',
      total_pending: 'বাকি থাকা কাজা',
      average_resolution: 'গড় আদায়ের সময়',
      salah_performance: 'প্রতি সালাতের বিবরণ',
      prayer_name: 'সালাতের নাম',
      obligated: 'বাধ্যতামূলক',
      performance: 'সাফল্য',
      jamaah: 'জামায়াত',
      days_7: '৭ দিন',
      days_30: '৩০ দিন',
      year_1: '১ বছর',
      custom: 'কাস্টম',
      to: 'থেকে',
      salahs_entries: 'সালাত ভুক্তি',
      salahs_performed: 'আদায়কৃত সালাত',
      salahs_missed: 'ছুটে যাওয়া সালাত',
      makeup_prayers_logged: 'পূরণকৃত কাজা সালাত',
      processing_analytics: 'বিশ্লেষণ প্রক্রিয়াধীন...',
      no_analytics_data: 'নির্বাচিত সময়ের জন্য কোনো তথ্য পাওয়া যায়নি।',
      offered_percentage_desc: 'অপবিত্রতার দিনসমূহ ব্যতীত',
      situational_absences: 'পরিস্থিতিগত অনুপস্থিতি',
      excused_total: 'মোট ক্ষমাযোগ্য',
      unexcused_total: 'মোট ক্ষমা অযোগ্য',
      salah_breakdown_metrics: 'সালাত ভিত্তিক বিভাজন',
      jamaah_count: 'জামায়াতে আদায়ের সংখ্যা',
      jamaah_rate: 'জামায়াতে আদায়ের হার',
      travel_count: 'সফর (মুসাফির)',
      home_count: 'বাসায় আদায়',
      from_missed_to_makeup: 'ছুটে যাওয়া থেকে আদায়ের সময়',
      total_lifetime_missed: 'আজীবনের মোট ছুটে যাওয়া',
      pending_in_current_ledger: 'খতিয়ানে বকেয়া কাজা',
      hours_abbr: '{hours} ঘণ্টা',
      
      // Guide
      guide_title: 'সালাত নির্দেশিকা ও তথ্যাবলী',
      guide_tagline: 'ইকামার ট্র্যাকিং সিস্টেমের পেছনের ফিকহী কাঠামো সম্পর্কে জানুন এবং আপনার বিশ্লেষণাত্মক প্রতিবেদনটি সঠিকভাবে বিশ্লেষণ করুন।',
      qaza_rules: 'কাজা সালাতের নিয়ম',
      qaza_rules_tagline: 'ছুটে যাওয়া সালাত সম্পর্কিত ইসলামী ফিকহ ও বিধানসমূহ জেনে নিন।',
      waqt_punctuality_title: 'ওয়াক্ত ও সময়ানুবর্তিতা',
      waqt_tagline: 'আউয়াল, ওয়াসাত এবং আখির ওয়াক্ত সম্পর্কে স্পষ্ট ধারণা।',
      app_usage: 'প্ল্যাটফর্মের ব্যবহার',
      app_usage_tagline: 'কীভাবে সালাতের বিভিন্ন মোডিফায়ার যুক্ত করবেন, বকেয়া কাজা ট্র্যাক করবেন এবং চার্ট বিশ্লেষণ করবেন।',
      qaza_rules_heading: 'কাজা সালাতের ফিকহী নিয়ম',
      qaza_rules_sub: 'ফিকহ শাস্ত্রে ছুটে যাওয়া নামাজের আইনি শ্রেণীবদ্ধকরণ।',
      qaza_rules_desc: 'ইসলামী ফিকহ মতে, দৈনিক সালাত নির্দিষ্ট সময়ের সাথে কঠোরভাবে আবদ্ধ। যদি কোনো সালাত ছুটে যায়, তবে সেটি একটি বকেয়া ঋণ (দায়ন) হিসেবে থেকে যায়, যা আদায় (কাজা) না করা পর্যন্ত ব্যক্তির ওপর আবশ্যক থাকে।',
      excused_sleep_title: 'ক্ষমাযোগ্য ওজর (মা\'জুর) — ঘুম ও বিস্মৃতি',
      excused_sleep_desc: 'অনিচ্ছাকৃত ঘুম (নওম) বা প্রকৃত বিস্মৃতির (নিসইয়ান) কারণে সালাত ছুটে গেলে সময়মতো না পড়ার কারণে গুনাহ হবে না। তবে মনে পড়ার সাথে সাথে বা ঘুম থেকে ওঠার সাথে সাথে কাজা আদায় করা ফরজ।',
      unexcused_laziness_title: 'ক্ষমা অযোগ্য (গাইর মা\'জুর) — অবহেলা ও ব্যস্ততা',
      unexcused_laziness_desc: 'দুনিয়াবী ব্যস্ততা (শুগুল), অলসতা (কাসাল) বা বিভ্রান্তি/উদাসীনতার (গাফলাহ) কারণে সালাত ছেড়ে দেওয়া কবিরা গুনাহ। এর জন্য খাঁটি তাওবার পাশাপাশি যত দ্রুত সম্ভব সালাতের কাজা আদায় করা আবশ্যক।',
      excused_impurity_title: 'অব্যাহতিপ্রাপ্ত অবস্থা — হায়েজ / নিফাস',
      excused_impurity_desc: 'মাসিক ঋতুস্রাব (হায়েজ) বা সন্তান জন্মদান পরবর্তী রক্তক্ষরণের (নিফাস) সময় নারীরা সালাত আদায় করা থেকে শরীয়তসম্মতভাবে অব্যাহতিপ্রাপ্ত। কোনো গুনাহ নেই এবং কাজা আদায় করতে হবে না। লক্ষ্য করুন: জানাবাত (সহবাস, বীর্যপাত ইত্যাদির কারণে গোসল ফরজ হওয়া) নামাজ থেকে অব্যাহতি দেয় না — সেক্ষেত্রে নামাজ ফরজই থাকে এবং না পড়লে কাজা হবে। ইকামা অ্যাপ হায়েজ/নিফাসের দিনগুলো স্বয়ংক্রিয়ভাবে সালাতের অনুপাত হিসাব থেকে বাদ দেয়।',
      punctuality_title: 'ওয়াক্ত ও সালাত আদায়ের সময়',
      punctuality_sub: 'সালাত আদায়ের ওয়াক্তসমূহের বিভাজন।',
      punctuality_desc: 'ওয়াক্তের শুরুর দিকে সালাত আদায় করা ইসলামের অত্যন্ত প্রিয় আমল। ইকামা প্ল্যাটফর্মে আপনি সালাতের ওয়াক্তের তিনটি ধ্রুপদী অংশ অনুযায়ী আপনার সময়ানুবর্তিতা লিপিবদ্ধ করতে পারেন:',
      awwal_waqt_title: 'আউয়াল ওয়াক্ত (প্রথম অংশ)',
      awwal_waqt_desc: 'আজানের প্রথম ১৫ থেকে ২০ মিনিটের মধ্যে সালাত আদায় করা। এটি সর্বোচ্চ আগ্রহ ও সুন্নাহর যথাযথ অনুসরণ প্রকাশ করে এবং এর আধ্যাত্মিক সওয়াব সবচেয়ে বেশি।',
      wast_waqt_title: 'ওয়াসাত ওয়াক্ত (মধ্যবর্তী অংশ)',
      wast_waqt_desc: 'ওয়াক্তের মাঝামাঝি সময়ে সালাত আদায় করা। এটি কর্মব্যস্ততার মাঝে সময়মতো ফরজ আদায়ের প্রতীক।',
      akhir_waqt_title: 'আখির ওয়াক্ত (শেষ অংশ)',
      akhir_waqt_desc: 'ওয়াক্ত শেষ হওয়ার ঠিক কিছু সময় আগে (মাকরূহ সময়ের আগে) সালাত আদায় করা। এটি বৈধ হলেও অভ্যাসগতভাবে সালাত দেরিতে পড়া অনুৎসাহিত।',
      using_platform_title: 'ইকামা প্ল্যাটফর্ম ব্যবহার নির্দেশিকা',
      using_platform_sub: 'কীভাবে আপনার সালাতের তথ্য লিপিবদ্ধ এবং পরিচালনা করবেন।',
      using_platform_desc_1: 'মূল ড্যাশবোর্ডে, ক্যালেন্ডার স্ট্রিপ থেকে একটি তারিখ নির্বাচন করুন, তারপরে যেকোনো সালাতের পাশে **লগ** বাটনে ক্লিক করুন। আপনি সালাত আদায় করেছেন কি না, জামাতে পড়েছেন কি না, সফররত কি না তা নির্বাচন করুন। আর ছুটে গিয়ে থাকলে তার কারণটি বেছে নিন।',
      using_platform_desc_2: 'হায়েজ / নিফাস ছাড়া অন্য যেকোনো কারণে ছুটে যাওয়া সালাত কাজা পেজে অপেক্ষমান হিসেবে জমা হবে। যখনই কাজা আদায় করবেন, খতিয়ানের পাশে **আদায় করুন** বাটনে ক্লিক করুন।',
      using_platform_desc_3: 'বিশ্লেষণ পেজের ডায়াল গেজটি আপনার সালাত আদায়ের হার গণনা করে: আদায়ের হার = মোট আদায়কৃত / (মোট ওয়াক্ত − হায়েজ/নিফাসের দিনসমূহ)।',
      
      // Waqts & Reasons
      awwal: 'প্রথম (আউয়াল)',
      wast: 'মধ্যবর্তী (ওয়াসাত)',
      akhir: 'দেরিতে (আখির)',
      impurity: 'হায়েজ / নিফাস',

      // Gender preference
      gender_setting: 'লিঙ্গ নির্ধারণ',
      gender_male: 'পুরুষ (মুজাক্কার)',
      gender_female: 'নারী (মুআন্নাস)',
      gender_note: 'হায়েজ / নিফাস অপশন শুধুমাত্র নারী ব্যবহারকারীদের জন্য দেখানো হয়।',
      sleep: 'ঘুম (নওম)',
      forgetfulness: 'ভুলে যাওয়া (নিসইয়ান)',
      situational: 'ব্যস্ততা / পরিস্থিতিগত',
      laziness: 'অলসতা (কাসাল)',
      distraction: 'উদাসীনতা (গাফলাহ)',
      
      // Prayers
      fajr: 'ফজর',
      dhuhr: 'যোহর',
      asr: 'আসর',
      maghrib: 'মাগরিব',
      isha: 'এশা'
    }
  }

  const t = computed(() => {
    return (key: keyof typeof translations['en'], params?: Record<string, string | number>) => {
      let text = translations[currentLocale.value][key] || translations['en'][key] || key
      if (params) {
        for (const [k, v] of Object.entries(params)) {
          text = text.replace(`{${k}}`, String(v))
        }
      }
      return text
    }
  })

  return {
    currentLocale,
    setLocale,
    toggleLocale,
    t
  }
})
