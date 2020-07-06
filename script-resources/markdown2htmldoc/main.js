#!/usr/bin/env node

const fs = require('fs');
const argparse = require('argparse');
const markdownIt = require('markdown-it');
const markdownItTaskCheckbox = require('markdown-it-task-checkbox');
const markdownItEmoji = require('markdown-it-emoji');
const markdownItHeaderAnchors = require('./markdown-it-header-anchors');
const Prism = require('prismjs');
const loadPrismLanguages = require('prismjs/components/');

let parser = new argparse.ArgumentParser();
parser.addArgument('inputFile', {
  nargs: argparse.Const.OPTIONAL,
  metavar: 'INPUT_FILE',
  help: '(stdin by default)',
});
parser.addArgument('outputFile', {
  nargs: argparse.Const.OPTIONAL,
  metavar: 'OUTPUT_FILE',
  help: '(stdout by default)',
});
let args = parser.parseArgs();

let md = markdownIt({
  html: true,
  linkify: true,
  highlight: (str, lang) => {
    if (lang.length > 0) {
      loadPrismLanguages([lang]);
      if (Object.prototype.hasOwnProperty.call(Prism.languages, lang)) {
        return Prism.highlight(str, Prism.languages[lang], lang);
      }
    }
    return str;
  },
});
md.use(markdownItTaskCheckbox);
md.use(markdownItEmoji);
md.use(markdownItHeaderAnchors);

let markdownDocument = fs.readFileSync(args.get('inputFile', 0), 'utf-8');
let renderedMarkdown = md.render(markdownDocument);
let githubMarkdownCSS = fs.readFileSync(
  require.resolve('github-markdown-css/github-markdown.css'),
);
let syntaxHighlightingThemeCSS = fs.readFileSync(
  require.resolve('prismjs/themes/prism.css'),
);

let renderedHtmlDocument = `
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="X-UA-Compatible" content="ie=edge">
<style>
${githubMarkdownCSS}
</style>
<style>
${syntaxHighlightingThemeCSS}
</style>
<style>
html, body {
  padding: 0;
  margin: 0;
}
.markdown-body {
  max-width: 882px;
  margin: 0 auto;
  padding: 32px;
}
.octicon-link {
  font: normal normal 16px 'octicons-link';
  line-height: 1;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}
.octicon-link::before {
  content: '\\f05c';
}
</style>
</head>
<body>
<article class="markdown-body">
${renderedMarkdown}
</article>
</body>
</html>
`;

fs.writeFileSync(args.get('outputFile', 1), renderedHtmlDocument, 'utf-8');
