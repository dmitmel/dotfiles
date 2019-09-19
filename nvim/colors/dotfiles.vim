" modified version of base16-vim (https://github.com/chriskempson/base16-vim)
" by Chris Kempson (http://chriskempson.com)

" Color definitions {{{

  execute 'source' fnameescape(g:nvim_dotfiles_dir.'/../colorschemes/out/nvim.vim')

  if !&termguicolors && exists('$_COLORSCHEME_TERMINAL')
    set notermguicolors
  endif

" }}}

" Theme setup {{{
  hi clear
  syntax reset
  let g:colors_name = g:dotfiles_colorscheme_name
" }}}

" Highlighting function {{{
  function s:is_number(value)
    return type(a:value) == v:t_number
  endfunction

  let s:colors = g:dotfiles_colorscheme_base16_colors
  function s:hi(group, fg, bg, attr, guisp)
    let l:args = ''
    if a:fg isnot ''
      let l:fg = s:is_number(a:fg) ? s:colors[a:fg] : {'gui': a:fg, 'cterm': a:fg}
      let l:args .= ' guifg=' . l:fg.gui . ' ctermfg=' . l:fg.cterm
    endif
    if a:bg isnot ''
      let l:bg = s:is_number(a:bg) ? s:colors[a:bg] : {'gui': a:bg, 'cterm': a:bg}
      let l:args .= ' guibg=' . l:bg.gui . ' ctermbg=' . l:bg.cterm
    endif
    if a:attr isnot ''
      let l:args .= ' gui=' . a:attr . ' cterm=' . a:attr
    endif
    if a:guisp isnot ''
      let l:guisp = s:is_number(a:guisp) ? s:colors[a:guisp].gui : a:guisp
      let l:args .= ' guisp=' . l:guisp
    endif
    exec 'hi' a:group l:args
  endfunction
" }}}

" General syntax highlighting {{{

  call s:hi('Normal',     0x5,  0x0,    '',          '')
  call s:hi('Italic',     0xE,  '',     'italic',    '')
  call s:hi('Bold',       0xA,  '',     'bold',      '')
  call s:hi('Underlined', 0x8,  '',     'underline', '')
  call s:hi('Title',      0xD,  '',     '',          '')
  hi! link Directory Title
  call s:hi('Conceal',    0xC,  'NONE', '',          '')
  call s:hi('NonText',    0x3,  '',     '',          '')
  hi! link SpecialKey NonText
  call s:hi('MatchParen', 'fg', 0x3,    '',          '')

  call s:hi('Keyword', 0xE, '', '', '')
  hi! link Statement    Keyword
  hi! link Repeat       Keyword
  hi! link StorageClass Keyword
  hi! link Exception    Keyword
  hi! link Structure    Keyword
  hi! link Conditional  Keyword
  call s:hi('Constant',   0x9, '', '', '')
  call s:hi('Boolean',    0x9, '', '', '')
  call s:hi('Float',      0x9, '', '', '')
  call s:hi('Number',     0x9, '', '', '')
  call s:hi('String',     0xB, '', '', '')
  hi! link Character String
  hi! link Quote String
  call s:hi('Comment',    0x3,  '',  '', '')
  hi! link SpecialComment Comment
  call s:hi('Todo',       'bg', 0xA, 'bold', '')
  call s:hi('Function',   0xD, '', '', '')
  call s:hi('Identifier', 0x8, '', 'none', '')
  hi! link Variable Identifier
  call s:hi('Include',    0xF, '', '', '')
  call s:hi('PreProc',    0xA, '', '', '')
  call s:hi('Label',      0xA, '', '', '')
  hi! link Operator NONE
  hi! link Delimiter NONE
  call s:hi('Special',    0xC, '', '', '')
  call s:hi('Tag',        0xA, '', '', '')
  call s:hi('Type',       0xA, '', 'none', '')
  hi! link Typedef Type

" }}}

