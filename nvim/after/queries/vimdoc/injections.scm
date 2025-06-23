;; extends

; This query adds syntax highlighting to blocks for which no explicit syntax is defined.
(codeblock
  ; the dots work like anchors, similar to ^ and $ in a regular expression
  . ((code) @injection.content) .
  (#set! injection.language "vim")
  (#set! injection.include-children))
