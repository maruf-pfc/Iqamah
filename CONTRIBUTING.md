# Contributing to Iqamah

First off, thank you for considering contributing to Iqamah! It is people like you who make open source projects amazing.

Please review the guidelines below to make contributing as easy and transparent as possible.

## 🤝 Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct (detailed in [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)). Please report any unacceptable behavior.

## 🚀 How Can I Contribute?

### Reporting Bugs
* **Check existing issues:** Before opening a new issue, search the issue tracker to see if the problem has already been reported.
* **Be specific:** Provide as much detail as possible, including steps to reproduce, expected vs. actual behavior, screenshots, and logs.
* **Environment details:** State the client framework version, .NET version, browser, and OS you are using.

### Requesting Features
* **Describe the need:** Explain why this feature is useful and what problem it solves.
* **Propose a solution:** Outline how you think the feature should work or look.

### Submitting Pull Requests
1. **Fork the Repository:** Create a personal copy of the repository on GitHub.
2. **Create a Branch:** Name your branch descriptively (e.g., `feature/analytics-export` or `bugfix/jwt-expiration`).
3. **Write Tests:** Ensure your changes are covered by unit tests (both in C# and Vitest).
4. **Code Quality:** Ensure all client checks pass by running `npm run lint` and `npm run type-check`. Ensure the server compiles without warnings.
5. **Commit Messages:** Follow standard conventional commit formats (e.g., `feat: ...`, `fix: ...`, `docs: ...`, `refactor: ...`).
6. **Submit PR:** Target the `main` branch. Provide a detailed description of the changes.

## 💻 Development Setup

Please refer to the **Getting Started** section in the [README.md](README.md) to set up the client and server development environments.

## 🎨 Coding Standards

### Backend (.NET)
* Follow clean architecture and domain-driven design principles.
* Use CQRS patterns (via MediatR) for application commands and queries.
* Name classes and variables according to standard C# casing guidelines (PascalCase for classes/methods, camelCase for local variables/parameters).
* Keep controllers thin; domain logic belongs in the domain/application layers.

### Frontend (Vue 3 / TypeScript)
* Use the Composition API with `<script setup lang="ts">`.
* Use Tailwind CSS v4 variables and theme configuration rather than ad-hoc inline styles.
* Strictly enforce type safety. Avoid using `any` types.
* Keep components reusable and well-documented.

## 🧪 Testing Checklist
Before submitting a pull request, run the following:

```bash
# Server tests
cd server
dotnet test

# Client validation
cd client
npm run lint
npm run type-check
npm run test:unit -- --run
```
