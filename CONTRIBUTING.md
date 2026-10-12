# Contributing to Iqamah

First off, thank you for considering contributing to Iqamah! It is people like you who make open source projects amazing.

Please review the guidelines below to make contributing as easy and transparent as possible.

## 🤝 Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct (detailed in [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)). Please report any unacceptable behavior.

## 🚀 How Can I Contribute?

### Reporting Bugs
* **Check existing issues:** Before opening a new issue, search the issue tracker to see if the problem has already been reported.
* **Be specific:** Provide as much detail as possible, including steps to reproduce, expected vs. actual behavior, screenshots, and logs.
* **Environment details:** State the Vue/Flutter versions, Android version, WebView/browser, and OS you are using. The .NET backend is retired.

### Requesting Features
* **Describe the need:** Explain why this feature is useful and what problem it solves.
* **Propose a solution:** Outline how you think the feature should work or look.

### Submitting Pull Requests
1. **Fork the Repository:** Create a personal copy of the repository on GitHub.
2. **Create a Branch:** Name your branch descriptively (e.g., `feature/analytics-export`).
3. **Write Tests:** Ensure your changes are covered by automated unit tests (Vitest / Flutter).
4. **Code Quality:** Ensure all client checks pass by running `bun run lint` and `bun run type-check`.
5. **Commit Messages:** Follow standard conventional commit formats (e.g., `feat: ...`, `fix: ...`, `docs: ...`, `refactor: ...`).
6. **Submit PR:** Target the `main` branch. Provide a detailed description of the changes.

## 💻 Development Setup

Please refer to the **Quick Start** section in [README.md](README.md) to set up the client and mobile development environments.

## 🎨 Coding Standards

### Frontend (Vue 3 / TypeScript)
* Use the Composition API with `<script setup lang="ts">`.
* Use Tailwind CSS v4 variables and semantic theme tokens (`--iq-*`) rather than ad-hoc inline styles.
* Strictly enforce type safety. Avoid using `any` types.
* Keep components reusable and well-documented.

### Mobile (Flutter / Dart)
* Follow clean widget composition principles.
* Use `super.key` constructors and adherence to `flutter_lints`.

## 🧪 Testing Checklist
Before submitting a pull request, run the following:

```bash
# Client validation
cd client
bun run lint
bun run type-check
bun run test:unit -- --run

# Mobile validation
cd ../mobile
flutter analyze
flutter test
```
