const Prism = require('prismjs/components/prism-core');
const createPrismLoader = require('prismjs/dependencies');

/** @type {createPrismLoader.Components} */
const PRISM_COMPONENTS = require('prismjs/components.js');

const PRISM_THEMES = Object.keys(PRISM_COMPONENTS.themes).filter((k) => k !== 'meta');

/**
 * TypeScript's definition of `Array.isArray()` does not do type narrowing for
 * readonly arrays correctly, see these threads:
 * <https://github.com/microsoft/TypeScript/issues/17002> and
 * <https://github.com/microsoft/TypeScript/issues/41808>. Hence I have to make
 * a wrapper for it that deals only with readonly arrays, due to the definitions
 * for `prismjs/dependencies` using them generously
 * (<https://github.com/DefinitelyTyped/DefinitelyTyped/blob/cf18b26599b77d4ac1f37433fc43124736639372/types/prismjs/dependencies.d.ts>).
 *
 * @param {unknown} value
 * @returns {value is readonly unknown[]}
 */
function isArray(value) {
  return Array.isArray(value);
}

/**
 * @template T
 * @param {T | readonly T[] | null | undefined} value
 * @returns {readonly T[]}
 */
function toArray(value) {
  if (isArray(value)) {
    return value;
  } else if (value != null) {
    return [value];
  } else {
    return [];
  }
}

function hasKey(/** @type {object} */ obj, /** @type {PropertyKey} */ key) {
  return Object.prototype.hasOwnProperty.call(obj, key);
}

/** @type {createPrismLoader.ComponentCategory} */
let availableSyntaxes = {};
for (let [id, entry] of Object.entries(PRISM_COMPONENTS.languages)) {
  if (id !== 'meta' && typeof entry === 'object') {
    entry = Object.assign({}, entry, {
      // Make all optional dependencies non-optional
      require: [...toArray(entry.require), ...toArray(entry.optional), ...toArray(entry.modify)],
    });
  }
  availableSyntaxes[id] = entry;
}

// See <https://github.com/PrismJS/prism/blob/v1.27.0/components/index.js>
function loadSyntaxes(/** @type {string | readonly string[]} */ list) {
  /** @type {Readonly<createPrismLoader.Components>} */
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

/** @returns {string | null} */
function highlight(
  /** @type {string} */ code,
  /** @type {string} */ lang,
  /** @type {string} */ _attrs,
) {
  if (!lang) return null;
  loadSyntaxes(lang);
  if (!hasKey(Prism.languages, lang)) return null;
  return Prism.highlight(code, Prism.languages[lang], lang);
}

module.exports = { Prism, PRISM_COMPONENTS, PRISM_THEMES, loadSyntaxes, highlight };
