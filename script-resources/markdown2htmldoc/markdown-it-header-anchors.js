const GithubSlugger = require('github-slugger');

const OCTICON_LINK_ICON_SVG = [
  // Basically copied from Github's HTML. Also see
  // <https://stackoverflow.com/a/34249810/12005228>. I wonder what other
  // attributes can be thrown out to make this image smaller? After all, it is
  // duplicated for each and every heading.
  '<svg class="octicon octicon-link" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true">',
  '<path fill-rule="evenodd" d="M7.775 3.275a.75.75 0 001.06 1.06l1.25-1.25a2 2 0 112.83 2.83l-2.5 2.5a2 2 0 01-2.83 0 .75.75 0 00-1.06 1.06 3.5 3.5 0 004.95 0l2.5-2.5a3.5 3.5 0 00-4.95-4.95l-1.25 1.25zm-4.69 9.64a2 2 0 010-2.83l2.5-2.5a2 2 0 012.83 0 .75.75 0 001.06-1.06 3.5 3.5 0 00-4.95 0l-2.5 2.5a3.5 3.5 0 004.95 4.95l1.25-1.25a.75.75 0 00-1.06-1.06l-1.25 1.25a2 2 0 01-2.83 0z"></path>',
  '</svg>',
].join('');

function markdownItHeaderAnchors(md) {
  let slugger = new GithubSlugger();

  let defaultRender =
    md.renderer.rules.heading_open ||
    ((tokens, idx, options, _env, self) => self.renderToken(tokens, idx, options));

  // eslint-disable-next-line camelcase
  md.renderer.rules.heading_open = (tokens, idx, opts, env, self) => {
    let renderedHeadingOpen = defaultRender(tokens, idx, opts, env, self);

    let innerText = '';
    let headingContentToken = tokens[idx + 1];
    headingContentToken.children.forEach((child) => {
      switch (child.type) {
        case 'html_block':
        case 'html_inline':
          break;
        case 'emoji':
          innerText += child.markup;
          break;
        default:
          innerText += child.content;
      }
    });

    if (innerText.length > 0) {
      let id = md.utils.escapeHtml(slugger.slug(innerText));
      renderedHeadingOpen += `<a id="${id}" class="anchor" href="#${id}" aria-hidden="true">${OCTICON_LINK_ICON_SVG}</a>`;
    }

    return renderedHeadingOpen;
  };
}

module.exports = markdownItHeaderAnchors;
