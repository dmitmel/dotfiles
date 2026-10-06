#!/usr/bin/env node
/// <reference types="node" />
const fs = require('fs');
const Path = require('path');
const argparse = require('argparse');
const { PRISM_THEMES, highlight } = require('./syntax-highlighting');
const markdownIt = require('markdown-it');

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
    metavar: 'ENCODING',
    help: '(utf-8 by default)',
  });
  parser.add_argument('--output-encoding', {
    default: 'utf-8',
    metavar: 'ENCODING',
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
    metavar: 'FILE',
  });
  parser.add_argument('--script', {
    nargs: argparse.ZERO_OR_MORE,
    metavar: 'FILE',
  });

  let args = parser.parse_args();

  let md = markdownIt({
    html: true,
    linkify: true,
    highlight,
  });

  md.use(require('markdown-it-emoji').full, { shortcuts: {} });
  md.use(require('markdown-it-task-checkbox'));
  md.use(require('./markdown-it-header-anchors'));

  let markdownDocument = fs.readFileSync(args.INPUT_FILE || 0, args.input_encoding);
  let renderedMarkdown = md.render(markdownDocument);

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
  if (syntaxThemeName && syntaxThemeName !== 'none' && /^[\w-]+$/.test(syntaxThemeName)) {
    stylesheetsTexts.push(
      fs.readFileSync(
        require.resolve(
          syntaxThemeName === 'dotfiles'
            ? './themes-out/my-prismjs-theme.css'
            : `prismjs/themes/${syntaxThemeName}.min.css`,
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

  const trimTrailingNewline = (/** @type {string} */ s) => (s.endsWith('\n') ? s.slice(0, -1) : s);

  let renderedHtmlDocument = [
    '<!DOCTYPE html>',
    '<html>',
    '<head>',
    `<meta charset="${md.utils.escapeHtml(String(args.output_encoding).toUpperCase())}">`,
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
    '<meta http-equiv="X-UA-Compatible" content="ie=edge">',
    `<title>${md.utils.escapeHtml(Path.basename(args.INPUT_FILE || '<stdin>'))}</title>`,
    ...stylesheetsTexts
      .map(trimTrailingNewline)
      .map((s) => (!s.includes('\n') ? `<style>${s}</style>` : `<style>\n${s}\n</style>`)),
    '</head>',
    '<body>',
    '<article class="markdown-body">',
    trimTrailingNewline(renderedMarkdown),
    '</article>',
    ...scriptsTexts
      .map(trimTrailingNewline)
      .map((s) => (!s.includes('\n') ? `<script>${s}</script>` : `<script>\n${s}\n</script>`)),
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
