source <sfile>:h/javascript.vim

" This was hacked together during a sleepless night, so don't expect clarity from this code.
if exists('b:dotfiles_lsp_markdown')

  hi def link typescriptHoverMember Type
  syntax match typescriptHoverMember /\K\k*/ nextgroup=typescriptHoverGenerics,typescriptHoverDot contained

  syntax match typescriptHoverDot /\./ nextgroup=typescriptMember contained

  syntax region typescriptHoverGenerics matchgroup=typescriptTypeBrackets
        \ start=/</ end=/>/
        \ contains=typescriptTypeParameter
        \ nextgroup=typescriptHoverDot
        \ contained

  hi def link typescriptHoverVariable Variable
  syntax match typescriptHoverVariable /#\?\K\k*\ze?\?:/ contained nextgroup=@memberNextGroup

  hi def link typescriptHoverFunction Function
  syntax match typescriptHoverFunction /#\?\K\k*\ze?\?(/ contained nextgroup=@memberNextGroup

  hi def link typescriptHoverConstructor Type
  syntax match typescriptHoverConstructor /\K\k*/ contained nextgroup=@typescriptCallSignature

  hi def link typescriptHover Keyword
  syntax match typescriptHover /(\(method\|property\|getter\|setter\|local var\|local function\))/hs=s+1,he=e-1
        \ contained skipwhite nextgroup=typescriptHoverFunction,typescriptHoverVariable,typescriptHoverMember
  syntax match typescriptHover /(parameter)/hs=s+1,he=e-1
        \ contained skipwhite nextgroup=typescriptHoverVariable
  syntax match typescriptHover /\<constructor\>/
        \ contained skipwhite nextgroup=typescriptHoverConstructor

  if &filetype ==# 'blink-cmp-signature'
    syntax match typescriptLspSignature /^\ze#\?\K\k*(/ nextgroup=typescriptMember transparent
    syntax match typescriptLspSignature /^\ze(/ nextgroup=@memberNextGroup transparent
  else
    syntax match typescriptHoverStart /^\%1l\%((loading\.\.\.)\)\?/ transparent skipwhite nextgroup=typescriptHover
  endif

endif

" <https://github.com/HerringtonDarkholme/yats.vim/blob/b325c449a2db4d9ee38aa441afa850a815982e8b/syntax/common.vim#L11-L12>
setlocal iskeyword-=#

if hlexists('typescriptCommentTodo')
  syn clear typescriptCommentTodo
  execute 'syn match typescriptCommentTodo contained' dotfiles#todo_comments#get_pattern()
endif
