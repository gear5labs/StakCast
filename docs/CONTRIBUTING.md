# Contributing to Stakcast

Thank you for your interest in contributing to Stakcast! 🚀  
We welcome contributions of all kinds, whether it's fixing bugs, improving documentation, or adding new features.  
Please follow this guide to ensure a smooth contribution process.

---

## Table of Contents
1. [Code of Conduct](#code-of-conduct)  
2. [Getting Started](#getting-started)  
3. [Setting Up the Development Environment](#setting-up-the-development-environment)  
4. [Working on the Cairo Smart Contracts](#working-on-the-cairo-smart-contracts)  
5. [Making Changes](#making-changes)  
6. [Submitting a Pull Request](#submitting-a-pull-request)  
7. [Reporting Issues](#reporting-issues)  
8. [Security Reporting](#security-reporting)
---

## 📜 Code of Conduct
By contributing, you agree to have read our getting Started [Getting Started](/docs/GettingStarted.md).  
Please read it before making any contributions.

---

## 🔧 Getting Started
Before contributing, ensure you have the following installed:
- [Node.js](https://nodejs.org/)  
- [Git](https://git-scm.com/)
- A code editor (e.g., [VS Code](https://code.visualstudio.com/))
- [Cairo Language](https://github.com/starkware-libs/cairo)
- [pnpm](https://pnpm.io/)

We use **pnpm workspaces** for package management and **Husky** for git hooks enforcement.

For detailed setup instructions, refer to [GettingStarted.md](/docs/GettingStarted.md).

---

## ⚙️ Setting Up the Development Environment
1. **Fork the Repository**  
2. **Clone Your Fork**  
3. **Install Dependencies**  
4. **Start the Development Server**  
   For detailed  instructions, refer to [GettingStarted.md](/docs/GettingStarted.md).
---

## ⚡ Working on the Cairo Smart Contracts
Stakcast includes smart contracts written in [Cairo](https://cairo-lang.org/) for deployment on StarkNet. Follow these steps to contribute to the contract code:

### 🔧 Setting Up Cairo & StarkNet Dev Environment
1. **Install Scarb (Cairo's package manager)**  
   ```bash
   curl -L https://raw.githubusercontent.com/software-mansion/scarb/master/install.sh | bash
   ```
2. **Verify Installation**  
   ```bash
   scarb --version
   ```
3. **Compile the Contracts**  
   Navigate to the `contracts` folder and run:
   ```bash
   cd contracts
   scarb build
   ```
4. **Run Tests**  
   ```bash
   snforge test
   ```

---

## 🛠 Making Changes
1. **Create a Feature Branch**  
   We use **feature branches** for all new changes. Please create one before making any modifications:
   ```bash
   git checkout -b feature-branch-name
   ```

2. **Make Your Changes**  
   - Write code, add tests if applicable, and update the documentation.
   - Ensure your changes follow the project's coding style.

3. **Run Tests**  
   ```bash
   pnpm test
   ```

4. **Commit Your Changes**  
   ```bash
   git add .
   git commit -m "Describe your changes"
   ```

Husky will run pre-commit hooks to enforce formatting and linting.

---

## 🔀 Submitting a Pull Request
1. **Push Your Changes**  
   ```bash
   git push origin feature-branch-name
   ```

2. **Create a Pull Request**  
   - Go to the [Pull Requests](https://github.com/gear5labs/StakCast.git/pulls) page.  
   - Click "New Pull Request."  
   - Provide a clear title and description.  

3. **Wait for Review**  
   A maintainer will review your pull request and provide feedback.

---

## 🐛 Reporting Issues
If you encounter a bug or have a feature request, please [open an issue](https://github.com/gear5labs/StakCast.git/issues). Your issue should include:
- A **clear description** of the problem or feature request.
- **Why** the change is necessary.
- Steps to reproduce the issue (if applicable).
- Avoid unnecessary long, AI-generated descriptions—keep it concise and relevant.
- When applying to an issue, mention your estimated **ETA**.
- We expect a **draft PR** within **48 hours** of assignment, even if it's incomplete—this shows progress has started.

---
## Security Reporting
If you find a security vulnerability, please do not open a public issue. Instead contact us for responsible disclosure.

---
Thank you for contributing to Stakcast! 🎉
