const Path = require('path');
const MarkdownIt = require('markdown-it');
const markdownItFootnote = require('markdown-it-footnote');
const markdownItFootnoteCustomizations = require('./markdown-it-footnote-customizations');
const markdownItHeaderAnchors = require('./markdown-it-header-anchors');
const markdownTestingUtils = require('./markdown-testing-utils');

const createTestCases = (
  /** @type {{ fromGithubApi: boolean, hardBreaksMode: boolean, render: (markdown: string) => string }} */
  { fromGithubApi, hardBreaksMode, render },
) => {
  const { collect, extractAllMarkdownSnippets } =
    markdownTestingUtils.createMarkdownTestingHarness(render);

  const { concat, concatLines, blockTag, p, h1, softbr, pre, em } =
    markdownTestingUtils.createHtmlBuilders({ fromGithubApi, hardBreaksMode });

  const anchor = !fromGithubApi ? markdownItHeaderAnchors.renderAnchorHtml : () => '';

  const fnrefClass = !fromGithubApi ? ' class="footnote-ref"' : '';
  const footnoteItemClass = !fromGithubApi ? ' class="footnote-item"' : '';
  const backrefArrow = !fromGithubApi ? '\u21a9\ufe0e' : '\u21a9';
  const backrefClass = ' class="data-footnote-backref"';

  const footnotesSection = blockTag.bind(null, 'section data-footnotes="" class="footnotes"');
  const footnotesHeader = '<h2 id="footnote-label" class="sr-only">Footnotes</h2>';
  const footnotesList = blockTag.bind(null, !fromGithubApi ? 'ol class="footnotes-list"' : 'ol');

  const formatId = (
    /** @type {'fn' | 'fnref'} */ kind,
    /** @type {unknown} */ id,
    /** @type {unknown?} */ subId = null,
  ) => {
    let fullId = `${kind}-${id}`;
    if (subId != null) fullId = `${fullId}-${subId}`;
    return fromGithubApi ? `user-content-${fullId}-${'x'.repeat(32)}` : `${fullId}`;
  };

  const splitId = (/** @type {unknown} */ num, /** @type {unknown?} */ id) => {
    let [onlyNum, subId] = String(num).split('-', 2);
    return [onlyNum, subId, id || onlyNum];
  };

  const fnref = (/** @type {unknown} */ num, /** @type {unknown?} */ optionalId) => {
    let [onlyNum, subId, id] = splitId(num, optionalId);
    return (
      `<sup${fnrefClass}><a href="#${formatId('fn', id)}" id="${formatId('fnref', id, subId)}"` +
      ` data-footnote-ref="" aria-describedby="footnote-label">${onlyNum}</a></sup>`
    );
  };

  const footnoteItem = (/** @type {unknown} */ id, /** @type {string[]} */ ...body) =>
    blockTag(`li id="${formatId('fn', id)}"${footnoteItemClass}`, ...body);

  const backref = (/** @type {unknown} */ num, /** @type {unknown?} */ optionalId) => {
    let [_onlyNum, subId, id] = splitId(num, optionalId);
    return (
      `<a href="#${formatId('fnref', id, subId)}" data-footnote-backref=""` +
      ` aria-label="Back to reference ${num}"${backrefClass}>${backrefArrow}` +
      `${subId != null ? `<sup>${subId}</sup>` : ''}</a>`
    );
  };

  const withFootnotes = (
    /** @type {string} */ documentBody,
    /** @type {Record<string, string>} */ footnotes,
  ) => {
    let footnotesBody = Object.entries(footnotes).map(([id, text]) => footnoteItem(id, text));
    return concat(documentBody, footnotesSection(footnotesHeader, footnotesList(...footnotesBody)));
  };

  test(
    'basic case',
    collect((mdtest) => {
      mdtest(
        concatLines(
          // <https://github.blog/changelog/2021-09-30-footnotes-now-supported-in-markdown-fields/>
          'Here is a simple footnote[^1]. With some additional[^2] text after it.',
          '',
          '[^1]: My reference.',
          '[^2]: extra, other, supplementary',
        ),
        withFootnotes(
          p(`Here is a simple footnote${fnref(1)}. With some additional${fnref(2)} text after it.`),
          {
            1: p(`My reference. ${backref(1)}`),
            2: p(`extra, other, supplementary ${backref(2)}`),
          },
        ),
        { isolated: true },
      );
    }),
  );

  test(
    'more complicated case with a multi-line footnote',
    collect((mdtest) => {
      mdtest(
        concatLines(
          // <https://github.com/jgm/pandoc/blob/3.14/MANUAL.txt#L6091-L6107>
          'Here is a footnote reference,[^1] and another.[^longnote]',
          '',
          '[^1]: Here is the footnote.',
          '',
          "[^longnote]: Here's one with multiple blocks.",
          '',
          '    Subsequent paragraphs are indented to show that they',
          'belong to the previous footnote.',
          '',
          '        { some.code }',
          '',
          '    The whole paragraph can be indented, or just the first',
          '    line.  In this way, multi-paragraph footnotes work like',
          '    multi-paragraph list items.',
          '',
          "This paragraph won't be part of the note, because it",
          "isn't indented.",
        ),
        withFootnotes(
          concat(
            p(`Here is a footnote reference,${fnref(1)} and another.${fnref(2, 'longnote')}`),
            p(`This paragraph won't be part of the note, because it${softbr}isn't indented.`),
          ),
          {
            1: p(`Here is the footnote. ${backref(1)}`),
            longnote: concat(
              p("Here's one with multiple blocks."),
              p(
                `Subsequent paragraphs are indented to show that they${softbr}`,
                'belong to the previous footnote.',
              ),
              pre('{ some.code }\n'),
              p(
                `The whole paragraph can be indented, or just the first${softbr}`,
                `line.  In this way, multi-paragraph footnotes work like${softbr}`,
                `multi-paragraph list items. ${backref(2, 'longnote')}`,
              ),
            ),
          },
        ),
        { isolated: true },
      );
    }),
  );

  test(
    'inline footnotes should not work',
    collect((mdtest) => {
      mdtest(
        "this should not work: ^[*inline* footnotes]! That's non-standard^[bad] syntax.",
        p(`this should not work: ^[${em('inline')} footnotes]! That's non-standard^[bad] syntax.`),
        { isolated: true },
      );
    }),
  );

  test(
    'multiple references to the same footnote',
    collect((mdtest) => {
      mdtest(
        concatLines(
          'There are multiple[^1] references[^1] to the same footnote here.',
          '',
          '[^1]: The footnote in question (it[^1] can refer back to itself!)',
          "      Let's also reference another footnote[^2].",
          '[^2]: Hi!',
          '',
          'And in another paragraph[^1] too. Last but not least: bye![^2]',
        ),
        withFootnotes(
          concat(
            p(
              `There are multiple${fnref('1')} references${fnref('1-2')} to the same footnote here.`,
            ),
            p(
              `And in another paragraph${fnref('1-4')} too. Last but not least: bye!${fnref('2-2')}`,
            ),
          ),
          {
            1: p(
              `The footnote in question (it${fnref('1-3')} can refer back to itself!)${softbr}`,
              `Let's also reference another footnote${fnref('2')}.`,
              ` ${backref('1')} ${backref('1-2')} ${backref('1-3')} ${backref('1-4')}`,
            ),
            2: p(`Hi! ${backref('2')} ${backref('2-2')}`),
          },
        ),
        { isolated: true },
      );
    }),
  );

  test(
    'footnote IDs are slugged independently from header IDs',
    collect((mdtest) => {
      mdtest(
        concatLines(
          '# test',
          '',
          'What is this?[^test]',
          '',
          '[^test]: a test',
          '',
          '[^test-1]: duplicate',
          '',
          '# test',
          '',
          'another[^test-1] paragraph[^test]',
        ),
        withFootnotes(
          concat(
            h1(anchor('test', 'test'), 'test'),
            p(`What is this?${fnref('1', 'test')}`),
            h1(anchor('test-1', 'test'), 'test'),
            p(`another${fnref('2', 'test-1')} paragraph${fnref('1-2', 'test')}`),
          ),
          {
            test: p(`a test ${backref('1', 'test')} ${backref('1-2', 'test')}`),
            'test-1': p(`duplicate ${backref('2', 'test-1')}`),
          },
        ),
        { isolated: true },
      );
    }),
  );

  test(
    'multiple footnotes sharing the same label',
    collect((mdtest) => {
      // NOTE: This is an important discrepancy between markdown-it-footnote and
      // Github. It seems that Github decided to follow the same rules for
      // footnote definitions as for link definitions in their parser, for which
      // the CommonMark spec clearly states that in case when there are multiple
      // link definitions with the same label, the one that appears first should
      // be picked: <https://github.github.com/gfm/#:~:text=If%20there%20are%20several%20matching%20definitions%2C%20the%20first%20one%20takes%20precedence>
      //
      // In fact, Github's cmark-gfm library uses the same struct to map labels
      // to definitions both for links and footnotes, which deduplicates both of
      // them in the same way (by keeping only the first unique instance of
      // every label: <https://github.com/github/cmark-gfm/blob/0.29.0.gfm.14/src/map.c#L34-L72>).
      const expectedFootnoteContent = fromGithubApi ? 'first' : 'last';

      mdtest(
        concatLines(
          'Before: [^a]',
          '',
          '[^a]: first',
          '[^a]: second',
          '',
          'in the middle: [^a]',
          '',
          '[^a]: last',
          '',
          'So which is it? [^a]',
        ),
        withFootnotes(
          concat(
            p(`Before: ${fnref('1', 'a')}`),
            p(`in the middle: ${fnref('1-2', 'a')}`),
            p(`So which is it? ${fnref('1-3', 'a')}`),
          ),
          {
            a: p(
              `${expectedFootnoteContent} ${backref('1', 'a')} ${backref('1-2', 'a')} ${backref('1-3', 'a')}`,
            ),
          },
        ),
        { isolated: true },
      );
    }),
  );

  return extractAllMarkdownSnippets;
};

describe('my plugin for markdown-it', () => {
  const hardBreaksMode = true;

  let mdit = new MarkdownIt({ breaks: hardBreaksMode, html: true })
    .use(markdownItFootnote)
    .disable('footnote_inline')
    .use(markdownItFootnoteCustomizations)
    .use(markdownItHeaderAnchors);

  createTestCases({
    fromGithubApi: false,
    hardBreaksMode,
    render: (markdown) => mdit.render(markdown),
  });
});

describe("GitHub's /markdown API", () => {
  /** @type {Map<string, string>} */
  let renderedSnippets = new Map();

  let collectSnippets = createTestCases({
    fromGithubApi: true,
    hardBreaksMode: true,
    render: (markdown) => renderedSnippets.get(markdown),
  });

  beforeAll(async () => {
    await markdownTestingUtils.refreshFetchedSnippetsDatabase(
      renderedSnippets,
      Path.join(__dirname, 'fixtures', 'rendered-by-github', 'footnotes.json'),
      collectSnippets(),
    );
  });
});
