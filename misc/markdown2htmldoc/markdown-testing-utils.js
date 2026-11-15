const fs = require('fs/promises');
const Path = require('path');
const crypto = require('crypto');
const util = require('util');
const { isObject, checkErrorName, checkErrorCode } = require('./utils');

function createMarkdownTestingHarness(/** @type {(markdown: string) => string} */ render) {
  function mdtest(/** @type {string} */ markdown, /** @type {string} */ expectedHtml) {
    expectedHtml = String(expectedHtml).replace(/\n\n+/g, '\n').replace(/^\n/, '');
    let actualHtml = render(markdown);
    try {
      expect(actualHtml).toBe(expectedHtml);
    } catch (error) {
      if (checkErrorName(error, 'AssertionError')) {
        // <https://kentcdodds.com/blog/improve-test-error-messages-of-your-abstractions>
        Error.captureStackTrace(error, mdtest);
      }
      throw error;
    }
  }

  /** @typedef {(mdtest_: typeof mdtest) => void} MarkdownTestFunction */

  /** @type {MarkdownTestFunction[]} */
  let allTestFunctions = [];

  function collect(/** @type {MarkdownTestFunction} */ testImpl) {
    allTestFunctions.push(testImpl);
    return testImpl.bind(null, mdtest);
  }

  function extractAllMarkdownSnippets() {
    /** @type {Set<string>} */
    let snippets = new Set();
    for (let testImpl of allTestFunctions) {
      testImpl((markdown, _html) => {
        snippets.add(markdown);
      });
    }
    return snippets;
  }

  return { collect, extractAllMarkdownSnippets };
}

const DATABASE_FORMAT_VERSION = 1;

async function refreshFetchedSnippetsDatabase(
  /** @type {Map<string, string>} */ renderedSnippets,
  /** @type {string} */ databasePath,
  /** @type {Iterable<string>} */ requestedSnippets,
) {
  renderedSnippets.clear();

  let text = await fs.readFile(databasePath, 'utf-8').catch((/** @type {unknown} */ error) => {
    if (checkErrorCode(error, 'ENOENT')) {
      // The `null` needs to be cast to a `string` because of the disabled
      // `strictNullChecks`, so that the type of the variable `text` resolves to
      // `string`, and not `any`.
      return /** @type {string?} */ (null);
    } else {
      throw error;
    }
  });

  let cachedSnippets = new Map();

  if (text != null && text.length !== 0) {
    /** @type {unknown} */
    let data = JSON.parse(text);

    if (isObject(data) && 'version' in data && data.version === DATABASE_FORMAT_VERSION) {
      if ('snippets' in data && isObject(data.snippets)) {
        cachedSnippets = new Map(
          Object.entries(data.snippets).filter(([_key, val]) => typeof val === 'string'),
        );
      }
    }
  }

  let snippetsById = new Map();
  let missingSnippets = new Map();

  for (let markdown of requestedSnippets) {
    // I want the IDs to be stable and deterministic, as that would help with
    // caching the responses from the REST API (although I'm not doing any such
    // caching currently) -- a weak hash function would be more than enough for
    // this. Also, on my laptop, SHA-1 seems to be faster than MD5, which is why
    // I picked the former.
    let id = crypto.hash('sha1', markdown, 'base64url');

    if (markdown.includes(id)) {
      throw new Error(
        `markdown snippet ${util.inspect(markdown)} contains its own ID ${util.inspect(id)}`,
      );
    }
    if (snippetsById.has(id) && snippetsById.get(id) !== markdown) {
      throw new Error(
        `ID collision between markdown snippets ${util.inspect(markdown)} and ${util.inspect(snippetsById.get(id))}`,
      );
    }
    snippetsById.set(id, markdown);

    let html = cachedSnippets.get(markdown);
    if (typeof html === 'string') {
      renderedSnippets.set(markdown, html);
    } else if (!renderedSnippets.has(markdown)) {
      missingSnippets.set(id, markdown);
    }
  }

  if (missingSnippets.size > 0) {
    // To save on API requests (unauthenticated users get 60 requests per hour,
    // and I don't want to bother with authentication), I am gonna concatenate
    // all markdown snippets in a big document, separated by markers which
    // GitHub's markdown renderer definitely won't generate (but which will pass
    // the HTML sanitization), render this entire document in one request, and
    // then split the resulting HTML document into the individual snippets. This
    // method does rely on the individual Markdown snippets not having side
    // effects that extend beyond a single paragraph, as otherwise a broken
    // snippet can mess up the rendering of other unrelated ones.
    let dummyDocument = '';
    for (let [id, markdown] of snippetsById) {
      dummyDocument += `<div>snippetStart(${id})</div>\n\n${markdown}\n\n<div>snippetEnd(${id})</div>\n\n`;
    }

    let htmlDocument = await renderMarkdownOnGithub(dummyDocument);

    renderedSnippets.clear();
    for (let [_, id, html] of htmlDocument.matchAll(
      /<div>snippetStart\(([^)]+?)\)<\/div>\n([\s\S]*?\n)<div>snippetEnd\(\1\)<\/div>/g,
    )) {
      if (snippetsById.has(id)) {
        renderedSnippets.set(snippetsById.get(id), html);
      }
    }
  }

  // Only write the database file if the data in it was actually modified.
  if (missingSnippets.size > 0 || cachedSnippets.size !== renderedSnippets.size) {
    let json = {
      version: DATABASE_FORMAT_VERSION,
      snippets: Object.fromEntries(renderedSnippets),
    };

    let text = JSON.stringify(json, null, 2);
    text += '\n';

    // Ensure that the saved JSON contains only ASCII characters.
    // <https://stackoverflow.com/a/31652607/12005228>
    text = text.replace(/[^\t\n\r\x20-\x7E]/g, (c) => {
      return `\\u${c.charCodeAt(0).toString(16).padStart(4, '0')}`;
    });

    await fs.mkdir(Path.dirname(databasePath), { recursive: true });
    await fs.writeFile(databasePath, text, 'utf-8');
  }
}

