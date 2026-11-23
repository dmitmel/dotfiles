const fs = require('fs/promises');
const Path = require('path');
const crypto = require('crypto');
const util = require('util');
const http = require('http');
const { isObject, checkErrorName, checkErrorCode } = require('./utils');

/** @typedef {(markdown: string) => string} MarkdownRendererFn */

/** @typedef {{ isolated?: boolean, render?: MarkdownRendererFn }} MarkdownTestOptions */

/** @typedef {{ markdown: string, options: MarkdownTestOptions }} MarkdownTestSnippet */

function createMarkdownTestingHarness(/** @type {MarkdownRendererFn} */ render) {
  function mdtest(
    /** @type {string} */ markdown,
    /** @type {string} */ expectedHtml,
    /** @type {MarkdownTestOptions} */ options = {},
  ) {
    expectedHtml = String(expectedHtml).replace(/^\n/, '').replace(/\n\n+/g, '\n');
    let actualHtml = options.render ? options.render(markdown) : render(markdown);
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
    /** @type {Set<MarkdownTestSnippet>} */
    let snippets = new Set();
    for (let testImpl of allTestFunctions) {
      testImpl((markdown, _html, options = {}) => {
        snippets.add({ markdown, options });
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
  /** @type {Iterable<MarkdownTestSnippet>} */ requestedSnippets,
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

  /** @type {Map<string, string>} */ let cachedSnippets = new Map();

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

  /** @type {Map<string, MarkdownTestSnippet>} */ let snippetsById = new Map();
  /** @type {Set<String>} */ let missingBatchedSnippets = new Set();
  /** @type {Set<String>} */ let missingIsolatedSnippets = new Set();

  renderedSnippets.clear();

  for (let snippet of requestedSnippets) {
    let { markdown } = snippet;
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
    let collidingSnippet = snippetsById.get(id);
    if (collidingSnippet != null && collidingSnippet.markdown !== snippet.markdown) {
      throw new Error(
        `ID collision between markdown snippets ${util.inspect(snippet.markdown)} and ${util.inspect(collidingSnippet.markdown)}`,
      );
    }
    snippetsById.set(id, snippet);

    let html = cachedSnippets.get(markdown);
    if (typeof html === 'string') {
      renderedSnippets.set(markdown, html);
    } else if (!renderedSnippets.has(markdown)) {
      (snippet.options.isolated ? missingIsolatedSnippets : missingBatchedSnippets).add(id);
    }
  }

  if (missingBatchedSnippets.size > 0) {
    // To save on API requests (unauthenticated users get 60 requests per hour,
    // and I don't want to bother with authentication), I am gonna concatenate
    // all markdown snippets in a big document, separated by markers which
    // GitHub's markdown renderer definitely won't generate (but which will pass
    // the HTML sanitization), render this entire document in one request, and
    // then split the resulting HTML document into the individual snippets. This
    // method does rely on the individual Markdown snippets not having side
    // effects that extend beyond a single paragraph, as otherwise a broken
    // snippet can mess up the rendering of other unrelated ones.
    let batchedSnippets = '';
    for (let [id, snippet] of snippetsById) {
      if (!snippet.options.isolated) {
        batchedSnippets += `<div>snippetStart(${id})</div>\n\n${snippet.markdown}\n\n<div>snippetEnd(${id})</div>\n\n`;
      }
    }

    let htmlDocument = await renderMarkdownOnGithub(batchedSnippets);

    for (let [_, id, html] of htmlDocument.matchAll(
      /<div>snippetStart\(([^)]+?)\)<\/div>\n([\s\S]*?\n)<div>snippetEnd\(\1\)<\/div>/g,
    )) {
      let snippet = snippetsById.get(id);
      if (snippet != null) {
        renderedSnippets.set(snippet.markdown, html);
      }
    }
  }

  if (missingIsolatedSnippets.size > 0) {
    // GitHub's documentation warns against making requests to the API concurrently:
    // <https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api?apiVersion=2026-03-10#avoid-concurrent-requests>
    for (let id of missingIsolatedSnippets) {
      let snippet = snippetsById.get(id);
      let html = await renderMarkdownOnGithub(snippet.markdown);
      if (!html.endsWith('\n')) html += '\n';
      renderedSnippets.set(snippet.markdown, html);
    }
  }

  // Only write the database file if the data in it was actually modified.
  if (
    missingBatchedSnippets.size > 0 ||
    missingIsolatedSnippets.size > 0 ||
    cachedSnippets.size !== renderedSnippets.size
  ) {
    let json = {
      version: DATABASE_FORMAT_VERSION,
      snippets: /** @type {Record<string, string>} */ ({}),
    };

    // Sort the snippets back into the order of definition, to ensure that their
    // order in the database file remains stable, even if they were assigned or
    // fetched and stored in the map `renderedSnippets` in a different order.
    for (let snippet of requestedSnippets) {
      let rendered = renderedSnippets.get(snippet.markdown);
      if (typeof rendered === 'string') {
        json.snippets[snippet.markdown] = rendered;
      }
    }

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

/** @type {number?} */
let prevGithubRequestTimestamp = null;

async function renderMarkdownOnGithub(/** @type {string} */ markdown, gfm = true) {
  if (prevGithubRequestTimestamp != null) {
    // GitHub's docs strongly suggest not to send more than 900 requests per
    // minute to their REST API. We can easily throttle the rate of requests
    // from our side by sleeping if not enough time has passed since the last
    // request.
    // <https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2026-03-10#:~:text=No%20more%20than%20900%20points%20per%20minute%20are%20allowed%20for%20REST%20API%20endpoints>
    const MAX_REQUESTS_PER_MINUTE = 900;
    const MAX_REQUESTS_PER_SECOND = MAX_REQUESTS_PER_MINUTE / 60;
    const MIN_REQUEST_INTERVAL = 1 / MAX_REQUESTS_PER_SECOND;
    const MIN_REQUEST_INTERVAL_MS = MIN_REQUEST_INTERVAL * 1000;

    let nextRequestPossibleAt = prevGithubRequestTimestamp + MIN_REQUEST_INTERVAL_MS;
    let waitUntilNextRequest = nextRequestPossibleAt - performance.now();

    if (waitUntilNextRequest > 0) {
      await new Promise((resolve) => setTimeout(resolve, waitUntilNextRequest));
    }
  }

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

  let res = null;
  try {
    prevGithubRequestTimestamp = performance.now();
    res = await fetch(req);

    if (!res.ok) {
      let rateLimitMsg = '';

      if (res.status === 403 /* Forbidden */ || res.status === 429 /* Too Many Requests */) {
        let rateLimitReset = res.headers.get('x-ratelimit-reset') || '';
        if (/^[0-9]+$/.test(rateLimitReset)) {
          let remainingSeconds = Math.ceil(parseInt(rateLimitReset, 10) - Date.now() / 1000);
          if (remainingSeconds > 0) {
            let remainingMinutes = Math.ceil(remainingSeconds / 60);

            let remainingTime =
              remainingMinutes > 0 ? `${remainingMinutes} minutes` : `${remainingSeconds} seconds`;
            rateLimitMsg = `\nPlease try again in ${remainingTime}`;
          }
        }
      }

      let statusText = res.statusText || http.STATUS_CODES[res.status] || '';
      throw new Error(`${req.method} ${req.url} => ${res.status} ${statusText}${rateLimitMsg}`);
    }

    let contentType = new util.MIMEType(res.headers.get('content-type') || '');
    if (!(contentType.essence === 'text/html' && contentType.params.get('charset') === 'utf-8')) {
      throw new Error(`${req.method} ${req.url} => unrecognized content type: ${contentType}`);
    }

    let html = await res.text();

    return html;
  } catch (error) {
    // Undici wraps network errors into `TypeError('fetch failed')` with the
    // `error.cause` set to the real error.
    // <https://github.com/nodejs/undici/blob/e5c9d703e63cd5ad691b8ce26e3f9a81c598f2e3/lib/fetch/index.js#L223-L230>
    // <https://github.com/octokit/request.js/blob/999fad9ce9ed4e9428c7e17da1795c80d1df52d6/src/fetch-wrapper.ts#L65-L75>
    // The network errors need to be unwrapped for display to the user because
    // of this bug in Vitest: <https://github.com/vitest-dev/vitest/issues/11973>.
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
  } finally {
    if (res != null && res.body != null && !res.bodyUsed) {
      // <https://undici.nodejs.org/#garbage-collection>
      await consumeEntireResponseBody(res.body).catch((_ignored) => {});
    }
  }
}

async function consumeEntireResponseBody(/** @type {ReadableStream<unknown>} */ body) {
  for await (let _chunk of body) {
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
