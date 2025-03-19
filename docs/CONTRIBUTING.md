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

---

## 📜 Code of Conduct
By contributing, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).  
Please read it before making any contributions.

---

## 🔧 Getting Started
Before contributing, ensure you have the following installed:
- [Node.js](https://nodejs.org/) 
- [Git](https://git-scm.com/)
- A code editor (e.g., [VS Code](https://code.visualstudio.com/))
- [Cairo Language](https://github.com/starkware-libs/cairo)

---

## ⚙️ Setting Up the Development Environment
1. **Fork the Repository**  
   Click the "Fork" button at the top right of the repository page.

2. **Clone Your Fork**  
   ```bash
   https://github.com/gear5labs/StakCast.git
   cd stakcast
   ```

3. **Install Dependencies**  
   ```bash
   pnpm install
   ```

4. **Start the Development Server**  
   ```bash
   pnpm run dev
   ```
   Open `http://localhost:3000` in your browser to see the app running.

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

## 🛠 Making Changes
1. **Create a New Branch**  
   ```bash
   git checkout -b feature-branch-name
   ```

2. **Make Your Changes**  
   Write code, add tests if applicable, and update the documentation.

3. **Run Tests**  
   ```bash
   pnpm test
   ```

4. **Commit Your Changes**  
   ```bash
   git add .
   git commit -m "Describe your changes"
   ```

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
If you encounter a bug or have a suggestion, please [open an issue](https://github.com/gear5labs/StakCast.git/issues) and include:
- A clear description of the problem
- Steps to reproduce it
- Screenshots or error messages (if applicable)

---

Thank you for contributing to Stakcast! 🎉