" User interface {{{

  call s:hi('Error',          'bg', 0x8,    '', '')
  call s:hi('ErrorMsg',       0x8,  'NONE', '', '')
  call s:hi('WarningMsg',     0x9,  'NONE', '', '')
  call s:hi('TooLong',        0x8,  '',     '', '')
  call s:hi('Debug',          0x8,  '',     '', '')
  hi! link CocErrorSign Error
  call s:hi('CocWarningSign', 'bg', 0xA,    '', '')
  call s:hi('CocInfoSign',    'bg', 0xD,    '', '')
  hi! link CocHintSign    CocInfoSign

  call s:hi('FoldColumn', 0xC, 0x1, '', '')
  call s:hi('Folded',     0x3, 0x1, '', '')

  call s:hi('IncSearch', 0x1, 0x9, 'none', '')
  call s:hi('Search',    0x1, 0xA, '',     '')
  hi! link Substitute Search

  call s:hi('ModeMsg',  0xB, '',   '', '')
  call s:hi('Question', 0xB, '',   '', '')
  hi! link MoreMsg Question
  call s:hi('Visual',   '',  0x2,  '', '')
  call s:hi('WildMenu', 0x1, 'fg', '', '')

  call s:hi('CursorLine',   '',  0x1, 'none', '')
  hi! link CursorColumn CursorLine
  call s:hi('ColorColumn',  '',  0x1, '', '')
  call s:hi('LineNr',       0x3, 0x1, '', '')
  call s:hi('CursorLineNr', 0x4, 0x1, '', '')
  call s:hi('QuickFixLine', '',  0x2, '', '')

  call s:hi('SignColumn',     0x3, 0x1, '', '')
  call s:hi('StatusLine',     0x4, 0x1, 'none', '')
  call s:hi('StatusLineNC',   0x3, 0x1, '', '')
  call s:hi('VertSplit',      0x2, 0x2, '', '')
  call s:hi('TabLine',        0x3, 0x1, '', '')
  call s:hi('TabLineFill',    0x3, 0x1, '', '')
  call s:hi('TabLineSel',     0xB, 0x1, '', '')

  call s:hi('PMenu',    'fg', 0x1,  '', '')
  call s:hi('PMenuSel', 0x1,  'fg', '', '')

" }}}

" AWK {{{
  hi! link awkArrayElement Number
  hi! link awkBoolLogic    Operator
  hi! link awkComma        Delimiter
  hi! link awkExpression   Operator
  hi! link awkFieldVars    awkVariables
  hi! link awkOperator     Operator
  hi! link awkPatterns     Label
  hi! link awkSemicolon    Delimiter
  hi! link awkVariables    Variable
" }}}

" Diff {{{
  " diff mode
  call s:hi('DiffAdd',     0xB, 0x1, '', '')
  call s:hi('DiffDelete',  0x8, 0x1, '', '')
  call s:hi('DiffText',    0xE, 0x1, '', '')
  call s:hi('DiffChange',  0x3, 0x1, '', '')
  " diff file
  call s:hi('diffAdded',   0xB, '', '', '')
  call s:hi('diffRemoved', 0x8, '', '', '')
  call s:hi('diffChanged', 0xE, '', '', '')
  hi! link diffNewFile   diffAdded
  hi! link diffFile      diffRemoved
  hi! link diffIndexLine Bold
  hi! link diffLine      Title
  hi! link diffSubname   Include
" }}}

" XML {{{
  call s:hi('xmlTagName', 0x8, '', '', '')
  call s:hi('xmlAttrib',  0x9, '', '', '')
  hi! link xmlTag NONE
  hi! link xmlEndTag xmlTag
" }}}

" Git {{{
  hi! link gitCommitOverflow TooLong
  hi! link gitCommitSummary String
  hi! link gitCommitComment Comment
  hi! link gitcommitUntracked Comment
  hi! link gitcommitDiscarded Comment
  hi! link gitcommitSelected Comment
  hi! link gitcommitHeader Keyword
  call s:hi('gitcommitSelectedType',  0xD, '', '', '')
  call s:hi('gitcommitUnmergedType',  0xD, '', '', '')
  call s:hi('gitcommitDiscardedType', 0xD, '', '', '')
  hi! link gitcommitBranch Function
  call s:hi('gitcommitUntrackedFile', 0xA, '', 'bold', '')
  call s:hi('gitcommitUnmergedFile',  0x8, '', 'bold', '')
  call s:hi('gitcommitDiscardedFile', 0x8, '', 'bold', '')
  call s:hi('gitcommitSelectedFile',  0xB, '', 'bold', '')

  hi! link GitGutterAdd          DiffAdd
  hi! link GitGutterDelete       DiffDelete
  hi! link GitGutterChange       DiffText
  hi! link GitGutterChangeDelete GitGutterDelete
  hi! link SignifySignAdd        DiffAdd
  hi! link SignifySignChange     DiffText
  hi! link SignifySignDelete     DiffDelete
" }}}

