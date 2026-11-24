// Configures the `markdown-it-footnote` plugin to generate the same HTML that
// Github.com does.
// <https://github.com/markdown-it/markdown-it-footnote/blob/4.0.0/index.mjs>

const GithubSlugger = require('github-slugger');

/** @import * as md from 'markdown-it' */

function markdownItFootnoteCustomizations(
  /** @type {md.MarkdownIt} */ md,
  { idPrefix = '', sectionLabelId = 'footnote-label' } = {},
) {
  const { escapeHtml } = md.utils;

  function meta(/** @type {md.Token} */ token) {
    return /** @type {{ id?: number, subId?: number, label?: string }} */ (token.meta);
  }

  function formatId(
    /** @type {md.Env} */ env,
    /** @type {string} */ kind,
    /** @type {string} */ id,
  ) {
    id = `${idPrefix}${kind}-${id}`;
    if (typeof env.docId === 'string') id = `${id}-${env.docId}`;
    return escapeHtml(id);
  }

  md.renderer.rules['footnote_anchor_name'] = function (tokens, idx) {
    return escapeHtml(GithubSlugger.slug(meta(tokens[idx]).label));
  };

  md.renderer.rules['footnote_block_open'] = function () {
    return (
      '<section data-footnotes="" class="footnotes">' +
      `<h2 id="${escapeHtml(sectionLabelId)}" class="sr-only">Footnotes</h2>\n` +
      '<ol class="footnotes-list">\n'
    );
  };

  md.renderer.rules['footnote_block_close'] = function () {
    return '</ol>\n</section>\n';
  };

  md.renderer.rules['footnote_caption'] = function (tokens, idx) {
    return String((meta(tokens[idx]).id || 0) + 1);
  };

  md.renderer.rules['footnote_ref'] = function (tokens, idx, options, env, self) {
    let id = self.rules['footnote_anchor_name'](tokens, idx, options, env, self);
    let caption = self.rules['footnote_caption'](tokens, idx, options, env, self);

    let subId = (meta(tokens[idx]).subId || 0) + 1;
    let refId = subId > 1 ? `${id}-${subId}` : id;

    return (
      '<sup class="footnote-ref">' +
      `<a href="#${formatId(env, 'fn', id)}" id="${formatId(env, 'fnref', refId)}"` +
      ` data-footnote-ref="" aria-describedby="${escapeHtml(sectionLabelId)}">${caption}</a>` +
      '</sup>'
    );
  };

  md.renderer.rules['footnote_open'] = function (tokens, idx, options, env, self) {
    let id = self.rules['footnote_anchor_name'](tokens, idx, options, env, self);
    return `<li id="${formatId(env, 'fn', id)}" class="footnote-item">\n`;
  };

  md.renderer.rules['footnote_close'] = function () {
    return '</li>\n';
  };

  md.renderer.rules['footnote_anchor'] = function (tokens, idx, options, env, self) {
    let id = self.rules['footnote_anchor_name'](tokens, idx, options, env, self);

    let subId = (meta(tokens[idx]).subId || 0) + 1;
    let refId = subId > 1 ? `${id}-${subId}` : id;

    let ord = String((meta(tokens[idx]).id || 0) + 1);
    if (subId > 1) ord = `${ord}-${subId}`;

    return (
      ' ' +
      `<a href="#${formatId(env, 'fnref', refId)}" data-footnote-backref=""` +
      ` aria-label="Back to reference ${escapeHtml(ord)}" class="data-footnote-backref">` +
      // <https://github.com/markdown-it/markdown-it-footnote/pull/11>
      // U+21A9 is a return arrow, U+FE0E is Variation Selector-15
      '\u21a9\uFE0E' +
      `${subId > 1 ? `<sup>${subId}</sup>` : ''}</a>`
    );
  };
}

module.exports = markdownItFootnoteCustomizations;
