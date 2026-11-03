const fs = require('fs/promises');
const Path = require('path');
const crypto = require('crypto');
const util = require('util');
const MarkdownIt = require('markdown-it');
const markdownItTasklist = require('./markdown-it-tasklist');

/** @returns {{ [group: string]: { [markdown: string]: string } }} */
function makeTestCases(fromGithubApi = false) {
  const ul = (/** @type {string[]} */ ...body) => `<ul>\n${body.join('\n')}\n</ul>\n`;
  const li = (/** @type {string} */ body) => `<li>${body}</li>`;

  const taskList = (/** @type {string[]} */ ...body) =>
    `<ul class="contains-task-list">\n${body.join('\n')}\n</ul>\n`;

  const taskListItem = (/** @type {boolean} */ checked) => (/** @type {string} */ body) =>
    `<li class="task-list-item"><input type="checkbox"${fromGithubApi ? ' id=""' : ''} disabled=""` +
    ` class="task-list-item-checkbox" aria-label="${checked ? 'Completed task' : 'Incomplete task'}"` +
    `${checked ? ' checked=""' : ''}>${body}</li>`;

  const checked = taskListItem(true);
  const unchecked = taskListItem(false);

  const pre = (/** @type {string} */ body) => {
    let notranslate = fromGithubApi ? ' class="notranslate"' : '';
    return `\n<pre${notranslate}><code${notranslate}>${body}</code></pre>\n`;
  };

  return {
    'basic cases': {
      '- [x] hi!': taskList(checked(' hi!')),
      '- [ ] hi!': taskList(unchecked(' hi!')),
    },

    'no text after marker': {
      '- [ ]': ul(li('[ ]')),
      '- [ ] ': ul(li('[ ]')),
      '- [x]    ': ul(li('[x]')),
    },

    'does not break links': {
      '- [x](link)': ul(li('<a href="link">x</a>')),
    },

    // NOTE: this is a quirk of GitHub's parser that I *don't* want to imitate.
    'escaped square brackets': {
      '- \\[x] text': fromGithubApi ? taskList(checked(' text')) : ul(li('[x] text')),
      '- [ \\] text': fromGithubApi ? taskList(unchecked(' text')) : ul(li('[ ] text')),
      '- \\[ \\] text': fromGithubApi ? taskList(unchecked(' text')) : ul(li('[ ] text')),
    },

    'square brackets as HTML entities': {
      '- &lsqb; ] lsqb': fromGithubApi ? taskList(unchecked(' lsqb')) : ul(li('[ ] lsqb')),
      '- [x&rsqb; rsqb': fromGithubApi ? taskList(checked(' rsqb')) : ul(li('[x] rsqb')),
      '- &lsqb;x&rsqb; lsqb + rsqb': fromGithubApi
        ? taskList(checked(' lsqb + rsqb'))
        : ul(li('[x] lsqb + rsqb')),
    },

    'list with and without checkboxes': {
      '- first\n- [x] second\n- [ ] third\n- normal\n- [x] checkbox again': taskList(
        li('first'),
        checked(' second'),
        unchecked(' third'),
        li('normal'),
        checked(' checkbox again'),
      ),
    },

    'long indent before checkbox marker': (() => {
      let taskListHTML = taskList(checked(' a'));
      let preCodeHTML = ul(li(pre('[x] a\n')));
      return {
        '-  [x] a': taskListHTML,
        '-   [x] a': taskListHTML,
        '-    [x] a': taskListHTML,
        '-     [x] a': preCodeHTML,
        '-      [x] a': ul(li(pre(' [x] a\n'))),
        '-\t[x] a': taskListHTML,
        '-\t [x] a': taskListHTML,
        '- \t [x] a': taskListHTML,
        '-  \t [x] a': taskListHTML,
        '-\t  [x] a': preCodeHTML,
        '- \t  [x] a': preCodeHTML,
        '-  \t  [x] a': preCodeHTML,
      };
    })(),

    'no space before checkbox marker': {
      '-[x]': '<p>-[x]</p>\n',
      '-[ ] text': '<p>-[ ] text</p>\n',
      '-[x] text': '<p>-[x] text</p>\n',
      '-[ ]': '<p>-[ ]</p>\n',
    },

    'linebreak between checkbox and text': {
      '- [x]\n  a': ul(li(`[x]${fromGithubApi ? '<br>' : ''}\na`)),
      '- [x] \n  a': ul(li(`[x]${fromGithubApi ? '<br>' : ''}\na`)),
      '- [x]  \n  a': ul(li('[x]<br>\na')),
      '- [x]\\\n  a': ul(li('[x]<br>\na')),
      '- [x] \\\n  a': taskList(checked(' <br>\na')),
      '- [x] \\ a': taskList(checked(' \\ a')),
    },
  };
}