" Vim scripts {{{
  hi! link vimUserFunc vimFuncName
  hi! link vimBracket  vimMapModKey
  hi! link vimFunction vimFuncName
  hi! link vimParenSep Delimiter
  hi! link vimSep      Delimiter
  hi! link vimVar      Variable
  hi! link vimFuncVar  Variable
" }}}

" C {{{
  hi! link cOperator Special
" }}}

" C# {{{
  call s:hi('csClass',                  0xA, '', '', '')
  call s:hi('csAttribute',              0xA, '', '', '')
  call s:hi('csModifier',               0xE, '', '', '')
  hi! link csType Type
  call s:hi('csUnspecifiedStatement',   0xD, '', '', '')
  call s:hi('csContextualStatement',    0xE, '', '', '')
  call s:hi('csNewDecleration',         0x8, '', '', '')
" }}}

" Rust {{{
  hi! link rustEnumVariant   rustType
  hi! link rustSelf          Variable
  hi! link rustSigil         rustOperator
  hi! link rustMacroVariable Variable
" }}}

" HTML {{{
  hi! link htmlBold           Bold
  hi! link htmlItalic         Italic
  hi! link htmlTag            xmlTag
  hi! link htmlTagName        xmlTagName
  hi! link htmlSpecialTagName xmlTagName
  hi! link htmlEndTag         xmlEndTag
  hi! link htmlArg            xmlAttrib
" }}}

" CSS {{{
  hi! link cssBraces        Delimiter
  hi! link cssTagName       htmlTagName
  hi! link cssPseudoClassId Special
  hi! link cssClassName     Type
  hi! link cssClassNameDot  cssClassName
  hi! link cssAtRule        Keyword
  hi! link cssProp          Identifier
  hi! link cssVendor        Special
  hi! link cssNoise         Delimiter
  hi! link cssAttr          String
  hi! link cssAttrComma     Delimiter
  hi! link cssAttrRegion    cssAttr
" }}}

" JavaScript {{{
  hi! link javaScriptBraces    Delimiter
  hi! link jsOperator          Operator
  hi! link jsThis              Variable
  hi! link jsSuper             jsThis
  hi! link jsClassDefinition   Type
  hi! link jsFunction          Keyword
  hi! link jsArrowFunction     jsFunction
  hi! link jsFuncName          jsFuncCall
  hi! link jsClassFuncName     jsFuncCall
  hi! link jsClassMethodType   jsFunction
  hi! link jsRegexpString      Special
  hi! link jsGlobalObjects     Type
  hi! link jsGlobalNodeObjects Type
  hi! link jsExceptions        Type
  hi! link jsBuiltins          jsFuncName
  hi! link jsNull              Constant
  hi! link jsUndefined         Constant
  hi! link jsOperatorKeyword   Keyword
  hi! link jsObjectKey         Identifier
" }}}

" Markdown {{{
  hi! link mkdHeading Title
" }}}

" Mail {{{
  call s:hi('mailQuoted1', 0x8, '', '', '')
  call s:hi('mailQuoted2', 0x9, '', '', '')
  call s:hi('mailQuoted3', 0xA, '', '', '')
  call s:hi('mailQuoted4', 0xB, '', '', '')
  call s:hi('mailQuoted5', 0xD, '', '', '')
  call s:hi('mailQuoted6', 0xE, '', '', '')
  hi! link mailURL   Underlined
  hi! link mailEmail Underlined
" }}}

" Python {{{
  hi! link pythonBuiltinType Type
  hi! link pythonBuiltinObj  pythonFunction
  hi! link pythonClassVar    Variable
" }}}

" Ruby {{{
  hi! link rubyPseudoVariable  Variable
  hi! link rubyClassName       Type
  hi! link rubyAttribute       rubyFunction
  hi! link rubyConstant        Constant
  call s:hi('rubyInterpolationDelimiter', 0xF, '', '', '')
  hi! link rubySymbol          String
  hi! link rubyStringDelimiter rubyString
  hi! link rubyRegexp          Special
  hi! link rubyRegexpDelimiter rubyRegexp
" }}}

" Lua {{{
  hi! link luaFuncCall Function
  hi! link luaBraces   Delimiter
" }}}

" Shell {{{
  hi! link shQuote     String
  hi! link zshFunction Function
  hi! link zshVariable Variable
" }}}

" Spelling {{{
  call s:hi('SpellBad',   '', '', 'undercurl', 0x8)
  call s:hi('SpellLocal', '', '', 'undercurl', 0xC)
  call s:hi('SpellCap',   '', '', 'undercurl', 0xD)
  call s:hi('SpellRare',  '', '', 'undercurl', 0xE)
" }}}
