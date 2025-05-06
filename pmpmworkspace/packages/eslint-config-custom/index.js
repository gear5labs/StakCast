module.exports = {
    root: true,
    extends: ['eslint:recommended', 'next', 'next/core-web-vitals'],
    parser: '@typescript-eslint/parser',
    plugins: ['@typescript-eslint'],
    rules: {
      semi: ['error', 'always'],
      quotes: ['error', 'single'],
    }
  };
  