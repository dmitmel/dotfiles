#!/usr/bin/env node
/// <reference types="node" />
const fs = require('fs');
const Path = require('path');
const argparse = require('argparse');
const PRISM_COMPONENTS = require('prismjs/components.js');
const createRenderer = require('./renderer');

// TODO: integrate <https://github.com/PrismJS/prism-themes>
const PRISM_THEMES = Object.keys(PRISM_COMPONENTS.themes).filter((k) => k !== 'meta');

async function main() {
  let parser = new argparse.ArgumentParser();

  parser.add_argument('INPUT_FILE', {
    nargs: argparse.OPTIONAL,
    help: '(stdin by default)',
  });
  parser.add_argument('OUTPUT_FILE', {
    nargs: argparse.OPTIONAL,
    help: '(stdout by default)',
  });

  parser.add_argument('--input-encoding', {
    default: 'utf-8',
    help: '(utf-8 by default)',
  });
  parser.add_argument('--output-encoding', {
    default: 'utf-8',
    help: '(utf-8 by default)',
  });

  parser.add_argument('--theme', {
    choices: ['dotfiles', 'github', 'none'],
    default: 'dotfiles',
  });
  parser.add_argument('--syntax-theme', {
    choices: [...PRISM_THEMES, 'none', 'dotfiles'],
  });

  parser.add_argument('--stylesheet', {
    nargs: argparse.ZERO_OR_MORE,
  });
  parser.add_argument('--script', {
    nargs: argparse.ZERO_OR_MORE,
  });

  let args = parser.parse_args();

  let render = createRenderer();

  let markdownDocument = fs.readFileSync(args.INPUT_FILE || 0, args.input_encoding);
  let renderedMarkdown = render(markdownDocument);

  let stylesheetsTexts = [];
  let scriptsTexts = [];
  let syntaxThemeName = 'dotfiles';

  if (args.theme === 'dotfiles') {
    stylesheetsTexts.push(fs.readFileSync(require.resolve('./themes-out/my.css'), 'utf-8'));
  } else if (args.theme === 'github') {
    stylesheetsTexts.push(fs.readFileSync(require.resolve('./themes-out/github.css'), 'utf-8'));
  } else {
    syntaxThemeName = 'none';
  }

  syntaxThemeName = args.syntax_theme || syntaxThemeName;
  if (syntaxThemeName && syntaxThemeName !== 'none') {
    stylesheetsTexts.push(
      fs.readFileSync(
        require.resolve(
          syntaxThemeName === 'dotfiles'
            ? './themes-out/my-prismjs-theme.css'
            : `prismjs/themes/${syntaxThemeName}.css`,
        ),
        'utf-8',
      ),
    );
  }

  for (let stylesheetPath of args.stylesheet || []) {
    stylesheetsTexts.push(fs.readFileSync(stylesheetPath));
  }

  for (let scriptPath of args.script || []) {
    scriptsTexts.push(fs.readFileSync(scriptPath));
  }

  let renderedHtmlDocument = [
    '<!DOCTYPE html>',
    '<html>',
    '<head>',
    '<meta charset="UTF-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
    '<meta http-equiv="X-UA-Compatible" content="ie=edge">',
    `<title>${Path.basename(args.INPUT_FILE || '<stdin>')}</title>`,
    ...stylesheetsTexts.map((s) => {
      let st = s.trim();
      return !st.includes('\n') ? `<style>${st}</style>` : `<style>\n${s}\n</style>`;
    }),
    '</head>',
    '<body>',
    '<article class="markdown-body">',
    renderedMarkdown,
    '</article>',
    ...scriptsTexts.map((s) => {
      let st = s.trim();
      return !st.includes('\n') ? `<script>${st}</script>` : `<script>\n${s}\n</script>`;
    }),
    '</body>',
    '</html>',
  ].join('\n');

  fs.writeFileSync(args.OUTPUT_FILE || 1, renderedHtmlDocument, args.output_encoding);

  return 0;
}

main().then(
  (code) => {
    process.exitCode = code;
  },
  (error) => {
    console.error(error);
    process.exitCode = 1;
  },
);
