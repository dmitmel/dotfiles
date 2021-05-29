" modified version of base16-vim (https://github.com/chriskempson/base16-vim)
" by Chris Kempson (http://chriskempson.com)

" Color definitions {{{

  execute 'source' fnameescape(g:dotfiles_dir.'/colorschemes/out/vim.vim')

  let s:is_gui_color = !has('win32') && !has('win64') && !has('win32unix') && has('termguicolors') && &termguicolors
  if s:is_gui_color && exists('$_COLORSCHEME_TERMINAL')
    set notermguicolors
  endif

  let s:is_kitty = $TERM ==# 'xterm-kitty'

" }}}

" Theme setup {{{
  hi clear
  syntax reset
  let g:colors_name = g:dotfiles_colorscheme_name
" }}}

" The highlighting function {{{
  function s:is_number(value)
    return type(a:value) == v:t_number
  endfunction

  let s:colors = g:dotfiles_colorscheme_base16_colors
  function s:hi(group, fg, bg, attr, sp)
    let fg = {}
    let bg = {}
    let attr = 'NONE'
    let sp = {}
    if a:fg isnot ''
      let fg = s:is_number(a:fg) ? s:colors[a:fg] : {'gui': a:fg, 'cterm': a:fg}
    endif
    if a:bg isnot ''
      let bg = s:is_number(a:bg) ? s:colors[a:bg] : {'gui': a:bg, 'cterm': a:bg}
    endif
    if a:attr isnot ''
      let attr = a:attr
    endif
    if a:sp isnot ''
      let sp = s:is_number(a:sp) ? s:colors[a:sp] : {'gui': a:sp, 'cterm': a:sp}
    endif
    exec 'hi' a:group
      \ 'guifg='.get(fg, 'gui', 'NONE') 'ctermfg='.get(fg, 'cterm', 'NONE')
      \ 'guibg='.get(bg, 'gui', 'NONE') 'ctermbg='.get(bg, 'cterm', 'NONE')
      \ 'gui='.(attr) 'cterm='.(attr)
      \ 'guisp='.get(sp, 'gui', 'NONE')
  endfunction
" }}}

" General syntax highlighting {{{

  " TODO: `hi clear` ?

  call s:hi('Normal',     0x5,  0x0, '',          '')
  call s:hi('Italic',     0xE,  '',  'italic',    '')
  call s:hi('Bold',       0xA,  '',  'bold',      '')
  call s:hi('Underlined', 0x8,  '',  'underline', '')
  call s:hi('Title',      0xD,  '',  '',          '')
  hi! link Directory Title
  call s:hi('Conceal',    0xC,  '',  '',          '')
  call s:hi('NonText',    0x3,  '',  '',          '')
  hi! link SpecialKey Special
  call s:hi('MatchParen', 'fg', 0x3, '',          '')

  call s:hi('Keyword', 0xE, '', '', '')
  hi! link Statement    Keyword
  hi! link Repeat       Keyword
  hi! link StorageClass Keyword
  hi! link Exception    Keyword
  hi! link Structure    Keyword
  hi! link Conditional  Keyword
  call s:hi('Constant',   0x9, '', '', '')
  hi! link Boolean Constant
  hi! link Float   Constant
  hi! link Number  Constant
  call s:hi('String',     0xB, '', '', '')
  hi! link Character       String
  hi! link Quote           String
  hi! link StringDelimiter String
  call s:hi('Comment',    0x3,  '',  '', '')
  hi! link SpecialComment Comment
  call s:hi('Todo',       'bg', 0xA, 'bold', '')
  call s:hi('Function',   0xD, '', '', '')
  call s:hi('Identifier', 0x8, '', '', '')
  hi! link Variable Identifier
  " call s:hi('Include',    0xF, '', '', '')
  hi! link Include Keyword
  call s:hi('PreProc',    0xA, '', '', '')
  call s:hi('Label',      0xA, '', '', '')
  hi! link Operator NONE
  hi! link Delimiter NONE
  call s:hi('Special',    0xC, '', '', '')
  call s:hi('Tag',        0xA, '', '', '')
  call s:hi('Type',       0xA, '', '', '')
  hi! link Typedef Type

