const fs = require('fs/promises');
const Path = require('path');
const crypto = require('crypto');
const util = require('util');
const MarkdownIt = require('markdown-it');
const markdownItTasklist = require('./markdown-it-tasklist');

// NOTE: Can't use a narrower assertion like `x is Record<string, unknown>`
// because then type narrowing with the `in` operator stops working.
// <https://www.reddit.com/r/typescript/comments/tq3m4f/the_difference_between_object_and_recordstring/>
/** @returns {x is object} */
const isObject = (/** @type {unknown} */ x) => {
  // eslint-disable-next-line eqeqeq
  return typeof x === 'object' && x !== null && !Array.isArray(x);
};

const createTestCases = (
  /** @type {{ fromGithubApi: boolean, hardBreaksMode: boolean, render: (markdown: string) => string }} */
  { fromGithubApi, hardBreaksMode, render },
) => {
  const mdtest = (/** @type {string} */ markdown, /** @type {string} */ expectedHtml) => {
    let actualHtml = render(markdown);
    try {
      expect(actualHtml).toBe(expectedHtml);
    } catch (error) {
      if (isObject(error) && 'name' in error && error.name === 'AssertionError') {
        // <https://kentcdodds.com/blog/improve-test-error-messages-of-your-abstractions>
        Error.captureStackTrace(error, mdtest);
      }
      throw error;
    }
  };

  /** @typedef {(mdtest_: typeof mdtest) => void} MarkdownTestFunction */

  /** @type {MarkdownTestFunction[]} */
  let allTestFunctions = [];

  const collect = (/** @type {MarkdownTestFunction} */ testImpl) => {
    allTestFunctions.push(testImpl);
    return testImpl.bind(null, mdtest);
  };

  const extractAllMarkdownSnippets = () => {
    /** @type {Set<string>} */
    let snippets = new Set();
    for (let testImpl of allTestFunctions) {
      testImpl((markdown, _html) => {
        snippets.add(markdown);
      });
    }
    return snippets;
  };

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

  test(
    'basic cases',
    collect((mdtest) => {
      mdtest('- [x] hi!', taskList(item(checked, ' hi!')));
      mdtest('- [X] hi!', taskList(item(checked, ' hi!')));
      mdtest('- [ ] hi!', taskList(item(unchecked, ' hi!')));
    }),
  );

  test(
    'second checkbox marker in the text',
    collect((mdtest) => {
      mdtest('- [x] [x]', taskList(item(checked, ' [x]')));
      mdtest('- [ ] [ ]', taskList(item(unchecked, ' [ ]')));
    }),
  );

  test(
    'no text after marker',
    collect((mdtest) => {
      mdtest('- [ ]', ul(li('[ ]')));
      mdtest('- [ ] ', ul(li('[ ]')));
      mdtest('- [x]    ', ul(li('[x]')));
      mdtest('- [x]\n\na', ul(li('[x]')) + p('a'));
    }),
  );

  test(
    'multiple characters in the marker',
    collect((mdtest) => {
      mdtest('- [xx] 2 Xs', ul(li('[xx] 2 Xs')));
      mdtest('- [  ] 2 spaces', ul(li('[  ] 2 spaces')));
    }),
  );

  test(
    'NUL bytes',
    collect((mdtest) => {
      mdtest('- [\0] single NUL', ul(li('[\uFFFD] single NUL')));
      mdtest('- [x\0] x then NUL', ul(li('[x\uFFFD] x then NUL')));
      mdtest('- [\0x] NUL then x', ul(li('[\uFFFDx] NUL then x')));
      mdtest('- \0[x] NUL before', ul(li('\uFFFD[x] NUL before')));
      mdtest('- [x]\0 NUL after', ul(li('[x]\uFFFD NUL after')));
    }),
  );

  test(
    'does not break links',
    collect((mdtest) => {
      mdtest('- [x](link)', ul(li('<a href="link">x</a>')));
    }),
  );

  // NOTE: this is a quirk of GitHub's parser that I *don't* want to imitate.
  test(
    'escaped square brackets',
    collect((mdtest) => {
      mdtest('- \\[x] text', quirkyOnGithub({ my: '[x]', github: checked, body: ' text' }));
      mdtest('- [ \\] text', quirkyOnGithub({ my: '[ ]', github: unchecked, body: ' text' }));
      mdtest('- \\[ \\] text', quirkyOnGithub({ my: '[ ]', github: unchecked, body: ' text' }));
      mdtest('- [\\x] text', ul(li('[\\x] text')));
      mdtest('- [\\ ] text', ul(li('[\\ ] text')));
    }),
  );

  test(
    'square brackets as HTML entities',
    collect((mdtest) => {
      mdtest('- &lsqb; ] lsqb', quirkyOnGithub({ my: '[ ]', github: unchecked, body: ' lsqb' }));
      mdtest('- [x&rsqb; rsqb', quirkyOnGithub({ my: '[x]', github: checked, body: ' rsqb' }));
      mdtest('- &lsqb;x&rsqb; both', quirkyOnGithub({ my: '[x]', github: checked, body: ' both' }));
      mdtest(
        '- &#91;&#120;&#93; dec',
        quirkyOnGithub({ my: '[x]', github: checked, body: ' dec' }),
      );
      mdtest(
        '- &#x5b;&#x78;&#x5d; hex',
        quirkyOnGithub({ my: '[x]', github: checked, body: ' hex' }),
      );
    }),
  );

  test(
    'list with and without checkboxes',
    collect((mdtest) => {
      mdtest(
        '- first\n- [x] second\n- [ ] third\n- normal\n- [x] checkbox again',
        taskList(
          li('first'),
          item(checked, ' second'),
          item(unchecked, ' third'),
          li('normal'),
          item(checked, ' checkbox again'),
        ),
      );
    }),
  );

  test(
    'long indent before checkbox marker',
    collect((mdtest) => {
      mdtest('-  [x] a', taskList(item(checked, ' a')));
      mdtest('-   [x] a', taskList(item(checked, ' a')));
      mdtest('-    [x] a', taskList(item(checked, ' a')));
      mdtest('-     [x] a', ul(li(pre('[x] a\n'))));
      mdtest('-      [x] a', ul(li(pre(' [x] a\n'))));
      mdtest('-\t[x] a', taskList(item(checked, ' a')));
      mdtest('-\t [x] a', taskList(item(checked, ' a')));
      mdtest('- \t [x] a', taskList(item(checked, ' a')));
      mdtest('-  \t [x] a', taskList(item(checked, ' a')));
      mdtest('-\t  [x] a', ul(li(pre('[x] a\n'))));
      mdtest('- \t  [x] a', ul(li(pre('[x] a\n'))));
      mdtest('-  \t  [x] a', ul(li(pre('[x] a\n'))));
    }),
  );

  test(
    'no space before checkbox marker',
    collect((mdtest) => {
      mdtest('-[x]', p('-[x]'));
      mdtest('-[ ] text', p('-[ ] text'));
      mdtest('-[x] text', p('-[x] text'));
      mdtest('-[ ]', p('-[ ]'));
    }),
  );

  test(
    'linebreak between checkbox and text',
    collect((mdtest) => {
      mdtest('- [x]\n  a', ul(li('[x]<br>\na')));
      mdtest('- [x] \n  a', ul(li('[x]<br>\na')));
      mdtest('- [x]  \n  a', ul(li('[x]<br>\na')));
      mdtest('- [x]\\\n  a', ul(li('[x]<br>\na')));
      mdtest('- [x] \\\n  a', taskList(item(checked, ' <br>\na')));
      mdtest('- [x] \\ a', taskList(item(checked, ' \\ a')));
      mdtest(
        '- \n  [x] newline before checkbox',
        taskList(item(checked, ' newline before checkbox')),
      );
    }),
  );

  test(
    'loose list',
    collect((mdtest) => {
      mdtest(
        '* [x] loose 1\n\n* [ ] loose 2\n* [x] loose 3',
        taskList(
          item('\n', p(checked, ' loose 1')),
          item('\n', p(unchecked, ' loose 2')),
          item('\n', p(checked, ' loose 3')),
        ),
      );
    }),
  );

  test(
    "quirks of Github's parser",
    collect((mdtest) => {
      mdtest('- [ ]<span></span> empty span after', ul(li('[ ]<span></span> empty span after')));
      mdtest('- <span></span>[ ] empty span before', ul(li('<span></span>[ ] empty span before')));

      mdtest(
        '- <button></button>[ ] illegal tag',
        quirkyOnGithub({ my: '<button></button>[ ]', github: unchecked, body: ' illegal tag' }),
      );

      mdtest(
        '- <foo></foo>[ ] unknown tag',
        quirkyOnGithub({ my: '<foo></foo>[ ]', github: unchecked, body: ' unknown tag' }),
      );

      mdtest('- [ ]<!-- --> empty comment after', ul(li(`[ ]${comment(' ')} empty comment after`)));
      mdtest(
        '- [x<!-- -->] empty comment inside',
        ul(li(`[x${comment(' ')}] empty comment inside`)),
      );

      // NOTE: this is an actually interesting quirk: a task list is generated,
      // but checkboxes inside aren't
      mdtest(
        '- <!-- --> [ ] empty comment before\n',
        quirkyOnGithub({ my: '\n<!-- --> [ ]', github: '\n [ ]', body: ' empty comment before\n' }),
      );

      mdtest(
        '1. <!-- --> [ ] empty comment before\n',
        quirkyOnGithub({
          my: '\n<!-- --> [ ]',
          github: '\n [ ]',
          body: ' empty comment before\n',
        }).replace(/ul/g, 'ol'),
      );

      mdtest(
        '- <!-- [x] --> [ ] checkbox in comment\n',
        quirkyOnGithub({
          my: '\n<!-- [x] --> [ ]',
          github: '\n [ ]',
          body: ' checkbox in comment\n',
        }),
      );
    }),
  );

  test(
    'raw HTML',
    collect((mdtest) => {
      mdtest(
        '<ul>\n<li>[x] raw</li>\n</ul>\n',
        quirkyOnGithub({ my: '[x]', github: checked, body: ' raw' }),
      );

      mdtest('<li>[x] just li</li>\n', li(fromGithubApi ? checked : '[x]', ' just li'));
      mdtest('<li>[ ] just li</li>\n', li(fromGithubApi ? unchecked : '[ ]', ' just li'));

      mdtest(
        '<ul>\n<li> [ ] space before</li>\n</ul>\n',
        quirkyOnGithub({ my: ' [ ]', github: unchecked, body: ' space before' }),
      );

      mdtest(
        '<ul>\n<li>&#32;[ ] space before</li>\n</ul>\n',
        quirkyOnGithub({ my: '&#32;[ ]', github: unchecked, body: ' space before' }),
      );

      mdtest(
        '<ul>\n<li><p>[x] loose</p>\n</li>\n<li><p>[ ] loose 2</p>\n</li>\n</ul>\n',
        quirkyOnGithub(
          { my: '<p>[x]', github: `<p>${checked}`, body: ' loose</p>\n' },
          { my: '<p>[ ]', github: `<p>${unchecked}`, body: ' loose 2</p>\n' },
        ),
      );

      mdtest('<li><p>[x] p</p>\n</li>\n', li(p(fromGithubApi ? checked : '[x]', ' p')));
      mdtest('<li><div>[x] div</div></li>\n', li('<div>', '[x]', ' div', '</div>'));
    }),
  );

  return extractAllMarkdownSnippets;
};

