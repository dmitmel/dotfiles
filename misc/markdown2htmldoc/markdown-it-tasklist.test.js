// Some tests were taken from various other Markdown processing libraries:
// <https://github.com/linsir/markdown-it-task-checkbox/tree/6c684bb3f02aa097fe33ca7d9fe05e19857c910d/test/fixtures>
// <https://github.com/markedjs/marked/tree/738ebebc835ebc97fe82e3321bc7f91f638c531f/test/specs/new>
// <https://github.com/kivikakk/comrak/blob/8e2bcb58e04a9e4e44bfb36f75d152904078e9f6/src/tests/tasklist.rs>
// <https://github.com/jgm/commonmark-hs/blob/1f95dd95987647a48898fa2d272be68e564f3b41/commonmark-extensions/test/task_lists.md>
// <https://github.com/micromark/micromark-extension-gfm-task-list-item/blob/7902c38c76a6dea80928a54829313b702615d1e1/test/fixtures/basic.md?plain=1>
// <https://github.com/micromark/micromark-extension-gfm-task-list-item/blob/7902c38c76a6dea80928a54829313b702615d1e1/test/index.js>
// <https://github.com/github/cmark-gfm/blob/27d942c8b0a62d192f616e5bf3578f4b6a89e180/test/extensions.txt#L835-L920>
// <https://github.com/Ranrar/marco-core/blob/cd1708988bb213edb7bf50362abca5fe5d30cf51/tests/gfm_tasklist_it.rs>

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
    expectedHtml = String(expectedHtml).replace(/\n\n+/g, '\n').replace(/^\n/, '');
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

  const concat = (/** @type {string[]} */ ...strings) => strings.join('');
  const concatLines = (/** @type {string[]} */ ...strings) => `${strings.join('\n')}\n`;

  const blockTag = (/** @type {string} */ nameAndAttrs, /** @type {string[]} */ ...body) => {
    let onlyName = nameAndAttrs.split(/\s+/, 1)[0];
    return `\n<${nameAndAttrs}>${body.join('')}</${onlyName}>\n`;
  };

  const ul = blockTag.bind(null, 'ul');
  const ol = blockTag.bind(null, 'ol');
  const li = blockTag.bind(null, 'li');
  const p = blockTag.bind(null, 'p');
  const blockquote = blockTag.bind(null, 'blockquote');
  const h1 = blockTag.bind(null, 'h1');
  const h2 = blockTag.bind(null, 'h2');

  const hardbr = '<br>\n';
  const softbr = hardBreaksMode ? hardbr : '\n';

  const taskList = (/** @type {string} */ tag, /** @type {string[]} */ ...body) =>
    blockTag(`${tag} class="contains-task-list"`, ...body);
  taskList.ul = taskList.bind(null, 'ul');
  taskList.ol = taskList.bind(null, 'ol');

  const item = blockTag.bind(null, 'li class="task-list-item"');

  const taskListItemCheckbox = (/** @type {boolean} */ checked) =>
    `<input type="checkbox"${fromGithubApi ? ' id=""' : ''}` +
    ` disabled="" class="task-list-item-checkbox"` +
    ` aria-label="${checked ? 'Completed task' : 'Incomplete task'}"` +
    `${checked ? ' checked=""' : ''}>`;

  const checked = taskListItemCheckbox(true);
  const unchecked = taskListItemCheckbox(false);

  // <https://stackoverflow.com/questions/9628507/how-can-i-tell-google-translate-to-not-translate-a-section-of-a-website>
  const notranslate = fromGithubApi ? ' class="notranslate"' : '';
  const code = (/** @type {string} */ body) => `<code${notranslate}>${body}</code>`;
  const pre = (/** @type {string} */ body) => blockTag(`pre${notranslate}`, code(body));

  const em = (/** @type {string[]} */ ...body) => `<em>${body.join('')}</em>`;

  const comment = (/** @type {string} */ text) => (fromGithubApi ? '' : `<!--${text}-->`);

  const img = (/** @type {string} */ alt, /** @type {string} */ src) =>
    fromGithubApi
      ? `<a target="_blank" rel="noopener noreferrer" href="${src}"` +
        `><img src="${src}" alt="${alt}" style="max-width: 100%;"></a>`
      : `<img src="${src}" alt="${alt}">`;

  const quirkyOnGithub = (
    /** @type {string} */ tag,
    /** @type {Array<{ my: string, github: string, body: string }>} */ ...items
  ) => {
    let itemsStr = items.map(({ my, github, body }) =>
      fromGithubApi ? item(github, body) : li(my, body),
    );
    return fromGithubApi ? taskList(tag, ...itemsStr) : blockTag(tag, ...itemsStr);
  };
  quirkyOnGithub.ul = quirkyOnGithub.bind(null, 'ul');
  quirkyOnGithub.ol = quirkyOnGithub.bind(null, 'ol');

  test(
    'basic cases',
    collect((mdtest) => {
      mdtest(
        concatLines('- [x] hi!', '- [ ] lol!', '- [X] bye!'),
        taskList.ul(item(checked, ' hi!'), item(unchecked, ' lol!'), item(checked, ' bye!')),
      );
    }),
  );

  test(
    'different list styles',
    collect((mdtest) => {
      mdtest('+ [x] plus', taskList.ul(item(checked, ' plus')));
      mdtest('* [ ] star', taskList.ul(item(unchecked, ' star')));
      mdtest('1. [x] ordered', taskList.ol(item(checked, ' ordered')));
      mdtest('3) [x] offset', taskList('ol start="3"', item(checked, ' offset')));
    }),
  );

  test(
    'checkbox wrapped in another tag',
    collect((mdtest) => {
      mdtest('+ *[ ] emphasized*', ul(li(em('[ ] emphasized'))));
      mdtest('+ *[x]* emphasized', ul(li(em('[x]'), ' emphasized')));
      mdtest('+ <em>[ ] emphasized</em>', ul(li(em('[ ] emphasized'))));
      mdtest('+ <em>[x]</em> emphasized', ul(li(em('[x]'), ' emphasized')));
    }),
  );

  test(
    'second checkbox marker in the text',
    collect((mdtest) => {
      mdtest('- [x] [x]', taskList.ul(item(checked, ' [x]')));
      mdtest('- [ ] [ ]', taskList.ul(item(unchecked, ' [ ]')));
      mdtest('- [x] [ ] [x] three boxes', taskList.ul(item(checked, ' [ ] [x] three boxes')));
    }),
  );

  test(
    'no text after marker',
    collect((mdtest) => {
      mdtest('- [ ]', ul(li('[ ]')));
      mdtest('- [ ] ', ul(li('[ ]')));
      mdtest('- [ ]\t', ul(li('[ ]')));
      mdtest('- [x]    ', ul(li('[x]')));
      mdtest('- [x]\n\na', concat(ul(li('[x]')), p('a')));
      mdtest('- [x]\n\n  a', ul(li(p('[x]'), p('a'))));
    }),
  );

  test(
    'no space after the marker',
    collect((mdtest) => {
      mdtest('+ [x]a', ul(li('[x]a')));
      mdtest('+ [ ]b', ul(li('[ ]b')));
      mdtest('+\t[ ]c', ul(li('[ ]c')));
    }),
  );

  test(
    'invalid checkbox markers',
    collect((mdtest) => {
      mdtest('- [x ] space after', ul(li('[x ] space after')));
      mdtest('- [ x] space before', ul(li('[ x] space before')));
      mdtest('- [ x ] space around', ul(li('[ x ] space around')));
      mdtest('- [xx] 2 Xs', ul(li('[xx] 2 Xs')));
      mdtest('- [  ] 2 spaces', ul(li('[  ] 2 spaces')));
      mdtest('- [] no spaces', ul(li('[] no spaces')));
      mdtest('- [y] why?', ul(li('[y] why?')));
      mdtest("- [\u0445] cyrillic letter 'kha'", ul(li("[\u0445] cyrillic letter 'kha'")));
      mdtest('- [x\u0301] x + diacritic', ul(li('[x\u0301] x + diacritic')));
      // Apparently, Vimwiki uses an `o` to denote semi-complete tasks
      // <https://github.com/preservim/vim-markdown/blob/1bc9d0cd8e1cc3e901b0a49c2b50a843f1c89397/syntax/markdown.vim#L111>
      // <https://github.com/makyo/markdown-vimwiki#todo-lists>
      mdtest('- [o] oh', ul(li('[o] oh')));
      mdtest('- [O] OH', ul(li('[O] OH')));
      // <https://github.com/github/cmark-gfm/blob/27d942c8b0a62d192f616e5bf3578f4b6a89e180/test/extensions.txt#L896>
      mdtest('- [@] at sign', ul(li('[@] at sign')));
      // <https://github.com/mcecot/markdown-it-checkbox/blob/852f5e957292c209e0a390043a72c1b9e75a5e5c/index.js#L16>
      mdtest('- [_] underscore (unchecked)', ul(li('[_] underscore (unchecked)')));
      // <https://orgmode.org/manual/Checkboxes.html#:~:text=partially%20checked%20%E2%80%98%5B-%5D%E2%80%99>
      mdtest('- [-] dash (unchecked)', ul(li('[-] dash (unchecked)')));
      // <https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85982>
      mdtest('- [~] inapplicable (gitlab)', ul(li('[~] inapplicable (gitlab)')));
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
      mdtest('- [x]( )', ul(li('<a href="">x</a>')));
      mdtest('- [x][x]', ul(li('[x][x]')));
      mdtest('- ![x](image)', ul(li(img('x', 'image'))));
    }),
  );

  test(
    'checkbox after a link definition',
    collect((mdtest) => {
      mdtest(
        '- [n]: example.com\n  [x] [link to n][n]',
        taskList.ul(item(checked, ' <a href="example.com">link to n</a>')),
      );
      mdtest(
        '- [n]: example.com\n\n  [x] [link to n][n]',
        fromGithubApi
          ? taskList.ul(item(checked, ' <a href="example.com">link to n</a>'))
          : taskList.ul(item(p(checked, ' <a href="example.com">link to n</a>'))),
      );
      if (!fromGithubApi) {
        mdtest('[x]: example.com/x\n\n+ [x] a', ul(li('<a href="example.com/x">x</a> a')));
        mdtest('- [x]: example.com', ul(li('')));
        mdtest(
          '- [x] [y]\n\n[y]: https://example.com',
          taskList.ul(item(checked, ' <a href="https://example.com">y</a>')),
        );
      }
    }),
  );

  test(
    'stops parsing of block-level content',
    collect((mdtest) => {
      // <https://github.com/markedjs/marked/blob/ba50aa95636ac8f97f46446bbfeb04592ed22216/test/specs/new/tasklist_blocks.md>
      mdtest('+ [x] # heading', taskList.ul(item(checked, ' # heading')));
      mdtest('* [x] - list', taskList.ul(item(checked, ' - list')));
      mdtest('* [x] 2. list', taskList.ul(item(checked, ' 2. list')));
      mdtest('- [x] > blockquote', taskList.ul(item(checked, ' &gt; blockquote')));
      mdtest('1) [x] ---', taskList.ol(item(checked, ' ---')));
      mdtest('1. [ ] [def]: example.com', taskList.ol(item(unchecked, ' [def]: example.com')));

      mdtest(
        '- [ ]       not pre-formatted',
        taskList.ul(item(unchecked, '       not pre-formatted')),
      );

      mdtest(
        '- [x] ```\n  ```',
        taskList.ul(item(checked, ' ```', fromGithubApi ? pre('\n') : pre('').replace(/^\n/g, ''))),
      );

      mdtest(
        concatLines(
          '- [x] ```', //
          '      code',
          '      ```',
        ),
        taskList.ul(item(checked, ' ', code(fromGithubApi ? 'code' : '    code    '))),
      );
    }),
  );

  // NOTE: this is a quirk of GitHub's parser that I *don't* want to imitate.
  test(
    'escaped square brackets',
    collect((mdtest) => {
      mdtest('- \\[x] text', quirkyOnGithub.ul({ my: '[x]', github: checked, body: ' text' }));
      mdtest('- [ \\] text', quirkyOnGithub.ul({ my: '[ ]', github: unchecked, body: ' text' }));
      mdtest('- \\[ \\] text', quirkyOnGithub.ul({ my: '[ ]', github: unchecked, body: ' text' }));
      mdtest('- [\\x] text', ul(li('[\\x] text')));
      mdtest('- [\\ ] text', ul(li('[\\ ] text')));
    }),
  );

  test(
    'square brackets as HTML entities',
    collect((mdtest) => {
      mdtest('- &lsqb; ] lsqb', quirkyOnGithub.ul({ my: '[ ]', github: unchecked, body: ' lsqb' }));
      mdtest('- [x&rsqb; rsqb', quirkyOnGithub.ul({ my: '[x]', github: checked, body: ' rsqb' }));
      mdtest(
        '- &lsqb;x&rsqb; lsqb + rsqb',
        quirkyOnGithub.ul({ my: '[x]', github: checked, body: ' lsqb + rsqb' }),
      );
      mdtest(
        '- &lbrack;x&rbrack; lbrack + rbrack',
        quirkyOnGithub.ul({ my: '[x]', github: checked, body: ' lbrack + rbrack' }),
      );
      mdtest(
        '- &#91;&#120;&#93; dec',
        quirkyOnGithub.ul({ my: '[x]', github: checked, body: ' dec' }),
      );
      mdtest(
        '- &#x5b;&#x78;&#x5d; hex',
        quirkyOnGithub.ul({ my: '[x]', github: checked, body: ' hex' }),
      );
      mdtest(
        '- [&#32;] numeric space',
        quirkyOnGithub.ul({ my: '[ ]', github: unchecked, body: ' numeric space' }),
      );
      mdtest(
        '- [&#120;] numeric x',
        quirkyOnGithub.ul({ my: '[x]', github: checked, body: ' numeric x' }),
      );
    }),
  );

  test(
    'mixed list with and without checkboxes',
    collect((mdtest) => {
      mdtest(
        concatLines(
          '- first entry',
          '- [x] second',
          '- [ ] third',
          '- normal',
          '- [x] checkbox again',
        ),
        taskList.ul(
          li('first entry'),
          item(checked, ' second'),
          item(unchecked, ' third'),
          li('normal'),
          item(checked, ' checkbox again'),
        ),
      );
    }),
  );

  test(
    'different kinds of whitespace',
    collect((mdtest) => {
      mdtest('- [\t] tab', taskList.ul(item(unchecked, ' tab')));
      mdtest('-\t[\t]\ttabs', taskList.ul(item(unchecked, '\ttabs')));
      mdtest('- [\xa0] nbsp', taskList.ul(item(unchecked, ' nbsp')));
      mdtest('- [\xa0]\xa0nbsp', taskList.ul(item(unchecked, '\xa0nbsp')));
      mdtest('- [\xa0]\xa0\tnbsp', taskList.ul(item(unchecked, '\xa0\tnbsp')));
      mdtest('-\xa0[\xa0]\xa0nbsp', p('-\xa0[\xa0]\xa0nbsp'));
      mdtest('- \xa0[\xa0]\xa0nbsp', taskList.ul(item(unchecked, '\xa0nbsp')));
      mdtest('- \xa0[x]\xa0nbsp', taskList.ul(item(checked, '\xa0nbsp')));
      mdtest('-\f[\f]\fform feed', p('-\f[\f]\fform feed'));
      mdtest('- \f[\f]\fform feed', taskList.ul(item(unchecked, '\fform feed')));
      mdtest('- \f[x]\fform feed', taskList.ul(item(checked, '\fform feed')));
      mdtest(
        '-\t \xa0 \u2003 \t  \f[\u00a0] weird whitespace in front',
        taskList.ul(item(unchecked, ' weird whitespace in front')),
      );
      mdtest(
        '-\t \n \t \xa0 \u2003\t  \f[\u00a0] weird whitespace (+ newline) in front',
        taskList.ul(item(unchecked, ' weird whitespace (+ newline) in front')),
      );
    }),
  );

  test(
    'long indent before checkbox marker',
    collect((mdtest) => {
      mdtest('-  [x] a', taskList.ul(item(checked, ' a')));
      mdtest('-   [x] a', taskList.ul(item(checked, ' a')));
      mdtest('-    [x] a', taskList.ul(item(checked, ' a')));
      mdtest('-     [x] a', ul(li(pre('[x] a\n'))));
      mdtest('-      [x] a', ul(li(pre(' [x] a\n'))));
      mdtest('-\t[x] a', taskList.ul(item(checked, ' a')));
      mdtest('-\t [x] a', taskList.ul(item(checked, ' a')));
      mdtest('- \t [x] a', taskList.ul(item(checked, ' a')));
      mdtest('-  \t [x] a', taskList.ul(item(checked, ' a')));
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
    'checkbox marker outside a list',
    collect((mdtest) => {
      mdtest(
        ['[x] first', '[X] second', '[ ] third', '  [x] indented'].join('\n\n'),
        concat(p('[x] first'), p('[X] second'), p('[ ] third'), p('[x] indented')),
      );
      mdtest(
        'An inline [x] checkbox marker in a [ ] normal paragraph',
        p('An inline [x] checkbox marker in a [ ] normal paragraph'),
      );
      mdtest(
        '> [x] in a blockquote\n\n> [ ] in a blockquote',
        concat(blockquote(p('[x] in a blockquote')), blockquote(p('[ ] in a blockquote'))),
      );
    }),
  );

  test(
    'linebreak between checkbox and text',
    collect((mdtest) => {
      mdtest('- [x]\n  a', ul(li('[x]', softbr, 'a')));
      mdtest('- [x] \n  a', ul(li('[x]', softbr, 'a')));
      mdtest('- [x]  \n  a', ul(li('[x]', hardbr, 'a')));
      mdtest('- [x]\\\n  a', ul(li('[x]', hardbr, 'a')));
      mdtest('- [x] \\\n  a', taskList.ul(item(checked, ' ', hardbr, 'a')));
      mdtest('- [x] \\ a', taskList.ul(item(checked, ' \\ a')));
    }),
  );

  test(
    'linebreak before the checkbox',
    collect((mdtest) => {
      mdtest('-\n  [ ] no space', taskList.ul(item(unchecked, ' no space')));
      mdtest('- \n  [x] space and indent', taskList.ul(item(checked, ' space and indent')));
      mdtest('-  \n  [x] space and indent', taskList.ul(item(checked, ' space and indent')));
      mdtest('- \\\n  [x] space and indent', ul(li(hardbr, '[x] space and indent')));
      mdtest('+\n[x] no indent', concat(ul(li()), p('[x] no indent')));
      mdtest('* first line\n  [x] second line', ul(li('first line', softbr, '[x] second line')));
      mdtest('+ first line\n  [ ] second line', ul(li('first line', softbr, '[ ] second line')));
      mdtest(
        "- [x] ok, good\n  [ ] what's this?",
        taskList.ul(item(checked, ' ok, good', softbr, "[ ] what's this?")),
      );
      mdtest(
        '- The marker sits\n\n  [x] in another paragraph',
        ul(li(p('The marker sits'), p('[x] in another paragraph'))),
      );
      mdtest(
        '- hardbreak\\\n  [ ] before the checkbox',
        ul(li('hardbreak', hardbr, '[ ] before the checkbox')),
      );
      mdtest(
        '- hardbreak  \n  [ ] before the checkbox',
        ul(li('hardbreak', hardbr, '[ ] before the checkbox')),
      );
    }),
  );

  test(
    'linebreak inside the checkbox',
    collect((mdtest) => {
      mdtest('* [\n  ] linebreak in the checkbox', ul(li(`[${softbr}] linebreak in the checkbox`)));
      mdtest('* [\n] linebreak in the checkbox', ul(li(`[${softbr}] linebreak in the checkbox`)));
      mdtest('* [\n\n] two linebreaks', concat(ul(li('[')), p('] two linebreaks')));
    }),
  );

  test(
    'loose list',
    collect((mdtest) => {
      mdtest(
        concatLines(
          '* [x] loose 1',
          '',
          '* [ ] multiple',
          '',
          '  paragraphs',
          '',
          '* [ ] loose 2',
          '* [x] loose 3',
        ),
        taskList.ul(
          item(p(checked, ' loose 1')),
          item(p(unchecked, ' multiple'), p('paragraphs')),
          item(p(unchecked, ' loose 2')),
          item(p(checked, ' loose 3')),
        ),
      );
    }),
  );

  test(
    'nested lists',
    collect((mdtest) => {
      mdtest('+ 1) * [x] 2. k', ul(li(ol(li(taskList.ul(item(checked, ' 2. k')))))));
      mdtest('- - [x] nested', ul(li(taskList.ul(item(checked, ' nested')))));
      mdtest('* 1. [x] nested', ul(li(taskList.ol(item(checked, ' nested')))));

      mdtest(
        concatLines(
          '- foo',
          '  1. [x] nested checked',
          '  2. normal item',
          '  3. another normal item',
          '  4. [ ] nested unchecked',
          '- bar',
          '- baz',
        ),
        ul(
          li(
            'foo',
            taskList.ol(
              item(checked, ' nested checked'),
              li('normal item'),
              li('another normal item'),
              item(unchecked, ' nested unchecked'),
            ),
          ),
          li('bar'),
          li('baz'),
        ),
      );

      mdtest(
        concatLines(
          '* [x] outer 1',
          '  - [ ] inner 1',
          '  - [x] inner 2',
          '    + [x] deep 1',
          '  - [x] inner 3',
          '* [ ] outer 2',
        ),
        taskList.ul(
          item(
            checked,
            ' outer 1',
            taskList.ul(
              item(unchecked, ' inner 1'),
              item(checked, ' inner 2', taskList.ul(item(checked, ' deep 1'))),
              item(checked, ' inner 3'),
            ),
          ),
          item(unchecked, ' outer 2'),
        ),
      );

      mdtest(
        concatLines(
          '1. unrelated list',
          '',
          '- very',
          '  1) deeply',
          '     * nested',
          '       + [ ] list',
          '  2) another sublist:',
          '     + item 1',
          '     + item 2',
          '- [x] will walk back to the top to set the class',
        ),
        concat(
          ol(li('unrelated list')),
          taskList.ul(
            li(
              'very',
              ol(
                li('deeply', ul(li('nested', taskList.ul(item(unchecked, ' list'))))),
                li('another sublist:', ul(li('item 1'), li('item 2'))),
              ),
            ),
            item(checked, ' will walk back to the top to set the class'),
          ),
        ),
      );
    }),
  );

  test(
    'interactions with blockquotes',
    collect((mdtest) => {
      mdtest('> + [x] a', blockquote(taskList.ul(item(checked, ' a'))));
      mdtest('+ > [x] b', ul(li(blockquote(p('[x] b')))));
      mdtest('+ [x] > c', taskList.ul(item(checked, ' &gt; c')));

      mdtest(
        concatLines(
          // An exceptionally cursed test, courtesy of <https://github.com/kivikakk/comrak/blob/56af9279c8aef466f915f37ee7a37eb78e4bce2a/src/tests/tasklist.rs#L535-L542>
          'Before',
          '',
          '> - [x] cursed',
          '>',
          '>   1. * > 3. [ ] true',
          '',
          '+ [x] after',
        ),
        concat(
          p('Before'),
          blockquote(
            taskList.ul(
              item(
                p(checked, ' cursed'),
                ol(li(ul(li(blockquote(taskList('ol start="3"', item(unchecked, ' true'))))))),
              ),
            ),
          ),
          taskList.ul(item(checked, ' after')),
        ),
      );
    }),
  );

  test(
    'interactions with setext-style headings',
    collect((mdtest) => {
      // <https://github.com/markedjs/marked/blob/738ebebc835ebc97fe82e3321bc7f91f638c531f/test/specs/new/tasklist_setext_heading.md>
      mdtest(
        concatLines(
          '+ [ ] unchecked',
          '  =============',
          '',
          '- [x] checked',
          '  ===========',
          '',
          '- [ ] unchecked',
          '  -------------',
        ),
        concat(
          ul(li(h1('[ ] unchecked'))), //
          ul(li(h1('[x] checked')), li(h2('[ ] unchecked'))),
        ),
      );

      mdtest(
        concatLines(
          '- [x] checked', //
          '=============',
          '',
          '- [ ] unchecked',
          '---------------',
        ),
        concat(
          taskList.ul(
            item(p(checked, ' checked', softbr, '=============')),
            item(p(unchecked, ' unchecked')),
          ),
          '<hr>\n',
        ),
      );
    }),
  );

  test(
    "quirks of Github's parser",
    collect((mdtest) => {
      mdtest('- [ ]<span></span> empty span after', ul(li('[ ]<span></span> empty span after')));
      mdtest('- <span></span>[ ] empty span before', ul(li('<span></span>[ ] empty span before')));
      mdtest('- [<span></span>x] empty span inside', ul(li('[<span></span>x] empty span inside')));
      mdtest('- [x<span></span>] empty span inside', ul(li('[x<span></span>] empty span inside')));

      mdtest(
        '- <button></button>[ ] illegal tag',
        quirkyOnGithub.ul({ my: '<button></button>[ ]', github: unchecked, body: ' illegal tag' }),
      );

      mdtest(
        '- [<button>x</button>] illegal tag',
        ul(li(fromGithubApi ? '[x]' : '[<button>x</button>]', ' illegal tag')),
      );

      mdtest(
        '- <script></script>[x] dangerous tag',
        ul(
          li(
            '\n',
            fromGithubApi ? '&lt;script&gt;&lt;/script&gt;' : '<script></script>',
            '[x] dangerous tag',
            fromGithubApi ? '\n' : '',
          ),
        ),
      );

      mdtest(
        '- <foo></foo>[ ] unknown tag',
        quirkyOnGithub.ul({ my: '<foo></foo>[ ]', github: unchecked, body: ' unknown tag' }),
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
        quirkyOnGithub.ul({
          my: '\n<!-- --> [ ]',
          github: '\n [ ]',
          body: ' empty comment before\n',
        }),
      );

      mdtest(
        '1. <!-- --> [ ] empty comment before\n',
        quirkyOnGithub.ol({
          my: '\n<!-- --> [ ]',
          github: '\n [ ]',
          body: ' empty comment before\n',
        }),
      );

      mdtest(
        '- <!-- [x] --> [ ] checkbox in comment\n',
        quirkyOnGithub.ul({
          my: '\n<!-- [x] --> [ ]',
          github: '\n [ ]',
          body: ' checkbox in comment\n',
        }),
      );

      mdtest(
        '- [x]\n  - a nested list!',
        quirkyOnGithub.ul({ my: '[x]', github: checked, body: ul(li('a nested list!')) }),
      );
      mdtest(
        '1. [ ]\n   - a nested list!',
        quirkyOnGithub.ol({ my: '[ ]', github: unchecked, body: ul(li('a nested list!')) }),
      );

      mdtest(
        concatLines(
          '- [x]', //
          '  ```',
          '  code',
          '  ```',
        ),
        quirkyOnGithub.ul({
          my: '[x]',
          github: checked,
          body: fromGithubApi ? pre('code\n') : pre('code\n').replace(/^\n/g, ''),
        }),
      );
    }),
  );

  test(
    'how GitHub processes raw HTML',
    collect((mdtest) => {
      mdtest(
        '<ul>\n<li>[x] raw</li>\n</ul>\n',
        quirkyOnGithub.ul({ my: '[x]', github: checked, body: ' raw' }),
      );
      mdtest(
        '<ol>\n<li>[X] raw</li>\n</ol>\n',
        quirkyOnGithub.ol({ my: '[X]', github: checked, body: ' raw' }),
      );

      mdtest(
        '<ol>\n<li>[ ] space</li>\n</ol>\n',
        quirkyOnGithub.ol({ my: '[ ]', github: unchecked, body: ' space' }),
      );
      mdtest(
        '<ul>\n<li>[\xa0] nbsp</li>\n</ul>\n',
        quirkyOnGithub.ul({ my: '[\xa0]', github: unchecked, body: ' nbsp' }),
      );

      mdtest(
        '<ul>\n<li>[x] </li>\n</ul>\n',
        quirkyOnGithub.ul({ my: '[x]', github: checked, body: ' ' }),
      );

      mdtest('<ul>\n<li>[x]</li>\n</ul>\n', ul(li('[x]')));

      mdtest('<li>[x] just li</li>\n', li(fromGithubApi ? checked : '[x]', ' just li'));
      mdtest('<li>[ ] just li</li>\n', li(fromGithubApi ? unchecked : '[ ]', ' just li'));

      mdtest(
        '<ul>\n<li> [ ] space before</li>\n</ul>\n',
        quirkyOnGithub.ul({ my: ' [ ]', github: unchecked, body: ' space before' }),
      );

      mdtest(
        '<ul>\n<li>&#32;[ ] space before</li>\n</ul>\n',
        quirkyOnGithub.ul({ my: '&#32;[ ]', github: unchecked, body: ' space before' }),
      );

      mdtest(
        '<ul>\n<li><p>[x] loose</p>\n</li>\n<li><p>[ ] loose 2</p>\n</li>\n</ul>\n',
        quirkyOnGithub.ul(
          { my: '<p>[x]', github: `<p>${checked}`, body: ' loose</p>\n' },
          { my: '<p>[ ]', github: `<p>${unchecked}`, body: ' loose 2</p>\n' },
        ),
      );

      mdtest('<li>\n<p>[x] p</p>\n</li>\n', li(p(fromGithubApi ? checked : '[x]', ' p')));
      mdtest('<li><b>[x] b</b></li>\n', li('<b>[x] b</b>'));
      mdtest('<li><span>[x] span</span></li>\n', li('<span>[x] span</span>'));
      mdtest('<li><div>[x] div</div></li>\n', li('<div>[x] div</div>'));

      mdtest('* [x]<br> br after checkbox', ul(li('[x]<br> br after checkbox')));
      mdtest('* [x] <br> br after checkbox', taskList.ul(item(checked, ' <br> br after checkbox')));
      mdtest('* <br>[x] br before checkbox', ul(li('<br>[x] br before checkbox')));

      mdtest(
        '- <input type="checkbox"> raw input',
        ul(li(fromGithubApi ? '' : '<input type="checkbox">', ' raw input')),
      );

      mdtest(
        '- <input type="checkbox" checked disabled> raw input',
        ul(li(fromGithubApi ? '' : '<input type="checkbox" checked disabled>', ' raw input')),
      );
    }),
  );

  // for (let i = 0; i < 0xffff; i++)
  //   if (/^\s$/.test(String.fromCodePoint(i)))
  //     console.log(`U+${i.toString(16).toUpperCase().padStart(4, '0')}`);

  const char = (
    /** @type {string} */ str,
    /** @type {string} */ description,
    /** @type {string?} */ entity = null,
    /** @type {string?} */ replacement = null,
  ) => ({
    str,
    description: `U+${str.codePointAt(0).toString(16).toUpperCase().padStart(4, '0')} ${description}`,
    entity: entity || `&#${str.codePointAt(0)};`,
    replacement: replacement || str,
  });

  // <https://en.wikipedia.org/wiki/Whitespace_character#Unicode>
  // <https://www.compart.com/en/unicode/category/Zs>
  let whitespaceCharacters = [
    char('\t', 'tab', '&Tab;'),
    char('\f', 'form feed'),
    char('\u00a0', 'no-break space', '&nbsp;'),
    char('\u1680', 'ogham space mark'),
    char('\u2000', 'en quad'),
    char('\u2001', 'em quad'),
    char('\u2002', 'en space', '&ensp;'),
    char('\u2003', 'em space', '&emsp;'),
    char('\u2004', 'three-per-em space', '&emsp13;'),
    char('\u2005', 'four-per-em space', '&emsp14;'),
    char('\u2006', 'six-per-em space'),
    char('\u2007', 'figure space', '&numsp;'),
    char('\u2008', 'punctuation space', '&puncsp;'),
    char('\u2009', 'thin space', '&thinsp;'),
    char('\u200A', 'hair space', '&hairsp;'),
    char('\u2028', 'line separator'),
    char('\u2029', 'paragraph separator'),
    char('\u202F', 'narrow no-break space'),
    char('\u205F', 'medium mathematical space', '&MediumSpace;'),
    char('\u3000', 'ideographic space'),
  ];

  let notWhitespace = [
    char('\0', 'NUL byte', null, '\ufffd'),
    char('\n', 'line feed', '&NewLine;', softbr),
    char('\r', 'carriage return', null, softbr),
    char('\r\n', 'CR + LF', null, softbr),
    char('\u0085', 'next line', null, fromGithubApi ? '\ufffd' : null),
    char('\u180e', 'mongolian vowel separator'),
    char('\u200b', 'zero width space', '&ZeroWidthSpace;'),
    char('\u200c', 'zero width non-joiner', '&zwnj;'),
    char('\u200d', 'zero width joiner', '&zwj;'),
    char('\u2060', 'word joiner', '&NoBreak;'),
    char('\ufffd', 'replacement character'),
  ];

  (fromGithubApi ? notWhitespace : whitespaceCharacters).push(
    char('\v', 'vertical tab', null, fromGithubApi ? '\ufffd' : '\ufffd'),
    char('\ufeff', 'zero width non-breaking space'),
  );

  test(
    'what counts as whitespace inside the checkbox?',
    collect((mdtest) => {
      mdtest(
        whitespaceCharacters.map((c) => `* [${c.str}] ${c.description}\n`).join(''),
        taskList.ul(...whitespaceCharacters.map((c) => item(unchecked, ` ${c.description}`))),
      );

      mdtest(
        notWhitespace.map((c) => `* [${c.str}] ${c.description}\n`).join(''),
        ul(...notWhitespace.map((c) => li(`[${c.replacement}] ${c.description}`))),
      );

      mdtest(
        whitespaceCharacters.map((c) => `* [${c.entity}] ${c.description}\n`).join(''),
        quirkyOnGithub.ul(
          ...whitespaceCharacters.map(
            (c) => ({ my: `[${c.replacement}]`, github: unchecked, body: ` ${c.description}` }), //
          ),
        ),
      );
    }),
  );

  test(
    'what counts as whitespace after the checkbox?',
    collect((mdtest) => {
      mdtest(
        whitespaceCharacters.map((c) => `* [x]${c.str}${c.description}\n`).join(''),
        taskList.ul(...whitespaceCharacters.map((c) => item(checked, `${c.str}${c.description}`))),
      );

      mdtest(
        notWhitespace.map((c) => `* [x]${c.str}${c.description}\n`).join(''),
        ul(...notWhitespace.map((c) => li(`[x]${c.replacement}${c.description}`))),
      );

      mdtest(
        whitespaceCharacters.map((c) => `* [x]${c.entity}${c.description}\n`).join(''),
        quirkyOnGithub.ul(
          ...whitespaceCharacters.map(
            (c) => ({ my: `[x]`, github: checked, body: `${c.replacement}${c.description}` }), //
          ),
        ),
      );
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

      // Ensure that the saved JSON contains only ASCII characters.
      // <https://stackoverflow.com/a/31652607/12005228>
      text = text.replace(/[^\t\n\r\x20-\x7E]/g, (c) => {
        return `\\u${c.charCodeAt(0).toString(16).padStart(4, '0')}`;
      });

      await fs.mkdir(Path.dirname(DATABASE_PATH), { recursive: true });
      await fs.writeFile(DATABASE_PATH, text, 'utf-8');
    }
  });
});
