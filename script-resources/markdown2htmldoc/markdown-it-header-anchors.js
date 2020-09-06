const GithubSlugger = require('github-slugger');

function markdownItHeaderAnchors(md) {
  let slugger = new GithubSlugger();

  let defaultRender =
    md.renderer.rules.heading_open ||
    ((tokens, idx, options, _env, self) =>
      self.renderToken(tokens, idx, options));

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
      renderedHeadingOpen += `<a id="${id}" class="anchor" href="#${id}" aria-hidden="true"><span class="octicon octicon-link"></span></a>`;
    }

    return renderedHeadingOpen;
  };
}

module.exports = markdownItHeaderAnchors;