describe('my markdown-it plugin', () => {
  const hardBreaksMode = true;

  // NOTE: the `breaks` option does not affect parsing in any way, only the HTML
  // that gets rendered. It needs to be enabled for parity with GitHub's REST
  // API, as the `https://api.github.com/markdown` endpoint renders content in
  // hard breaks mode (the way it is parsed in the comment boxes on the website
  // itself). This option is only ever read here in the code of markdown-it:
  // <https://github.com/markdown-it/markdown-it/blob/15.0.2/src/renderer.ts#L126>
  let mdit = new MarkdownIt({ breaks: hardBreaksMode, html: true }).use(markdownItTasklist);

  createTestCases({
    fromGithubApi: false,
    hardBreaksMode,
    render: (markdown) => mdit.render(markdown),
  });

  test('strips the checkbox marker from the token.content', () => {
    let whitespace = '   ';
    let text = 'token  contents';
    let tokens = mdit.parse(`+ [x]${whitespace}${text}   \n`, {});
    expect(tokens[3].type).toBe('inline');
    expect(tokens[3].content).toBe(`${whitespace}${text}`);
    expect(tokens[3].children[1].type).toBe('text');
    expect(tokens[3].children[1].content).toBe(`${whitespace}${text}`);
  });
});

describe("GitHub's /markdown API", () => {
  const DATABASE_PATH = Path.join(__dirname, 'fixtures', 'rendered-by-github', 'tasklist.json');
  const DATABASE_FORMAT_VERSION = 1;

  /** @type {Map<string, string>} */
  let renderedSnippets = new Map();

  let collectSnippets = createTestCases({
    fromGithubApi: true,
    hardBreaksMode: true,
    render: (markdown) => renderedSnippets.get(markdown),
  });

  beforeAll(async () => {
    renderedSnippets.clear();

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

    for (let markdown of collectSnippets()) {
      // I want the IDs to be stable and deterministic, as that would help with
      // caching the responses from the REST API (although I'm not doing any
      // such caching currently) -- a weak hash function would be more than
      // enough for this. Also, on my laptop, SHA-1 seems to be faster than MD5,
      // which is why I picked it.
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
      /** @returns {never} */
      const unwrapNetworkErrors = (/** @type {unknown} */ error) => {
        // Undici wraps network errors into `TypeError('fetch failed')` with the
        // `e.cause` set to the real error.
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
      };

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

      let res = await fetch(req).catch(unwrapNetworkErrors);
      if (!res.ok) {
        throw new Error(`${req.method} ${req.url} => ${res.status} ${res.statusText}`);
      }

      let contentType = new util.MIMEType(res.headers.get('content-type') || '');
      if (!(contentType.essence === 'text/html' && contentType.params.get('charset') === 'utf-8')) {
        throw new Error(`${req.method} ${req.url} => unrecognized content type: ${contentType}`);
      }

      let body = await res.text().catch(unwrapNetworkErrors);

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
});
