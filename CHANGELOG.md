# Changelog

All notable changes to **Iqamah (إقامة)** are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.1] — 2026-07-03

### Added
- **Mobile — Hybrid WebView Architecture:** Replaced the mobile UI screens with a high-performance `webview_flutter` container that loads compiled `client/dist` assets directly from the local asset bundle. This guarantees 100% UI/UX parity with the web client.
- **Mobile — Platform-Safe Conditional WebViews:** Implemented a stub-based platform-conditional registration structure (`webview_stub.dart`, `webview_mobile.dart`, `webview_web.dart`) preventing crashes when launching on unsupported platforms (like web/desktop).
- **Web + Mobile — Offline Streak Calculation:** Refactored the Dashboard streak counter (`loadStreak` in `DashboardView.vue`) to calculate streaks locally from browser/WebView `localStorage` data, resolving the static `12 দিন` default placeholder.

### Fixed
- **Web — Router Local Resolution:** Switched Vue Router to `createWebHashHistory` to resolve routing paths correctly within isolated, non-server environments (e.g. mobile assets served under the `file:///` protocol).
- **Web — Asset Paths:** Updated Vite build configuration to use relative paths (`base: './'`), allowing resources to load correctly without absolute server domains.
- **Web — Code Quality & Lint Cleanups:** Resolved all ESLint and TypeScript compilation issues (unused imports, any types, unused destructured parameters) across the Vue codebase to guarantee production build stability.
- **Mobile — Modern Key Parameters:** Refactored all constructor keys in Flutter widgets to use modern Dart `super.key` parameters.

### Changed
- **Mobile — `pubspec.yaml`:** version bumped `1.1.0+2 → 1.1.1+3`.
- **Client — `package.json`:** version bumped `1.0.0 → 1.1.1`.

---

## [1.1.0] — 2026-07-02

### Added
- **Offline-First Architecture (Web):** Fully decoupled from the ASP.NET Core backend. All prayer logs, Qaza records, and analytics are now stored in `localStorage` via a Pinia store, removing any server dependency for the client SPA.
- **Offline-First Architecture (Mobile):** Fixed `databaseFactory not initialized` crash on web/desktop. Integrated `sqflite_common_ffi` (native) and `sqflite_common_ffi_web` (web/WASM) with platform detection via `kIsWeb`.
- **Onboarding flow (Web + Mobile):** Replaced the JWT-based Login/Register flow with a local onboarding wizard that captures the user's name, preferred language (Bengali/English), and gender. Completion state is persisted locally.
- **Salah time engine (Web + Mobile):** Integrated the `adhan` library for offline, high-precision prayer time calculation and Makruh (forbidden prayer window) detection, based on GPS coordinates from the device.
- **Settings → Reset Application (Web):** A destructive action that clears all `localStorage` keys and re-routes to `/onboarding`.
- **Guide View (Web):** Fiqh reference guide with three tabs: Qaza Rules, Punctuality (Waqt), and App Usage.

### Changed
- **Web — `stores/auth.ts`:** Replaced JWT authentication logic with a local `has_completed_onboarding` flag and user profile persistence.
- **Web — `stores/prayer.ts`:** Migrated from REST API calls to full `localStorage` CRUD, streaks, and analytics computation performed in-browser.
- **Web — Router:** Removed `/login` and `/register` routes; added `/onboarding` with a completion guard.
- **Mobile — Theme:** Hardened dark Material Design 3 palette (`Color(0xFF0F172A)` background, `Color(0xFF5EEAD4)` primary).

### Removed
- **Web — `LoginView.vue`:** Removed the login/register view entirely; superseded by `OnboardingView.vue`.

---

## [1.0.0] — 2026-06-11

### Added
- Initial full-stack platform release.
- **Server (ASP.NET Core 10 / .NET 10):** Clean Architecture with `Iqamah.Domain`, `Iqamah.Application` (CQRS + MediatR), `Iqamah.Infrastructure` (EF Core + PostgreSQL), and `Iqamah.API` (JWT Bearer Auth, REST endpoints).
- **Web Client (Vue 3 + Vite + Tailwind CSS v4):** Dashboard, Qaza ledger, Analytics, and Salah time views. Pinia store with enum normalisation layer for backend enum deserialization.
- **Mobile (Flutter):** Offline SQLite companion with JSON export/import backup, bilingual (Bengali/English) UI, gender-aware Hayd/Nifas logging, Qaza fulfillment state machine.
- **Domain Model:** `PrayerLog` aggregate root, `QazaLog` child entity, domain events (`PrayerMissedDomainEvent`, `QazaFulfilledDomainEvent`), full `PrayerName`, `WaqtStatus`, `MissedReason`, `QazaState` enumerations.
- **Docker / Coolify:** Single-container deployment (Vue SPA served from ASP.NET Core, port 8080).
- **CI/CD:** GitHub Actions pipeline for build + test on push to `main`.
