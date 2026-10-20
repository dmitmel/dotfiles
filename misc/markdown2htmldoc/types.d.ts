/// <reference types="node" />
/// <reference types="jest" />

declare module 'prismjs/components/prism-core' {
  export * from 'prismjs';
}

// I have to provide my own typings for this package because it does not come
// types of its own, and the typings in the `@types/markdown-it-emoji` package
// from DefinitelyTyped currently depend on the `@types/markdown-it`, the
// counterpart of the markdown-it v14, which is now obsolete, as markdown-it has
// been rewritten in TypeScript for v15 and ships its own types together with
// the library.
declare module 'markdown-it-emoji' {
  import { MarkdownIt } from 'markdown-it';

  /** <https://github.com/markdown-it/markdown-it-emoji#init> */
  export interface Options {
    defs?: Record<string, string>;
    shortcuts?: Record<string, string | string[]>;
    enabled?: string[];
  }

  function emoji_plugin(md: MarkdownIt, options?: emoji_plugin.Options): void;

  export { emoji_plugin as bare, emoji_plugin as light, emoji_plugin as full };
}
