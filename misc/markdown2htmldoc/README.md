# markdown2htmldoc

**The main goal of this script is to render Markdown documents in the same way they are presented on GitHub.com.**

Aspects of Markdown rendering on GitHub.com that are currently supported:

[markdown-it]: https://github.com/markdown-it/markdown-it
[CommonMark]: https://spec.commonmark.org/current/
[GFM]: https://github.github.com/gfm/

- [x] Standard [CommonMark] syntax - handled by [markdown-it]
- [x] Tables[^tables], strikethrough[^strikethrough], extended autolinks[^autolinks] - these [Github Flavored Markdown][GFM] extensions are also handled by [markdown-it] out of the box
- [x] Task lists[^tasklist]
- [ ] Footnotes[^footnotes]
- [x] Emojis[^emojis]
- [ ] `@`-mentions[^mentions]
- [ ] Permalinks to code blocks[^code-permalinks]
- [ ] Autolinks to issues[^issue-autolinks] or commit hashes[^commit-autolinks]
- [ ] Hover cards on links to issues, commits or pull requests
- [ ] CSS colors previews[^colors]
- [ ] HTML sanitization[^sanitization]
- [x] Sanitization of dangerous URLs - [done by markdown-it by default](https://github.com/markdown-it/markdown-it/blob/15.0.3/docs/safety.md)
- [ ] Links that start with a `/` become relative to the repository root[^relative-links]
- [ ] Specifiers for dark-/light-mode-only images[^dark-light-only]
- [ ] Rendering of code blocks with special languages as interactive diagrams:
  - [ ] [Mermaid](https://github.com/mermaid-js/mermaid#readme)[^mermaid]
  - [ ] [geoJSON](https://en.wikipedia.org/wiki/GeoJSON) and [topoJSON](https://github.com/topojson/topojson#readme)[^geojson]
  - [ ] [ASCII STL](<https://en.wikipedia.org/wiki/STL_(file_format)>)[^stl]
- [ ] Rendering of LaTeX math[^math] between `$ ... $` and `$$ ... $$`, and inside <code>```math</code> blocks
- [ ] Alerts[^alerts]
- [x] Anchors automatically added to all headings
- [ ] Images are wrapped in links that point to the original file (if the image doesn't sit inside a link already)
- [ ] `<code>` and `<pre>` tags get `class="notranslate"`
- [ ] Outgoing links to external websites get `rel="nofollow"`

## What library does GitHub.com use for rendering Markdown?

Good question! GitHub does not outright say that anywhere in their documentation, but they have this repo on their org: <https://github.com/github/markup> - which gives us a couple of hints.

<https://github.com/github/markup> is a meta-library in Ruby that dispatches the parsing and rendering of various markup languages that GitHub supports to different underlying libraries, based on the type of the document it gets. Its README says that it is a part of a bigger pipeline for displaying markup files uploaded to GitHub.com to the user, being just the first step that takes the raw markup and converts it to HTML. The steps that follow filter this raw HTML to perform sanitization, highlight the syntax in code blocks, and add some GitHub-specific features like task lists in Markdown files (yes, parts of the GFM syntax are implemented as a post-processing step, outside of the parser). The README also notes that the library used for processing Markdown is [commonmarker], which is essentially just a Ruby wrapper around the Rust library [comrak].

[commonmarker]: https://github.com/gjtorikian/commonmarker
[comrak]: https://github.com/kivikakk/comrak
[cmark-gfm]: https://github.com/github/cmark-gfm

So, case closed, GitHub is using comrak for parsing Markdown under the hood, right? Well, not quite, as GitHub gave us one more hint! The endpoint `POST /markdown` of `api.github.com`, which can be used to render a piece of Markdown code to HTML on their servers, returns a header named `x-commonmarker-version` - which confirms that they are indeed using commonmarker. However, as of 2026-11-20, this header suggests that the version of commonmarker currently in use is **0.23.13**, which is _extremely_ old, as the latest released version of this library is 2.10.1. This is important because, you see, before version 1.0.0, commonmarker used to be a wrapper around the library [cmark-gfm] instead, another library which is written in C and maintained by GitHub - [commonmarker developers switched to comrak in v1.0.0.pre.2](https://github.com/gjtorikian/commonmarker/pull/185), and GitHub seem to have stayed on an old version which is still based on cmark-gfm.

The reported version of 0.23.13 is actually pretty odd because no such version exists in the [commonmarker] repo - the latest publicly available release in the 0.x series is 0.23.12. I would assume that is because GitHub probably maintain a private fork with fixes or backports they needed to make after the upstream ditched cmark-gfm for good. Although they do seem to be [moving to commonmarker 2.x as well](https://github.com/github/markup/commit/b41ed929b0ee76d8f62e7bebb538c5ec733a42d6) ([but maintain compatibility with commonmarker v0.x ](https://github.com/github/markup/commit/4f40faf5f94b166458c2481b877b634cb61387b2), for now), as they do not seem to be [actively maintaining the cmark-gfm project anymore](https://github.com/github/cmark-gfm/issues/228#issuecomment-904651431), which has been [slowly drifting out of date with the CommonMark specification](https://github.com/github/cmark-gfm/issues/288). With GitHub practically abandoning active development of cmark-gfm, other projects which have been using it downstream [have also begun switching away from it](https://github.com/pypa/readme_renderer/issues/339).

It is actually possible to pretty easily to verify that GitHub.com is indeed using cmark-gfm and not comrak - we just need a parsing bug that occurs on one, but not the other. I used Claude to find such bugs/quirks by asking it to read through the changelogs of [comrak](https://github.com/kivikakk/comrak/blob/main/CHANGELOG.md) and [cmark-gfm](https://github.com/github/cmark-gfm/blob/master/changelog.txt), and it found an ideal candidate for us: cmark-gfm does not cap the number of digits in numeric HTML entities at the correct limits. The spec (which sits in the same repository!) requires numeric entities to consist of [1-7 decimal digits](https://github.com/github/cmark-gfm/blob/0.29.0.gfm.14/test/spec.txt#L5965) or [1-6 hex digits](https://github.com/github/cmark-gfm/blob/0.29.0.gfm.14/test/spec.txt#L5980), but cmark-gfm (currently) accepts [up to 8 digits](https://github.com/github/cmark-gfm/blob/0.29.0.gfm.14/src/houdini_html_u.c#L74) for both decimal and hex entities (**TODO:** I should actually report this to the them). Comrak used to have this same inconsistency with the spec too, but that was eventually discovered and fixed for both [decimal](https://github.com/kivikakk/comrak/commit/685d8a6de9c5b6c8b0b2ead013cdd785c22c47d4) and [hexadecimal](https://github.com/kivikakk/comrak/commit/87cf630ddb5b336c6feab2eab3eddb088ae47c22) entities. Let's use this fact to check our suspicions:

```shell-session
$ comrak --version
comrak 0.59.0

$ cmark-gfm --version
cmark-gfm 0.29.0.gfm.13 - CommonMark with GitHub Flavored Markdown converter
(C) 2014-2016 John MacFarlane

$ date +'%Y-%m-%d'
2026-11-20

$ cat entities.md
&#000065; (six), &#0000065; (seven), &#00000065; (eight), &#000000065; (nine)

&#x000041; (six), &#x0000041; (seven), &#x00000041; (eight), &#x000000041; (nine)

$ comrak entities.md
<p>A (six), A (seven), &amp;#00000065; (eight), &amp;#000000065; (nine)</p>
<p>A (six), &amp;#x0000041; (seven), &amp;#x00000041; (eight), &amp;#x000000041; (nine)</p>

$ cmark-gfm entities.md
<p>A (six), A (seven), A (eight), &amp;#000000065; (nine)</p>
<p>A (six), A (seven), A (eight), &amp;#x000000041; (nine)</p>

$ PAGER='cat' gh api -X POST /markdown -F mode='gfm' -F text='@entities.md'
<p>A (six), A (seven), A (eight), &amp;#000000065; (nine)</p>
<p>A (six), A (seven), A (eight), &amp;#x000000041; (nine)</p>
```

And indeed, the response from GitHub's API matches the output of cmark-gfm. **So in conclusion,** the answer to this question is that GitHub uses [cmark-gfm], which is wrapped by [commonmarker], which is called from [github-markup](https://github.com/github/markup), whose output is then filtered by additional steps that do sanitization and add extra HTML attributes and syntax features.

[^tables]: <https://github.github.com/gfm/#tables-extension->

[^strikethrough]: <https://github.github.com/gfm/#strikethrough-extension->

[^autolinks]: <https://github.github.com/gfm/#strikethrough-extension->

[^tasklist]:
    <https://github.github.com/gfm/#task-list-items-extension->, \
    <https://github.blog/news-insights/product-news/task-lists-in-gfm-issues-pulls-comments/>, \
    <https://github.blog/news-insights/product-news/task-lists-in-all-markdown-documents/>, \
    <https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#task-lists>, \
    <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/about-tasklists>

[^footnotes]:
    <https://github.blog/changelog/2021-09-30-footnotes-now-supported-in-markdown-fields/> \
    <https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#footnotes>

[^emojis]: <https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#using-emojis>

[^mentions]: <https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#mentioning-people-and-teams>

[^code-permalinks]: <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-a-permanent-link-to-a-code-snippet>

[^issue-autolinks]: <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/autolinked-references-and-urls#issues-and-pull-requests>

[^commit-autolinks]: <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/autolinked-references-and-urls#commit-shas>

[^colors]: <https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#supported-color-models>

[^sanitization]:
    <https://github.github.com/gfm/#disallowed-raw-html-extension->, \
    <https://github.com/gjtorikian/html-pipeline/blob/c99d76dbfe817598387c371af342e25abdccd363/lib/html_pipeline/sanitization_filter.rb>, \
    <https://gitlab.com/gitlab-org/gitlab/-/blob/a7c19f7ae8ed00f512bf7324879ae87d59bb088c/lib/banzai/filter/sanitization_filter.rb>, \
    <https://github.com/syntax-tree/hast-util-sanitize/blob/7f30d9e6261583efc544ff6a93ba54ca6e53e1b5/lib/schema.js>

[^relative-links]:
    <https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#relative-links>; \
    Judging by examples given in the documentation, path traversal with `../` components is not restricted just to the files inside the repository: <https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#relative-links:~:text=Here%20are%20some%20examples%20for%20using%20relative%20links%20to%20display%20an%20image.>

[^dark-light-only]:
    <https://github.blog/changelog/2021-11-24-specify-theme-context-for-images-in-markdown/>, \
    <https://web.archive.org/web/20220430193534/https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#specifying-the-theme-an-image-is-shown-to>, \
    <https://github.blog/developer-skills/github/how-to-make-your-images-in-markdown-on-github-adjust-for-dark-mode-and-light-mode/>, \
    <https://web.archive.org/web/20220831233743/https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#specifying-the-theme-an-image-is-shown-to>

[^mermaid]:
    <https://github.blog/developer-skills/github/include-diagrams-markdown-files-mermaid/>, \
    <https://github.blog/changelog/2022-03-17-mermaid-topojson-geojson-and-ascii-stl-diagrams-are-now-supported-in-markdown-and-as-files/>, \
    <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams#creating-mermaid-diagrams>, \
    <https://docs.github.com/en/repositories/working-with-files/using-files/working-with-non-code-files#displaying-mermaid-files-on-github>

[^geojson]:
    <https://github.blog/changelog/2022-03-17-mermaid-topojson-geojson-and-ascii-stl-diagrams-are-now-supported-in-markdown-and-as-files/>, \
    <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams#creating-geojson-and-topojson-maps>, \
    <https://docs.github.com/en/repositories/working-with-files/using-files/working-with-non-code-files#mapping-geojsontopojson-files-on-github>

[^stl]:
    <https://github.blog/changelog/2022-03-17-mermaid-topojson-geojson-and-ascii-stl-diagrams-are-now-supported-in-markdown-and-as-files/>, \
    <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams#creating-stl-3d-models>, \
    <https://docs.github.com/en/repositories/working-with-files/using-files/working-with-non-code-files#3d-file-viewer>

[^math]:
    <https://github.blog/news-insights/product-news/math-support-in-markdown/>, \
    <https://github.blog/changelog/2022-05-19-render-mathematical-expressions-in-markdown/>, \
    <https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/writing-mathematical-expressions>

[^alerts]:
    <https://github.blog/changelog/2023-12-14-new-markdown-extension-alerts-provide-distinctive-styling-for-significant-content/>, \
    <https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#alerts>
