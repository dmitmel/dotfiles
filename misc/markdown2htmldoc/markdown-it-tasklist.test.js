const MarkdownIt = require('markdown-it');
const markdownItTasklist = require('./markdown-it-tasklist');

const render = (/** @type {string} */ markdown) =>
  new MarkdownIt().use(markdownItTasklist).render(markdown);

const ul = (/** @type {string[]} */ ...body) => `<ul>\n${body.join('\n')}\n</ul>\n`;
const li = (/** @type {string} */ body) => `<li>${body}</li>`;

const taskList = (/** @type {string[]} */ ...body) =>
  `<ul class="contains-task-list">\n${body.join('\n')}\n</ul>\n`;

const taskListItem = (/** @type {boolean} */ checked) => (/** @type {string} */ body) =>
  `<li class="task-list-item"><input type="checkbox" disabled="" class="task-list-item-checkbox"` +
  ` aria-label="${checked ? 'Completed task' : 'Incomplete task'}"${checked ? ' checked=""' : ''}` +
  `>${body}</li>`;

const checked = taskListItem(true);
const unchecked = taskListItem(false);

test('basic case', () => {
  expect(render('- [x] hi!')).toBe(taskList(checked(' hi!')));
  expect(render('- [ ] hi!')).toBe(taskList(unchecked(' hi!')));
});

test('no text after marker', () => {
  expect(render('- [ ]')).toBe(ul(li('[ ]')));
  expect(render('- [ ] ')).toBe(ul(li('[ ]')));
  expect(render('- [x]    ')).toBe(ul(li('[x]')));
});

test('does not break links', () => {
  expect(render('- [x](link)')).toBe(ul(li('<a href="link">x</a>')));
});

test('escaped square brackets', () => {
  expect(render('- \\[x] text')).toBe(ul(li('[x] text')));
  expect(render('- [ \\] text')).toBe(ul(li('[ ] text')));
  expect(render('- \\[ \\] text')).toBe(ul(li('[ ] text')));
});

test('square brackets as HTML entities', () => {
  expect(render('- &lsqb; ] lsqb')).toBe(ul(li('[ ] lsqb')));
  expect(render('- [x&rsqb; rsqb')).toBe(ul(li('[x] rsqb')));
  expect(render('- &lsqb;x&rsqb; lsqb + rsqb')).toBe(ul(li('[x] lsqb + rsqb')));
});

test('list with and without checkboxes', () => {
  expect(render('- first\n- [x] second\n- [ ] third\n- normal\n- [x] checkbox again')).toBe(
    taskList(
      li('first'),
      checked(' second'),
      unchecked(' third'),
      li('normal'),
      checked(' checkbox again'),
    ),
  );
});

test('long indent before checkbox marker', () => {
  let taskListHTML = taskList(checked(' a'));
  let preCodeHTML = ul(li('\n<pre><code>[x] a\n</code></pre>\n'));
  expect(render('-  [x] a')).toBe(taskListHTML);
  expect(render('-   [x] a')).toBe(taskListHTML);
  expect(render('-    [x] a')).toBe(taskListHTML);
  expect(render('-     [x] a')).toBe(preCodeHTML);
  expect(render('-      [x] a')).toBe(ul(li('\n<pre><code> [x] a\n</code></pre>\n')));
  expect(render('-\t[x] a')).toBe(taskListHTML);
  expect(render('-\t [x] a')).toBe(taskListHTML);
  expect(render('- \t [x] a')).toBe(taskListHTML);
  expect(render('-  \t [x] a')).toBe(taskListHTML);
  expect(render('-\t  [x] a')).toBe(preCodeHTML);
  expect(render('- \t  [x] a')).toBe(preCodeHTML);
  expect(render('-  \t  [x] a')).toBe(preCodeHTML);
});

test('no space before checkbox marker', () => {
  expect(render('-[x]')).toBe('<p>-[x]</p>\n');
  expect(render('-[ ] text')).toBe('<p>-[ ] text</p>\n');
  expect(render('-[x] text')).toBe('<p>-[x] text</p>\n');
  expect(render('-[ ]')).toBe('<p>-[ ]</p>\n');
});

test('linebreak between checkbox and text', () => {
  expect(render('- [x]\n  a')).toBe(ul(li('[x]\na')));
  expect(render('- [x] \n  a')).toBe(ul(li('[x]\na')));
  expect(render('- [x]\\\n  a')).toBe(ul(li('[x]<br>\na')));
  expect(render('- [x] \\\n  a')).toBe(taskList(checked(' <br>\na')));
  expect(render('- [x] \\ a')).toBe(taskList(checked(' \\ a')));
});
