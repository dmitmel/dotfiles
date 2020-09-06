#!/usr/bin/env node

const fs = require('fs');
const argparse = require('argparse');
const markdownIt = require('markdown-it');
const markdownItTaskCheckbox = require('markdown-it-task-checkbox');
const markdownItEmoji = require('markdown-it-emoji');
const markdownItHeaderAnchors = require('./markdown-it-header-anchors');
const Prism = require('prismjs/components/prism-core');
const loadPrismLanguages = require('prismjs/components/');
const PRISM_COMPONENTS = require('prismjs/components.js');

// TODO: integrate <https://github.com/PrismJS/prism-themes>
const PRISM_THEMES = Object.keys(PRISM_COMPONENTS.themes).filter(
  (k) => k !== 'meta',
);

let parser = new argparse.ArgumentParser();

parser.addArgument('INPUT_FILE', {
  nargs: argparse.Const.OPTIONAL,
  help: '(stdin by default)',
});
parser.addArgument('OUTPUT_FILE', {
  nargs: argparse.Const.OPTIONAL,
  help: '(stdout by default)',
});

parser.addArgument('--input-encoding', {
  defaultValue: 'utf-8',
  help: '(utf-8 by default)',
});
parser.addArgument('--output-encoding', {
  defaultValue: 'utf-8',
  help: '(utf-8 by default)',
});

parser.addArgument('--no-default-stylesheets', {
  nargs: argparse.Const.SUPPRESS,
});
parser.addArgument('--syntax-theme', {
  choices: [...PRISM_THEMES, 'none', 'dotfiles'],
});

parser.addArgument('--stylesheet', {
  nargs: argparse.Const.ZERO_OR_MORE,
});
parser.addArgument('--script', {
  nargs: argparse.Const.ZERO_OR_MORE,
});

let args = parser.parseArgs();

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
md.use(markdownItEmoji);
md.use(markdownItHeaderAnchors);

let markdownDocument = fs.readFileSync(
  args.get('INPUT_FILE', 0),
  args.get('input_encoding'),
);
let renderedMarkdown = md.render(markdownDocument);

let stylesheetsTexts = [];
let scriptsTexts = [];
let syntaxThemeName = null;

if (!args.get('no_default_stylesheets')) {
  syntaxThemeName = 'dotfiles';
  stylesheetsTexts.push(
    fs.readFileSync(
      require.resolve('github-markdown-css/github-markdown.css'),
      'utf-8',
    ),
    fs.readFileSync(
      require.resolve('./github-markdown-additions.css'),
      'utf-8',
    ),
  );
}

syntaxThemeName = args.get('syntax_theme') || syntaxThemeName;
if (syntaxThemeName && syntaxThemeName !== 'none') {
  stylesheetsTexts.push(
    fs.readFileSync(
      require.resolve(
        syntaxThemeName === 'dotfiles'
          ? '../../colorschemes/out/prismjs-theme.css'
          : `prismjs/themes/${syntaxThemeName}.css`,
      ),
      'utf-8',
    ),
  );
}

for (let stylesheetPath of args.get('stylesheet', [])) {
  stylesheetsTexts.push(fs.readFileSync(stylesheetPath));
}

for (let scriptPath of args.get('script', [])) {
  scriptsTexts.push(fs.readFileSync(scriptPath));
}

let renderedHtmlDocument = `
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="X-UA-Compatible" content="ie=edge">
${stylesheetsTexts.map((s) => `<style>\n${s}\n</style>`).join('\n')}
</head>
<body>
<article class="markdown-body">
${renderedMarkdown}
</article>
${scriptsTexts.map((s) => `<script>\n${s}\n</script>`).join('\n')}
</body>
</html>
`.trim();

fs.writeFileSync(
  args.get('OUTPUT_FILE', 1),
  renderedHtmlDocument,
  args.get('output_encoding'),
);
