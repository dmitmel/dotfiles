#!/usr/bin/env node
/// <reference types="node" />
const fs = require('fs/promises');
const paths = require('path');
const postcss = require('postcss');
const postcssReporter = require('postcss-reporter');
const cssnano = require('cssnano');
const terser = require('terser');
const babelCodeFrame = require('@babel/code-frame');

async function main() {
  let templatePath = paths.resolve(__dirname, 'template.xslt');
  let stylesheetPath = paths.resolve(__dirname, 'styles.css');
  let scriptPath = paths.resolve(__dirname, 'script.js');

  let stylesheetSrc = await fs.readFile(stylesheetPath, 'utf8');
  let stylesheetCompiled = '';
  try {
    let result = await postcss
      .default()
      .use(postcssReporter())
      .use(cssnano())
      .process(stylesheetSrc, { from: stylesheetPath });
    stylesheetCompiled = result.css;
  } catch (error) {
    if (error.name === 'CssSyntaxError') {
      let message = `${error.name}: ${error.message}`;
      let code = error.showSourceCode();
      if (code.length > 0) {
        message = `${message}\n\n${code}\n`;
      }
      console.error(message);
      return process.exit(1);
    }
    throw error;
  }

  let scriptSrc = await fs.readFile(scriptPath, 'utf8');
  let scriptCompiled = '';
  try {
    let input = { [scriptPath]: scriptSrc };
    let result = await terser.minify(input, { mangle: false });
    scriptCompiled = result.code;
  } catch (error) {
    if (error.name === 'SyntaxError') {
      let location = { start: { line: error.line, column: error.col } };
      let message = `${error.name}: ${error.filename}:${error.line}:${error.col}: ${error.message}`;
      let code = babelCodeFrame.codeFrameColumns(scriptSrc, location, { highlightCode: true });
      if (code.length > 0) {
        message = `${message}\n\n${code}\n`;
      }
      console.error(message);
      return process.exit(1);
    }
    throw error;
  }

  let templateSrc = await fs.readFile(templatePath, 'utf8');
  let templateCompiled = templateSrc.replace(
    /(<!--\s*include\s+(\S+)\s+start\s*-->)[^]*(<!--\s*include\s+\2\s+end\s*-->)/g,
    (matched, includeStart, includedFile, includeEnd) => {
      let code = null;
      let wordCharRegex = null;
      if (includedFile === 'styles.css') {
        code = stylesheetCompiled;
        wordCharRegex = /[A-Za-z0-9_\-#]/;
      } else if (includedFile === 'script.js') {
        code = scriptCompiled;
        wordCharRegex = /[A-Za-z0-9_$]/;
      }
      if (code == null) {
        return matched;
      }

      // return `${includeStart}<![CDATA[${code}]]>${includeEnd}`;

      let xmlLines = [];
      // Note that wrapped text is not what is interpreted by the browser, it
      // is only wrapped for avoiding very long lines in the source code of the
      // XSLT template. After the template is evaluated, the broken text is
      // assembled back into a single minified long line.
      let wrapWidth = 200;
      for (let line of wrapText(code, wrapWidth, wordCharRegex)) {
        xmlLines.push(`  <xsl:text>${xmlEscape(line)}</xsl:text>`);
      }
      return `${includeStart}\n${xmlLines.join('\n')}\n${includeEnd}`;
    },
  );
  await fs.writeFile(templatePath, templateCompiled);

  process.exit(0);
}

/**
 * @param {string} text
 * @param {number} width
 * @param {RegExp} wordCharRegex
 * @returns {Generator<string>}
 */
function* wrapText(text, width, wordCharRegex) {
  let lineStart = 0;
  let wordStart = 0;
  let inWord = false;
  for (let i = 0, len = text.length; i < len; i++) {
    if (!wordCharRegex.test(text.charAt(i))) {
      // On a boundary
      inWord = false;
    } else if (!inWord) {
      // Just entered a word, mark it
      inWord = true;
      wordStart = i;
    }
    let insertBreakAt = -1;
    if (i - lineStart >= width) {
      // The line started overflowing
      if (!inWord) {
        // Text can be broken freely on boundaries
        insertBreakAt = i;
      } else if (wordStart > lineStart) {
        // But if we are in a word, check if it isn't the first one on the line
        insertBreakAt = wordStart;
      }
    }
    if (i + 1 === text.length) {
      // This will emit the final line
      insertBreakAt = i + 1;
    }
    if (insertBreakAt > 0) {
      let line = text.slice(lineStart, insertBreakAt);
      lineStart = insertBreakAt;
      yield line;
    }
  }
}

/**
 * <https://github.com/python/cpython/blob/v3.10.3/Lib/html/__init__.py#L12-L25>
 * @param {string} s
 * @param {?boolean} quote
 * @returns {string}
 */
function xmlEscape(s, quote = false) {
  s = s.replace(/&/g, '&amp;');
  s = s.replace(/</g, '&lt;');
  s = s.replace(/>/g, '&gt;');
  if (quote) {
    s = s.replace(/"/g, '&quot;');
    s = s.replace(/'/g, '&#x27;');
  }
  return s;
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
