;; extends

; (call_expression
;   function: ((identifier) @name)
;   . (_) ((string_literal) @injection.content) .
;   (#any-of? @name "map" "filter")
;   (#set! injection.language "vim")
;   (#set! injection.include-children)
;   (#offset! @injection.content 0 1 0 -1))

(command_statement
  repl: (command) @injection.content
  (#set! injection.language "vim")
  (#offset! @injection.content 0 1 0 0))
