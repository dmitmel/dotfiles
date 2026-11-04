const fs = require('fs/promises');
const Path = require('path');
const crypto = require('crypto');
const util = require('util');
const MarkdownIt = require('markdown-it');
const markdownItTasklist = require('./markdown-it-tasklist');

/** @returns {{ [group: string]: { [markdown: string]: string } }} */
function makeTestCases(fromGithubApi = false) {
  const ul = (/** @type {string[]} */ ...body) => `<ul>\n${body.join('')}</ul>\n`;
  const ol = (/** @type {string[]} */ ...body) => `<ol>\n${body.join('')}</ol>\n`;
  const li = (/** @type {string[]} */ ...body) => `<li>${body.join('')}</li>\n`;
  const p = (/** @type {string[]} */ ...body) => `<p>${body.join('')}</p>\n`;

  const taskList = (/** @type {string[]} */ ...body) =>
    `<ul class="contains-task-list">\n${body.join('')}</ul>\n`;

  const item = (/** @type {string[]} */ ...body) =>
    `<li class="task-list-item">${body.join('')}</li>\n`;

  const taskListItemCheckbox = (/** @type {boolean} */ checked) =>
    `<input type="checkbox"${fromGithubApi ? ' id=""' : ''}` +
    ` disabled="" class="task-list-item-checkbox"` +
    ` aria-label="${checked ? 'Completed task' : 'Incomplete task'}"` +
    `${checked ? ' checked=""' : ''}>`;

  const checked = taskListItemCheckbox(true);
  const unchecked = taskListItemCheckbox(false);

  const pre = (/** @type {string} */ body) => {
    let notranslate = fromGithubApi ? ' class="notranslate"' : '';
    return `\n<pre${notranslate}><code${notranslate}>${body}</code></pre>\n`;
  };

  const comment = (/** @type {string} */ text) => (fromGithubApi ? '' : `<!--${text}-->`);

  const quirkyOnGithub = (
    /** @type {Array<{ my: string, github: string, body: string }>} */ ...items
  ) => {
    let itemsStr = items.map(({ my, github, body }) =>
      fromGithubApi ? item(github, body) : li(my, body),
    );
    return fromGithubApi ? taskList(...itemsStr) : ul(...itemsStr);
  };

  return {
    'basic cases': {
      '- [x] hi!': taskList(item(checked, ' hi!')),
      '- [X] hi!': taskList(item(checked, ' hi!')),
      '- [ ] hi!': taskList(item(unchecked, ' hi!')),
    },

    'second checkbox marker in the text': {
      '- [x] [x]': taskList(item(checked, ' [x]')),
      '- [ ] [ ]': taskList(item(unchecked, ' [ ]')),
    },

    'no text after marker': {
      '- [ ]': ul(li('[ ]')),
      '- [ ] ': ul(li('[ ]')),
      '- [x]    ': ul(li('[x]')),
      '- [x]\n\na': ul(li('[x]')) + p('a'),
    },

    'multiple characters in the marker': {
      '- [xx] 2 Xs': ul(li('[xx] 2 Xs')),
      '- [  ] 2 spaces': ul(li('[  ] 2 spaces')),
    },

    'NUL bytes': {
      '- [\0] single NUL': ul(li('[\uFFFD] single NUL')),
      '- [x\0] x then NUL': ul(li('[x\uFFFD] x then NUL')),
      '- [\0x] NUL then x': ul(li('[\uFFFDx] NUL then x')),
      '- \0[x] NUL before': ul(li('\uFFFD[x] NUL before')),
      '- [x]\0 NUL after': ul(li('[x]\uFFFD NUL after')),
    },

    'does not break links': {
      '- [x](link)': ul(li('<a href="link">x</a>')),
    },

    // NOTE: this is a quirk of GitHub's parser that I *don't* want to imitate.
    'escaped square brackets': {
      '- \\[x] text': quirkyOnGithub({ my: '[x]', github: checked, body: ' text' }),
      '- [ \\] text': quirkyOnGithub({ my: '[ ]', github: unchecked, body: ' text' }),
      '- \\[ \\] text': quirkyOnGithub({ my: '[ ]', github: unchecked, body: ' text' }),
      '- [\\x] text': ul(li('[\\x] text')),
      '- [\\ ] text': ul(li('[\\ ] text')),
    },

    'square brackets as HTML entities': {
      '- &lsqb; ] lsqb': quirkyOnGithub({ my: '[ ]', github: unchecked, body: ' lsqb' }),
      '- [x&rsqb; rsqb': quirkyOnGithub({ my: '[x]', github: checked, body: ' rsqb' }),
      '- &lsqb;x&rsqb; both': quirkyOnGithub({ my: '[x]', github: checked, body: ' both' }),
      '- &#91;&#120;&#93; dec': quirkyOnGithub({ my: '[x]', github: checked, body: ' dec' }),
      '- &#x5b;&#x78;&#x5d; hex': quirkyOnGithub({ my: '[x]', github: checked, body: ' hex' }),
    },

    'list with and without checkboxes': {
      '- first\n- [x] second\n- [ ] third\n- normal\n- [x] checkbox again': taskList(
        li('first'),
        item(checked, ' second'),
        item(unchecked, ' third'),
        li('normal'),
        item(checked, ' checkbox again'),
      ),
    },

    'long indent before checkbox marker': {
      '-  [x] a': taskList(item(checked, ' a')),
      '-   [x] a': taskList(item(checked, ' a')),
      '-    [x] a': taskList(item(checked, ' a')),
      '-     [x] a': ul(li(pre('[x] a\n'))),
      '-      [x] a': ul(li(pre(' [x] a\n'))),
      '-\t[x] a': taskList(item(checked, ' a')),
      '-\t [x] a': taskList(item(checked, ' a')),
      '- \t [x] a': taskList(item(checked, ' a')),
      '-  \t [x] a': taskList(item(checked, ' a')),
      '-\t  [x] a': ul(li(pre('[x] a\n'))),
      '- \t  [x] a': ul(li(pre('[x] a\n'))),
      '-  \t  [x] a': ul(li(pre('[x] a\n'))),
    },

    'no space before checkbox marker': {
      '-[x]': p('-[x]'),
      '-[ ] text': p('-[ ] text'),
      '-[x] text': p('-[x] text'),
      '-[ ]': p('-[ ]'),
    },

    'linebreak between checkbox and text': {
      '- [x]\n  a': ul(li('[x]<br>\na')),
      '- [x] \n  a': ul(li('[x]<br>\na')),
      '- [x]  \n  a': ul(li('[x]<br>\na')),
      '- [x]\\\n  a': ul(li('[x]<br>\na')),
      '- [x] \\\n  a': taskList(item(checked, ' <br>\na')),
      '- [x] \\ a': taskList(item(checked, ' \\ a')),
      '- \n  [x] newline before checkbox': taskList(item(checked, ' newline before checkbox')),
    },

    'loose list': {
      '* [x] loose 1\n\n* [ ] loose 2\n* [x] loose 3': taskList(
        item('\n', p(checked, ' loose 1')),
        item('\n', p(unchecked, ' loose 2')),
        item('\n', p(checked, ' loose 3')),
      ),
    },

    "quirks of Github's parser": {
      '- [ ]<span></span> empty span after': ul(li('[ ]<span></span> empty span after')),
      '- <span></span>[ ] empty span before': ul(li('<span></span>[ ] empty span before')),

      '- <button></button>[ ] illegal tag': quirkyOnGithub({
        my: '<button></button>[ ]',
        github: unchecked,
        body: ' illegal tag',
      }),

      '- <foo></foo>[ ] unknown tag': quirkyOnGithub({
        my: '<foo></foo>[ ]',
        github: unchecked,
        body: ' unknown tag',
      }),

      '- [ ]<!-- --> empty comment after': ul(li(`[ ]${comment(' ')} empty comment after`)),
      '- [x<!-- -->] empty comment inside': ul(li(`[x${comment(' ')}] empty comment inside`)),

      // NOTE: this is an actually interesting quirk: a task list is generated,
      // but checkboxes inside aren't
      '- <!-- --> [ ] empty comment before\n': quirkyOnGithub({
        my: '\n<!-- --> [ ]',
        github: '\n [ ]',
        body: ' empty comment before\n',
      }),

      '1. <!-- --> [ ] empty comment before\n': quirkyOnGithub({
        my: '\n<!-- --> [ ]',
        github: '\n [ ]',
        body: ' empty comment before\n',
      }).replace(/ul/g, 'ol'),

      '- <!-- [x] --> [ ] checkbox in comment\n': quirkyOnGithub({
        my: '\n<!-- [x] --> [ ]',
        github: '\n [ ]',
        body: ' checkbox in comment\n',
      }),
    },

    'raw HTML': {
      '<ul>\n<li>[x] raw</li>\n</ul>\n': quirkyOnGithub({
        my: '[x]',
        github: checked,
        body: ' raw',
      }),

      '<li>[x] just li</li>\n': li(fromGithubApi ? checked : '[x]', ' just li'),
      '<li>[ ] just li</li>\n': li(fromGithubApi ? unchecked : '[ ]', ' just li'),

      '<ul>\n<li> [ ] space before</li>\n</ul>\n': quirkyOnGithub({
        my: ' [ ]',
        github: unchecked,
        body: ' space before',
      }),

      '<ul>\n<li>&#32;[ ] space before</li>\n</ul>\n': quirkyOnGithub({
        my: '&#32;[ ]',
        github: unchecked,
        body: ' space before',
      }),

      '<ul>\n<li><p>[x] loose</p>\n</li>\n<li><p>[ ] loose 2</p>\n</li>\n</ul>\n': quirkyOnGithub(
        { my: '<p>[x]', github: `<p>${checked}`, body: ' loose</p>\n' },
        { my: '<p>[ ]', github: `<p>${unchecked}`, body: ' loose 2</p>\n' },
      ),

      '<li><p>[x] p</p>\n</li>\n': li(p(fromGithubApi ? checked : '[x]', ' p')),
      '<li><div>[x] div</div></li>\n': li('<div>', '[x]', ' div', '</div>'),
    },
  };
}

