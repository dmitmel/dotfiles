// @ts-check

// A plugin for markdown-it that implements the `tasklist` extension of GitHub
// Flavored Markdown. I wrote this module because all of the existing plugins
// for task lists would generate HTML markup that was a bit too different from
// what is expected by the stylesheet stolen from github.com, so they would
// get styled incorrectly (in particular, none of the existing plugins add the
// class `task-list-item-checkbox` to the checkboxes, which GitHub's CSS uses
// to put the checkbox over the list bullets). My code was made from bits and
// pieces taken from these projects:
//
// https://github.com/revin/markdown-it-task-lists/blob/1e68dd719b9c68be65fdb74f5c5e6d94d214447e/index.js
// https://github.com/linsir/markdown-it-task-checkbox/blob/6c684bb3f02aa097fe33ca7d9fe05e19857c910d/index.js
// https://github.com/mcecot/markdown-it-checkbox/blob/852f5e957292c209e0a390043a72c1b9e75a5e5c/index.coffee
// https://github.com/TotallyInformation/node-red-contrib-uibuilder/blob/f9066f0f6a06f042ec9e41e89285a3603e86cf0c/packages/uib-md-utils/src/tasklist.mjs

/** @import * as md from 'markdown-it' */

function markdownItTasklist(/** @type {md.MarkdownIt} */ md) {
  md.core.ruler.after('inline', 'tasklist', function tasklist(state) {
    let { tokens } = state;

    let openedLists = [];

    for (let i = 0; i < tokens.length; i++) {
      switch (tokens[i].type) {
        case 'ordered_list_open':
        case 'bullet_list_open':
          openedLists.push(tokens[i]);
          break;

        case 'ordered_list_close':
        case 'bullet_list_close':
          openedLists.pop();
          break;

        case 'list_item_open':
          if (
            openedLists.length > 0 &&
            i + 2 < tokens.length &&
            tokens[i + 1].type === 'paragraph_open' &&
            tokens[i + 2].type === 'inline'
          ) {
            let parentList = openedLists[openedLists.length - 1];
            let listItem = tokens[i];
            let inline = tokens[i + 2];
            processListItem(listItem, parentList, inline);
          }
      }
    }

    function processListItem(
      /** @type {md.Token} */ listItem,
      /** @type {md.Token} */ parentList,
      /** @type {md.Token} */ inline,
    ) {
      // Make a cheap `startsWith()` check first, to see if the more expensive
      // regexp evaluation is even necessary.
      // NOTE: markdown-it has already trimmed the whitespace after the list
      // marker off the `inline.content` for us.
      if (!inline.content.startsWith('[')) return;
      // Check for the task list marker: `[x]`, `[X]` or `[ ]`
      let match = inline.content.match(/^((\[[xX\s]\])\s+)\S/);
      if (!match) return;
      let markerAndWhitespace = match[1];
      let marker = match[2];
      let checked = marker === '[x]' || marker === '[X]';

      if (!inline.children) return;
      let firstChild = inline.children[0];
      if (!firstChild || firstChild.type !== 'text') return;
      if (!firstChild.content.startsWith(markerAndWhitespace)) return;
      firstChild.content = firstChild.content.slice(marker.length);
      inline.content = inline.content.slice(marker.length);

      let checkbox = new state.Token('tasklist_checkbox', 'input', 0);
      checkbox.attrs = [
        ['type', 'checkbox'],
        ['disabled', ''],
        ['class', 'task-list-item-checkbox'],
        ['aria-label', checked ? 'Completed task' : 'Incomplete task'],
      ];
      if (checked) checkbox.attrs.push(['checked', '']);
      inline.children.unshift(checkbox);

      listItem.attrJoin('class', 'task-list-item');

      parentList.meta = parentList.meta || {};
      if (!parentList.meta.addedTaskListClass) {
        parentList.attrJoin('class', 'contains-task-list');
        parentList.meta.addedTaskListClass = true;
      }
    }
  });
}

module.exports = markdownItTasklist;