" }}}

" User interface {{{

  call s:hi('Error',          'bg', 0x8, '', '')
  call s:hi('ErrorMsg',       0x8,  '',  '', '')
  call s:hi('WarningMsg',     0x9,  '',  '', '')
  call s:hi('TooLong',        0x8,  '',  '', '')
  call s:hi('Debug',          0x8,  '',  '', '')
  hi! link CocErrorSign    Error
  call s:hi('CocWarningSign', 'bg', 0xA, '', '')
  call s:hi('CocInfoSign',    'bg', 0xD, '', '')
  hi! link CocHintSign     CocInfoSign
  call s:hi('CocFadeOut',      0x3, '',  '', '')
  hi! link CocMarkdownLink Underlined

  call s:hi('FoldColumn', 0xC, 0x1, '', '')
  call s:hi('Folded',     0x3, 0x1, '', '')

  call s:hi('IncSearch', 0x1, 0x9, '', '')
  call s:hi('Search',    0x1, 0xA, '', '')
  hi! link Substitute Search

  call s:hi('ModeMsg',  0xB, '',   '', '')
  call s:hi('Question', 0xB, '',   '', '')
  hi! link MoreMsg Question
  call s:hi('Visual',   '',  0x2,  '', '')
  call s:hi('WildMenu', 0x1, 'fg', '', '')

  call s:hi('CursorLine',   '',  0x1, '', '')
  hi! link CursorColumn CursorLine
  call s:hi('ColorColumn',  '',  0x1, '', '')
  call s:hi('LineNr',       0x3, 0x1, '', '')
  call s:hi('CursorLineNr', 0x4, 0x1, '', '')
  call s:hi('QuickFixLine', '',  0x2, '', '')

  call s:hi('SignColumn',     0x3, 0x1, '', '')
  call s:hi('StatusLine',     0x4, 0x1, '', '')
  call s:hi('StatusLineNC',   0x3, 0x1, '', '')
  call s:hi('VertSplit',      0x2, 0x2, '', '')
  call s:hi('TabLine',        0x3, 0x1, '', '')
  call s:hi('TabLineFill',    0x3, 0x1, '', '')
  call s:hi('TabLineSel',     0xB, 0x1, '', '')

  call s:hi('PMenu',    'fg', 0x1,  '', '')
  call s:hi('PMenuSel', 0x1,  'fg', '', '')

  hi! link ctrlsfMatch     Search
  hi! link ctrlsfLnumMatch ctrlsfMatch

  let s:spell_fg   = s:is_kitty ? ''          : 'bg'
  let s:spell_attr = s:is_kitty ? 'undercurl' : ''
  call s:hi('SpellBad',   s:spell_fg, s:is_kitty ? '' : 0x8, s:spell_attr, 0x8)
  call s:hi('SpellLocal', s:spell_fg, s:is_kitty ? '' : 0xC, s:spell_attr, 0xC)
  call s:hi('SpellCap',   s:spell_fg, s:is_kitty ? '' : 0xD, s:spell_attr, 0xD)
  call s:hi('SpellRare',  s:spell_fg, s:is_kitty ? '' : 0xE, s:spell_attr, 0xE)
  unlet s:spell_fg s:spell_attr

  call s:hi('Sneak', 'bg', 0xB, 'bold', '')
  hi! link SneakScope Visual
  hi! link SneakLabel Sneak

  " checkhealth UI
  call s:hi('healthSuccess', 'bg', 0xB, 'bold', '')
  call s:hi('healthWarning', 'bg', 0xA, 'bold', '')
  call s:hi('healthError',   'bg', 0x8, 'bold', '')

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
  hi! link xmlTag Delimiter
  hi! link xmlEndTag Delimiter
  hi! link xmlAttribPunct Delimiter
  hi! link xmlProcessingDelim Delimiter
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
  hi! link rustModPath       Identifier
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
  hi! link cssPseudoClassId Type
  hi! link cssPseudoClass   cssPseudoClassId
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

