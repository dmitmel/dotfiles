const markdownIt = require('markdown-it');
const markdownItTaskCheckbox = require('markdown-it-task-checkbox');
const markdownItEmoji = require('markdown-it-emoji');
const markdownItHeaderAnchors = require('./markdown-it-header-anchors');
const Prism = require('prismjs/components/prism-core');
const createPrismLoader = require('prismjs/dependencies');
const PRISM_COMPONENTS = require('prismjs/components.js');

function toArray(value) {
  if (Array.isArray(value)) {
    return value;
  } else if (value != null) {
    return [value];
  } else {
    return [];
  }
}

function hasKey(obj, key) {
  return Object.prototype.hasOwnProperty.call(obj, key);
}

function createRenderer() {
  let availableSyntaxes = {};
  for (let [id, entry] of Object.entries(PRISM_COMPONENTS.languages)) {
    if (id !== 'meta') {
      entry = Object.assign({}, entry, {
        // Make all optional dependencies non-optional
        require: [].concat(toArray(entry.require), toArray(entry.optional), toArray(entry.modify)),
      });
    }
    availableSyntaxes[id] = entry;
  }

  // See <https://github.com/PrismJS/prism/blob/v1.27.0/components/index.js>
  function loadSyntaxes(list) {
    let components = { languages: availableSyntaxes };
    let loaded = Object.keys(Prism.languages);
    createPrismLoader(components, toArray(list), loaded).load((lang) => {
      if (hasKey(availableSyntaxes, lang)) {
        require(`prismjs/components/prism-${lang}`);
      } else {
        console.warn(`Language does not exist: ${lang}`);
      }
    });
  }

  let md = markdownIt({
    html: true,
    linkify: true,
    highlight: (code, lang) => {
      if (!lang) return null;
      loadSyntaxes(lang);
      if (!hasKey(Prism.languages, lang)) return null;
      return Prism.highlight(code, Prism.languages[lang], lang);
    },
  });
  md.use(markdownItTaskCheckbox);
  md.use(markdownItEmoji, { shortcuts: {} });
  md.use(markdownItHeaderAnchors);

  return (src) => md.render(src);
}

module.exports = createRenderer;