describe('my markdown-it plugin', () => {
  for (let [group, cases] of Object.entries(makeTestCases(false))) {
    describe(group, () => {
      test.each(Object.entries(cases))('%j', (markdown, html) => {
        // NOTE: the `breaks` option does not affect parsing in any way, only
        // the HTML that gets rendered. It needs to be enabled for parity with
        // GitHub's REST API, as the `https://api.github.com/markdown` endpoint
        // renders content in hard breaks mode (like in the comment boxes on the
        // website itself). This option is only ever read here in the code of
        // markdown-it: <https://github.com/markdown-it/markdown-it/blob/15.0.2/src/renderer.ts#L126>
        let md = new MarkdownIt({ breaks: true, html: true }).use(markdownItTasklist);
        expect(md.render(markdown)).toBe(html);
      });
    });
  }

  test('strips the checkbox marker from the token.content', () => {
    let md = new MarkdownIt().use(markdownItTasklist);
    let whitespace = '   ';
    let text = 'token  contents';
    let tokens = md.parse(`+ [x]${whitespace}${text}   \n`, {});
    expect(tokens[3].type).toBe('inline');
    expect(tokens[3].content).toBe(`${whitespace}${text}`);
    expect(tokens[3].children[1].type).toBe('text');
    expect(tokens[3].children[1].content).toBe(`${whitespace}${text}`);
  });
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
