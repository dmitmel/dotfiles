import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    execArgv: ['--enable-source-maps'],
    // <https://vitest.dev/guide/common-errors#commonjs-source-code-is-not-fully-supported>
    experimental: { viteModuleRunner: false },
  },
});