" SCSS {{{
  hi! link scssSelectorName cssClassName
  hi! link scssSelectorChar cssClassnameDot
  hi! link scssAmpersand    cssSelectorOp
" }}}

" JavaScript {{{
  hi! link javaScriptBraces    Delimiter
  hi! link jsParens            Delimiter
  hi! link jsOperator          Operator
  hi! link jsStorageClass      StorageClass
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
  hi! link jsException         Exception
  hi! link jsExceptions        Type
  hi! link jsBuiltins          jsFuncName
  hi! link jsNull              Constant
  hi! link jsUndefined         Constant
  hi! link jsOperatorKeyword   Keyword
  hi! link jsObjectKey         Identifier
  hi! link jsEnvComment        Special
  hi! link jsImport            Include
  hi! link jsExport            Include
  hi! link jsTemplateBraces    PreProc
" }}}

" JSON {{{
  hi! link jsonNull Constant
" }}}

" TypeScript {{{
  let g:yats_host_keyword = 0
  hi! link typescriptParens              jsParens
  hi! link typescriptBraces              javaScriptBraces
  hi! link typescriptOperator            jsOperatorKeyword
  hi! link typescriptKeywordOp           typescriptOperator
  hi! link typescriptCastKeyword         typescriptOperator
  hi! link typescriptMappedIn            typescriptOperator
  hi! link typescriptBinaryOp            jsOperator
  hi! link typescriptOptionalMark        typescriptBinaryOp
  hi! link typescriptIdentifier          jsThis
  hi! link typescriptArrowFunc           jsArrowFunction
  hi! link typescriptFuncTypeArrow       typescriptArrowFunc
  hi! link typescriptCall                Variable
  hi! link typescriptArrowFuncArg        typescriptCall
  hi! link typescriptFuncType            typescriptCall
  hi! link typescriptMessage             NONE
  hi! link typescriptVariable            jsStorageClass
  hi! link typescriptAmbientDeclaration  typescriptVariable
  hi! link typescriptVariableDeclaration Variable
  hi! link typescriptDestructureLabel    typescriptVariableDeclaration
  hi! link typescriptDestructureVariable typescriptVariableDeclaration
  hi! link typescriptGlobal              typescriptVariableDeclaration
  hi! link typescriptTypeReference       Type
  hi! link typescriptTypeParameter       typescriptTypeReference
  hi! link typescriptConstructSignature  Keyword
  hi! link typescriptConstructorType     typescriptConstructSignature
  hi! link typescriptEndColons           Delimiter
  hi! link typescriptImport              jsImport
  hi! link typescriptImportType          typescriptImport
  hi! link typescriptExport              jsExport
  hi! link typescriptNull                jsNull
  hi! link typescriptObjectLabel         jsObjectKey
  hi! link typescriptMethodAccessor      Keyword
  hi! link typescriptClassName           jsClassDefinition
  hi! link typescriptClassHeritage       jsClassDefinition
  hi! link typescriptExceptions          jsException
  hi! link typescriptTry                 typescriptExceptions
  hi! link typescriptEnumKeyword         typescriptClassKeyword
  hi! link typescriptModule              jsImport
  hi! link typescriptAbstract            Keyword
  hi! link typescriptTemplateSB          PreProc
  hi! link typescriptDebugger            Keyword
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
  hi! link pythonClass       Type
  hi! link pythonBuiltinType pythonClass
  hi! link pythonExClass     pythonClass
  hi! link pythonBuiltinObj  pythonFunction
  hi! link pythonClassVar    Variable
" }}}

" Ruby {{{
  hi! link rubyPseudoVariable         Variable
  hi! link rubyClassName              Type
  hi! link rubyAttribute              rubyFunction
  hi! link rubyConstant               Constant
  hi! link rubyInterpolationDelimiter PreProc
  hi! link rubySymbol                 String
  hi! link rubyStringDelimiter        StringDelimiter
  hi! link rubyRegexp                 Special
  hi! link rubyRegexpDelimiter        rubyRegexp
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