async function renderMarkdownOnGithub(/** @type {string} */ markdown, gfm = true) {
  // <https://docs.github.com/en/rest/markdown/markdown?apiVersion=2026-03-10#render-a-markdown-document>
  let req = new Request('https://api.github.com/markdown', {
    method: 'POST',
    headers: {
      'content-type': 'application/json; charset=utf-8',
      accept: 'text/html; charset=utf-8',
      'user-agent': 'https://github.com/dmitmel/dotfiles/tree/master/misc/markdown2htmldoc',
      'X-GitHub-Api-Version': '2026-03-10',
    },
    body: JSON.stringify({
      mode: gfm ? 'gfm' : 'markdown',
      text: markdown,
    }),
  });

  let res = await fetch(req).catch(unwrapNetworkErrors);
  if (!res.ok) {
    throw new Error(`${req.method} ${req.url} => ${res.status} ${res.statusText}`);
  }

  let contentType = new util.MIMEType(res.headers.get('content-type') || '');
  if (!(contentType.essence === 'text/html' && contentType.params.get('charset') === 'utf-8')) {
    throw new Error(`${req.method} ${req.url} => unrecognized content type: ${contentType}`);
  }

  let html = await res.text().catch(unwrapNetworkErrors);

  return html;
}

/** @returns {never} */
function unwrapNetworkErrors(/** @type {unknown} */ error) {
  // Undici wraps network errors into `TypeError('fetch failed')` with the
  // `error.cause` set to the real error.
  // https://github.com/nodejs/undici/blob/e5c9d703e63cd5ad691b8ce26e3f9a81c598f2e3/lib/fetch/index.js#L223-L230
  // https://github.com/octokit/request.js/blob/999fad9ce9ed4e9428c7e17da1795c80d1df52d6/src/fetch-wrapper.ts#L65-L75
  if (
    error instanceof TypeError &&
    error.message === 'fetch failed' &&
    'cause' in error &&
    error.cause instanceof Error
  ) {
    throw error.cause;
  } else {
    throw error;
  }
}

function createHtmlBuilders(
  /** @type {{ fromGithubApi: boolean, hardBreaksMode: boolean }} */
  { fromGithubApi, hardBreaksMode },
) {
  let builders = {};

  builders.concat = (/** @type {string[]} */ ...strings) => strings.join('');
  builders.concatLines = (/** @type {string[]} */ ...strings) => `${strings.join('\n')}\n`;

  let blockTag = (/** @type {string} */ nameAndAttrs, /** @type {string[]} */ ...body) => {
    let onlyName = nameAndAttrs.split(/\s+/, 1)[0];
    return `\n<${nameAndAttrs}>${body.join('')}</${onlyName}>\n`;
  };
  builders.blockTag = blockTag;

  builders.ul = blockTag.bind(null, 'ul');
  builders.ol = blockTag.bind(null, 'ol');
  builders.li = blockTag.bind(null, 'li');
  builders.p = blockTag.bind(null, 'p');
  builders.blockquote = blockTag.bind(null, 'blockquote');
  builders.h1 = blockTag.bind(null, 'h1');
  builders.h2 = blockTag.bind(null, 'h2');

  builders.hardbr = '<br>\n';
  builders.softbr = hardBreaksMode ? builders.hardbr : '\n';

  // <https://stackoverflow.com/questions/9628507/how-can-i-tell-google-translate-to-not-translate-a-section-of-a-website>
  let notranslate = fromGithubApi ? ' class="notranslate"' : '';
  let code = (/** @type {string} */ body) => `<code${notranslate}>${body}</code>`;
  builders.pre = (/** @type {string} */ body) => blockTag(`pre${notranslate}`, code(body));
  builders.code = code;

  builders.em = (/** @type {string[]} */ ...body) => `<em>${body.join('')}</em>`;

  builders.comment = (/** @type {string} */ text) => (fromGithubApi ? '' : `<!--${text}-->`);

  builders.img = (/** @type {string} */ alt, /** @type {string} */ src) =>
    fromGithubApi
      ? `<a target="_blank" rel="noopener noreferrer" href="${src}"` +
        `><img src="${src}" alt="${alt}" style="max-width: 100%;"></a>`
      : `<img src="${src}" alt="${alt}">`;

  return Object.freeze(builders);
}

module.exports = {
  createMarkdownTestingHarness,
  refreshFetchedSnippetsDatabase,
  renderMarkdownOnGithub,
  createHtmlBuilders,
};
