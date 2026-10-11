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

    for (let i = 2; i < tokens.length; i++) {
      let token = tokens[i];
      if (
        tokens[i - 2].type === 'list_item_open' &&
        tokens[i - 1].type === 'paragraph_open' &&
        token.type === 'inline' &&
        token.children != null
      ) {
        let match = /^\[([xX\s])\]\s/.exec(token.content);
        if (match == null) continue;
        let checked = match[1] === 'x' || match[1] === 'X';
        token.children[0].content = token.children[0].content.slice(3);

        let checkbox = new state.Token('tasklist_checkbox', 'input', 0);
        checkbox.attrs = [
          ['type', 'checkbox'],
          ['disabled', ''],
          ['class', 'task-list-item-checkbox'],
        ];
        if (checked) checkbox.attrs.push(['checked', '']);
        token.children.unshift(checkbox);

        tokens[i - 2].attrJoin('class', 'task-list-item');

        let list = tokens[findParentToken(tokens, i - 2)];
        list.meta = list.meta || {};
        if (!list.meta.addedTaskListClass) {
          list.attrJoin('class', 'contains-task-list');
          list.meta.addedTaskListClass = true;
        }
      }
    }
  });
}

function findParentToken(/** @type {md.Token[]} */ tokens, /** @type {number} */ index) {
  let targetLevel = tokens[index].level - 1;
  for (let i = index - 1; i >= 0; i--) {
    if (tokens[i].level === targetLevel) {
      return i;
    }
  }
  return -1;
}

module.exports = markdownItTasklist;
