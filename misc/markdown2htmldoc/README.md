**The main goal of this script is to render Markdown documents in the same way they are presented on GitHub.com.**

Aspects of Markdown rendering on GitHub.com that are currently supported:

- [x] Standard [CommonMark](https://spec.commonmark.org/current/) syntax - handled by [markdown-it]
- [x] Tables[^tables], strikethrough[^strikethrough], extended autolinks[^autolinks] - these [Github Flavored Markdown][GFM] extensions are also handled by [markdown-it] out of the box
- [x] [GFM] task lists[^tasklist]
- [ ] Footnotes[^footnotes]
- [x] Emojis[^emojis]
- [ ] `@`-mentions[^mentions]
- [ ] Permalinks to code blocks[^code-permalinks]
- [ ] Autolinks to issues[^issue-autolinks] or commit hashes[^commit-autolinks]
- [ ] CSS colors previews[^colors]
- [ ] HTML sanitization[^sanitization]
- [ ] Links that start with a `/` become relative to the repository root[^relative-links]
- [ ] Specifiers for dark-/light-mode-only images[^dark-light-only]
- [ ] Rendering of code blocks with special languages as interactive diagrams:
  - [ ] [Mermaid](https://github.com/mermaid-js/mermaid#readme)[^mermaid]
  - [ ] [geoJSON](https://en.wikipedia.org/wiki/GeoJSON) and [topoJSON](https://github.com/topojson/topojson#readme)[^geojson]
  - [ ] [ASCII STL](<https://en.wikipedia.org/wiki/STL_(file_format)>)[^stl]
- [ ] Rendering of LaTeX math[^math] between `$ ... $` and `$$ ... $$`, and inside <code>```math</code> blocks
- [ ] Alerts[^alerts]

[markdown-it]: https://github.com/markdown-it/markdown-it
[GFM]: https://github.github.com/gfm/

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
