/** @type {import('prismjs')} */
const Prism = require('prismjs/components/prism-core');
const createPrismLoader = require('prismjs/dependencies');
const PRISM_COMPONENTS = require('prismjs/components.js');

const PRISM_THEMES = Object.keys(PRISM_COMPONENTS.themes).filter((k) => k !== 'meta');

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

function highlight(/** @type {string} */ code, /** @type {string} */ lang) {
  if (!lang) return null;
  loadSyntaxes(lang);
  if (!hasKey(Prism.languages, lang)) return null;
  return Prism.highlight(code, Prism.languages[lang], lang);
}

module.exports = { Prism, PRISM_COMPONENTS, PRISM_THEMES, loadSyntaxes, highlight };
