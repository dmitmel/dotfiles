#!/usr/bin/env node

const fs = require('fs');
const pathM = require('path');
const argparse = require('argparse');
const markdownIt = require('markdown-it');
const markdownItTaskCheckbox = require('markdown-it-task-checkbox');
const markdownItEmoji = require('markdown-it-emoji');
const markdownItHeaderAnchors = require('./markdown-it-header-anchors');
const Prism = require('prismjs/components/prism-core');
const loadPrismLanguages = require('prismjs/components/');
const PRISM_COMPONENTS = require('prismjs/components.js');

// TODO: integrate <https://github.com/PrismJS/prism-themes>
const PRISM_THEMES = Object.keys(PRISM_COMPONENTS.themes).filter((k) => k !== 'meta');

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

loadPrismLanguages(); // loads all languages

let md = markdownIt({
  html: true,
  linkify: true,
  highlight: (code, lang) => {
    if (lang && Object.prototype.hasOwnProperty.call(Prism.languages, lang)) {
      return Prism.highlight(code, Prism.languages[lang], lang);
    }
    return null;
  },
});
md.use(markdownItTaskCheckbox);
md.use(markdownItEmoji, { shortcuts: {} });
md.use(markdownItHeaderAnchors);

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

let renderedHtmlDocument = `
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="X-UA-Compatible" content="ie=edge">
<title>${pathM.basename(args.INPUT_FILE || '<stdin>')}</title>
${stylesheetsTexts
  .map((s) => {
    let st = s.trim();
    return !st.includes('\n') ? `<style>${st}</style>` : `<style>\n${s}\n</style>`;
  })
  .join('\n')}
</head>
<body>
<article class="markdown-body">
${renderedMarkdown}
</article>
${scriptsTexts
  .map((s) => {
    let st = s.trim();
    return !st.includes('\n') ? `<script>${st}</script>` : `<script>\n${s}\n</script>`;
  })
  .join('\n')}
</body>
</html>
`.trim();

fs.writeFileSync(args.OUTPUT_FILE || 1, renderedHtmlDocument, args.output_encoding);