describe('my markdown-it plugin', () => {
  for (let [group, cases] of Object.entries(makeTestCases(false))) {
    describe(group, () => {
      test.each(Object.entries(cases))('%j', (markdown, html) => {
        let md = new MarkdownIt().use(markdownItTasklist);
        expect(md.render(markdown)).toBe(html);
      });
    });
  }
});

describe("GitHub's /markdown API", () => {
  const TEST_CASES = makeTestCases(true);
  const DATABASE_PATH = Path.join(__dirname, 'fixtures', 'rendered-by-github', 'tasklist.json');
  const DATABASE_FORMAT_VERSION = 1;

  let renderedSnippets = new Map();

  beforeAll(async () => {
    renderedSnippets.clear();

    // NOTE: Can't use a narrower assertion like `x is Record<string, unknown>`
    // because then type narrowing with the `in` operator stops working.
    // <https://www.reddit.com/r/typescript/comments/tq3m4f/the_difference_between_object_and_recordstring/>
    /** @returns {x is object} */
    function isObject(/** @type {unknown} */ x) {
      // eslint-disable-next-line eqeqeq
      return typeof x === 'object' && x !== null && !Array.isArray(x);
    }

    let text = await fs.readFile(DATABASE_PATH, 'utf8').catch((/** @type {unknown} */ error) => {
      if (isObject(error) && 'code' in error && error.code === 'ENOENT') {
        // The `null` needs to be cast to a `string` because of the disabled
        // `strictNullChecks`, so that the type of the variable `text` resolves
        // to `string`, and not `any`.
        return /** @type {string?} */ (null);
      } else {
        throw error;
      }
    });

    let cachedSnippets = new Map();

    if (text != null) {
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

    for (let cases of Object.values(TEST_CASES)) {
      for (let markdown of Object.keys(cases)) {
        // I want the IDs to be stable and deterministic, as that would help
        // with caching the responses from the REST API (although I'm not doing
        // any such caching currently) -- a weak hash function would be more
        // than enough for this. Also, on my laptop, SHA-1 seems to be faster
        // than MD5, which is why I picked it.
        let id = crypto.hash('sha1', markdown, 'base64url');

        if (markdown.includes(id)) {
          throw new Error(
            `markdown snippet ${JSON.stringify(markdown)} contains its own ID ${JSON.stringify(id)}`,
          );
        }
        if (snippetsById.has(id) && snippetsById.get(id) !== markdown) {
          throw new Error(
            `ID collision between markdown snippets ${JSON.stringify(markdown)} and ${JSON.stringify(snippetsById.get(id))}`,
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
    }

    if (missingSnippets.size > 0) {
      // To save on API requests (unauthenticated users get 60 requests per
      // hour, and I don't want to bother with authentication), I am gonna
      // concatenate all markdown snippets in a big document, separated by
      // markers which GitHub's markdown renderer definitely won't generate (but
      // which will pass the HTML sanitization), render this entire document in
      // one request, and then split the resulting HTML document into the
      // individual snippets. This method does rely on the individual Markdown
      // snippets not having side effects that extend beyond a single paragraph,
      // as otherwise a broken snippet can mess up the rendering of other
      // unrelated ones.
      let dummyDocument = '';
      for (let [id, markdown] of snippetsById) {
        dummyDocument += `<div>snippetStart(${id})</div>\n\n${markdown}\n\n<div>snippetEnd(${id})</div>\n\n`;
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
          mode: 'gfm',
          text: dummyDocument,
        }),
      });

      let res = await fetch(req);
      if (!res.ok) {
        throw new Error(`${req.method} ${req.url} => ${res.status} ${res.statusText}`);
      }

      let contentType = new util.MIMEType(res.headers.get('content-type') || '');
      if (!(contentType.essence === 'text/html' && contentType.params.get('charset') === 'utf-8')) {
        throw new Error(`${req.method} ${req.url} => unrecognized content type: ${contentType}`);
      }

      let body = await res.text();

      renderedSnippets.clear();
      for (let [_, id, html] of body.matchAll(
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

      await fs.mkdir(Path.dirname(DATABASE_PATH), { recursive: true });
      await fs.writeFile(DATABASE_PATH, text, 'utf-8');
    }
  });

  for (let [group, cases] of Object.entries(TEST_CASES)) {
    describe(group, () => {
      test.each(Object.entries(cases))('%j', (markdown, html) => {
        expect(renderedSnippets.get(markdown)).toBe(html);
      });
    });
  }
});
