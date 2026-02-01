import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tsconfigPaths from 'vite-tsconfig-paths'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  // @ts-ignore
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['src/CustomClassNameSetup.ts'], // اختياري إذا كان عندك إعدادات مسبقة
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'], // هذا السطر هو الأهم لإنتاج ملف lcov.info
      include: ['src/**/*'], // خليه يقرأ كل اللي جوه src
      all: true, // يحسب التغطية لكل الملفات حتى اللي مش معمولة ليها تست
    },
  },
})