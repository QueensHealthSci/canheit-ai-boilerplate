// Framework ESLint rules. Import and spread into the repo's eslint.config.js (flat config):
//
//   import framework from './eslint.framework.mjs';
//   export default [ ...yourBaseConfig, ...framework ];
//
// Run with --max-warnings=0 so a warning fails the build.
export default [
  {
    files: ['**/*.{ts,tsx,vue}'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'error',
      'vue/component-api-style': ['error', ['script-setup']],
      'import/order': ['error', { 'newlines-between': 'always', alphabetize: { order: 'asc' } }],
      'no-debugger': 'error',
      'no-console': ['error', { allow: ['warn', 'error'] }],
    },
  },
];
