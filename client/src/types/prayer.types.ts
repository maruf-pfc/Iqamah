/**
 * @file prayer.types.ts
 * @description Mirrors the C# Domain enums and entities from Iqamah.Domain.
 *              All values must stay in sync with server-side enum integer mappings.
 */

// ── Enums ─────────────────────────────────────────────────────────────────────

/** The five obligatory daily prayers (Salawat al-Khams). */
export const enum PrayerName {
  Fajr = 0,
  Dhuhr = 1,
  Asr = 2,
  Maghrib = 3,
  Isha = 4,
}

/** Human-readable Arabic/English labels for display. */
export const PRAYER_LABELS: Record<PrayerName, string> = {
  [PrayerName.Fajr]: 'Fajr (فجر)',
  [PrayerName.Dhuhr]: 'Dhuhr (ظهر)',
  [PrayerName.Asr]: 'Asr (عصر)',
  [PrayerName.Maghrib]: 'Maghrib (مغرب)',
  [PrayerName.Isha]: "Isha' (عشاء)",
}

/**
 * Prayer punctuality relative to its Waqt (time window).
 * Only populated when a prayer IS offered.
 */
export const enum WaqtStatus {
  /** Awwal al-Waqt — within 15-20 mins of Adhan. Highest merit. */
  AwwalAlWaqt = 0,
  /** Wast al-Waqt — middle of the Waqt window. */
  WastAlWaqt = 1,
  /** Akhir al-Waqt — near expiry of the Waqt window. */
  AkhirAlWaqt = 2,
}

export const WAQT_LABELS: Record<WaqtStatus, string> = {
  [WaqtStatus.AwwalAlWaqt]: 'Awwal al-Waqt (First)',
  [WaqtStatus.WastAlWaqt]: 'Wast al-Waqt (Middle)',
  [WaqtStatus.AkhirAlWaqt]: 'Akhir al-Waqt (Late)',
}

/**
 * Reason a prayer was missed.
 * Drives the Qaza state machine — ExcusedImpurity is the only value
 * that does NOT generate a Qaza obligation.
 */
export const enum MissedReason {
  // Excused (Ma'dhur) — no sin incurred
  /** Hayd/Nifas — menstruation or post-natal bleeding. NO Qaza required. */
  ExcusedImpurity = 0,
  /** Nawm — unintentional sleep. Qaza is obligatory. */
  ExcusedSleep = 1,
  /** Nisyan — genuine forgetfulness. Qaza is obligatory. */
  ExcusedForgetfulness = 2,

  // Unexcused (Ghayr Ma'dhur) — sin incurred
  /** Shughl — preoccupied with worldly matters. */
  UnexcusedSituational = 3,
  /** Kasl — laziness or deliberate neglect. */
  UnexcusedLaziness = 4,
  /** Ghaflah — heedlessness / distraction. */
  UnexcusedDistraction = 5,
}

export const MISSED_REASON_LABELS: Record<MissedReason, string> = {
  [MissedReason.ExcusedImpurity]: 'Ritual Impurity (Hayd/Nifas) — No Qaza',
  [MissedReason.ExcusedSleep]: 'Sleep (Nawm) — Excused',
  [MissedReason.ExcusedForgetfulness]: 'Forgetfulness (Nisyan) — Excused',
  [MissedReason.UnexcusedSituational]: 'Busy / Situational (Shughl)',
  [MissedReason.UnexcusedLaziness]: 'Laziness (Kasl)',
  [MissedReason.UnexcusedDistraction]: 'Distraction (Ghaflah)',
}

/** Lifecycle state of a Qaza make-up prayer obligation. */
export const enum QazaState {
  /** Outstanding debt — not yet made up. */
  Pending = 0,
  /** Fulfilled — make-up prayer performed. Terminal state. */
  Offered = 1,
}

// ── Interfaces (API payload shapes) ──────────────────────────────────────────

