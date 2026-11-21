" <https://github.com/atom/language-shellscript/blob/35dc1aa1371ab75ece08fd0837330eb62e1f9da9/grammars/shell-session.cson>
" <https://github.com/PrismJS/prism/blob/v1.30.0/components/prism-shell-session.js>

if exists('b:current_syntax')
  finish
endif

let s:cpo_save = &cpoptions
set cpoptions&vim

if !dotutils#syn_exists('@shell')
  syntax include @shell syntax/sh.vim
  unlet! b:current_syntax
endif

" `.{-}` is the same as `.*?` in normal regex engines, and `.{-1,}` is equivalent to `.+?`
let s:prompt_kinds = [
  \ 'sh\S{-}',
  \ '\w+\S+[@:]\S+%(\s+\S+)?',
  \ '\[\S{-1,}[@:].{-1,}\].{-}\s*',
  \ ]

let s:prompt_prefix = '\(\S{-1,}\)\s*'

let s:prompt = '%(' . s:prompt_prefix . ')?' . '%(' . join(s:prompt_kinds, '|') . ')'

let s:prompt_char = '[>$#%❯➜]'

syntax region shellSessionCommand start=// end=/$/ keepend oneline contained contains=@shell

execute 'syntax match shellSessionPromptChar /\v' . s:prompt_char . '\ze\s/ contained'
  \ 'nextgroup=shellSessionCommand'

" Must come before `shellSessionPrompt` to get lower priority for matching. This
" is a fallback for when there is no prompt before the prompt character, and the
" character sits directly at the start of a line.
execute 'syntax match shellSessionJustPromptChar /\v^' . s:prompt_char . '\ze\s/'
  \ 'nextgroup=shellSessionCommand'

execute 'syntax match shellSessionPrompt /\v^' . s:prompt . '\ze' . s:prompt_char . '\s/'
  \ 'nextgroup=shellSessionPromptChar'

highlight default link shellSessionPrompt String
highlight default link shellSessionPromptChar Title
highlight default link shellSessionJustPromptChar shellSessionPromptChar

let b:current_syntax = 'sh-session'

unlet s:prompt s:prompt_char s:prompt_kinds s:prompt_prefix

let &cpoptions = s:cpo_save
unlet s:cpo_save