/** Represents a single prayer record returned from the API. */
export interface PrayerLogDto {
  readonly id: string // UUID
  readonly userId: number
  readonly prayerName: PrayerName
  readonly prayerDate: string // ISO date: "YYYY-MM-DD"
  readonly isOffered: boolean
  readonly waqtStatus: WaqtStatus | null
  readonly missedReason: MissedReason | null
  readonly isJamaah: boolean
  readonly isTraveling: boolean
  readonly isJummah: boolean
  readonly loggedAt: string // ISO 8601 UTC
  readonly qazaLog: QazaLogDto | null
}

/** Represents a Qaza obligation returned from the API. */
export interface QazaLogDto {
  readonly id: string // UUID
  readonly prayerLogId: string
  readonly userId: number
  readonly prayerName: PrayerName
  readonly originalPrayerDate: string // ISO date: "YYYY-MM-DD"
  readonly state: QazaState
  readonly createdAt: string // ISO 8601 UTC
  readonly fulfilledAt: string | null
  readonly timeToResolutionSeconds: number | null
}

// ── Request bodies ─────────────────────────────────────────────────────────

/** Request body for logging an offered prayer. */
export interface LogOfferedPrayerRequest {
  prayerName: PrayerName
  prayerDate: string // "YYYY-MM-DD"
  waqtStatus: WaqtStatus
  isJamaah?: boolean
  isTraveling?: boolean
  isJummah?: boolean
}

/** Request body for logging a missed prayer. */
export interface LogMissedPrayerRequest {
  prayerName: PrayerName
  prayerDate: string // "YYYY-MM-DD"
  missedReason: MissedReason
  isTraveling?: boolean
}

/** Request body to mark a pending Qaza as fulfilled. */
export interface FulfillQazaRequest {
  qazaLogId: string
}

// ── Type guards ────────────────────────────────────────────────────────────

export const isExcusedMissedReason = (reason: MissedReason): boolean =>
  reason === MissedReason.ExcusedImpurity ||
  reason === MissedReason.ExcusedSleep ||
  reason === MissedReason.ExcusedForgetfulness

export const requiresQaza = (reason: MissedReason): boolean =>
  reason !== MissedReason.ExcusedImpurity

// ── Analytics DTOs ──────────────────────────────────────────────────────────

export interface PunctualityStatsDto {
  readonly awwalAlWaqtCount: number
  readonly wastAlWaqtCount: number
  readonly akhirAlWaqtCount: number
  readonly awwalAlWaqtPercentage: number
  readonly wastAlWaqtPercentage: number
  readonly akhirAlWaqtPercentage: number
}

export interface MissedReasonsStatsDto {
  readonly excusedImpurityCount: number
  readonly excusedSleepCount: number
  readonly excusedForgetfulnessCount: number
  readonly unexcusedSituationalCount: number
  readonly unexcusedLazinessCount: number
  readonly unexcusedDistractionCount: number
  readonly totalExcused: number
  readonly totalUnexcused: number
}

export interface PrayerSpecificStatsDto {
  readonly totalObligated: number
  readonly totalOffered: number
  readonly offeredPercentage: number
  readonly jamaahCount: number
  readonly jamaahPercentage: number
  readonly travelingCount: number
}

export interface QazaSummaryStatsDto {
  readonly totalPending: number
  readonly totalFulfilled: number
  readonly totalIncurred: number
  readonly averageResolutionTimeHours: number
}

export interface AnalyticsResponseDto {
  readonly totalLogged: number
  readonly totalObligated: number
  readonly totalOffered: number
  readonly totalMissed: number
  readonly offeredPercentage: number
  readonly punctuality: PunctualityStatsDto
  readonly missedReasons: MissedReasonsStatsDto
  readonly prayerStats: Record<string, PrayerSpecificStatsDto>
  readonly qazaSummary: QazaSummaryStatsDto
}
