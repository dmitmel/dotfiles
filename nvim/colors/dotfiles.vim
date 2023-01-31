" modified version of base16-vim (https://github.com/chriskempson/base16-vim)
" by Chris Kempson (http://chriskempson.com)

" Theme setup {{{
  set background=dark
  hi clear
  if exists('syntax_on')
    syntax reset
  endif
  let g:colors_name = 'dotfiles'
" }}}

" The highlighting function {{{

  let s:colors = g:dotfiles#colorscheme#base16_colors

  let s:t_number = type(0)
  function! s:hi(group, defs) abort
    let fg = {}
    if get(a:defs, 'fg', '') isnot# ''
      let fg = a:defs['fg']
      let fg = type(fg) ==# s:t_number ? s:colors[fg] : {'gui': fg, 'cterm': fg}
    endif
    let bg = {}
    if get(a:defs, 'bg', '') isnot# ''
      let bg = a:defs['bg']
      let bg = type(bg) ==# s:t_number ? s:colors[bg] : {'gui': bg, 'cterm': bg}
    endif
    let sp = {}
    if get(a:defs, 'sp', '') isnot# ''
      let sp = a:defs['sp']
      let sp = type(sp) ==# s:t_number ? s:colors[sp] : {'gui': sp, 'cterm': sp}
    endif
    let attr = filter(
    \ ['bold', 'underline', 'undercurl', 'strikethrough', 'reverse', 'italic', 'nocombine'],
    \ 'get(a:defs, v:val)')
    let attr = !empty(attr) ? join(attr, ',') : 'NONE'
    return 'hi ' . a:group
    \ . ' guifg='.get(fg, 'gui', 'NONE') . ' ctermfg='.get(fg, 'cterm', 'NONE')
    \ . ' guibg='.get(bg, 'gui', 'NONE') . ' ctermbg='.get(bg, 'cterm', 'NONE')
    \ . ' gui='.attr . ' cterm='.attr . ' guisp='.get(sp, 'gui', 'NONE')
  endfunction

  function! s:hi_raw(group, defs) abort
    return 'hi ' . a:group
    \ . ' guifg='.get(a:defs, 'guifg', 'NONE') . ' ctermfg='.get(a:defs, 'ctermfg', 'NONE')
    \ . ' guibg='.get(a:defs, 'guibg', 'NONE') . ' ctermbg='.get(a:defs, 'ctermbg', 'NONE')
    \ . ' gui='.get(a:defs, 'gui', 'NONE') . ' cterm='.get(a:defs, 'cterm', 'NONE')
    \ . ' guisp='.get(a:defs, 'guisp', 'NONE')
  endfunction

  function! s:mix_colors(color1, color2, factor) abort
    return {
    \ 'r': float2nr(round(a:color1.r * (1 - a:factor) + a:color2.r * a:factor)),
    \ 'g': float2nr(round(a:color1.g * (1 - a:factor) + a:color2.g * a:factor)),
    \ 'b': float2nr(round(a:color1.b * (1 - a:factor) + a:color2.b * a:factor)),
    \ }
  endfunction

  function! s:color_to_css_hex(color) abort
    return printf('#%02x%02x%02x',
    \ min([max([a:color.r, 0]), 0xff]),
    \ min([max([a:color.g, 0]), 0xff]),
    \ min([max([a:color.b, 0]), 0xff]))
  endfunction

  let s:is_kitty = $TERM ==# 'xterm-kitty'
  let s:has_nocombine = has('patch-8.0.0914') || has('nvim-0.5.0')

" }}}

" General syntax highlighting {{{

  exec s:hi('Normal',        { 'fg': 0x5, 'bg': 0x0      })
  exec s:hi('Italic',        { 'fg': 0xE, 'italic': 1    })
  exec s:hi('Bold',          { 'fg': 0xA, 'bold': 1      })
  exec s:hi('Underlined',    { 'fg': 0x8, 'underline': 1 })
  exec s:hi('Strikethrough', { 'strikethrough': 1        })
  exec s:hi('Title',         { 'fg': 0xD })
  hi! link Directory Title
  exec s:hi('Conceal',       { 'fg': 0xC })
  hi! link SpecialKey Special
  exec s:hi('MatchParen',    { 'fg': 'fg', 'bg': 0x3 })

  " The idea of using the `nocombine` attribute was taken from
  " <https://github.com/lukas-reineke/indent-blankline.nvim/blob/0a98fa8dacafe22df0c44658f9de3968dc284d20/lua/indent_blankline/utils.lua#L221>.
  exec s:hi('NonText',    { 'fg': 0x3, 'nocombine': s:has_nocombine })
  exec s:hi('IndentLine', { 'fg': 0x2, 'nocombine': s:has_nocombine })
  hi! link IndentBlanklineChar               IndentLine
  hi! link IndentBlanklineSpaceChar          Whitespace
  hi! link IndentBlanklineSpaceCharBlankline Whitespace
  hi! link IndentBlanklineContextChar        Label

  if get(g:, 'dotfiles_rainbow_indent_opacity', 0) !=# 0
    let g:indent_blankline_char_highlight_list = []
    for s:color in range(7)
      call add(g:indent_blankline_char_highlight_list, 'IndentLineRainbow' . s:color)
      exec s:hi_raw('IndentLineRainbow' . s:color, {
      \ 'ctermfg': s:colors[0x2].cterm,
      \ 'guifg': s:color_to_css_hex(s:mix_colors(s:colors[0x0], s:colors[8 + s:color], g:dotfiles_rainbow_indent_opacity)),
      \ 'cterm': s:has_nocombine ? 'nocombine' : '',
      \ 'gui':   s:has_nocombine ? 'nocombine' : '',
      \ })
    endfor
  endif

  exec s:hi('Keyword',     { 'fg': 0xE })
  hi! link Statement       Keyword
  hi! link Repeat          Keyword
  hi! link StorageClass    Keyword
  hi! link Exception       Keyword
  hi! link Structure       Keyword
  hi! link Conditional     Keyword
  exec s:hi('Constant',    { 'fg': 0x9 })
  hi! link Boolean         Constant
  hi! link Float           Constant
  hi! link Number          Constant
  exec s:hi('String',      { 'fg': 0xB })
  hi! link Character       String
  hi! link Quote           String
  hi! link StringDelimiter String
  exec s:hi('Comment',     { 'fg': 0x3 })
  hi! link SpecialComment  Comment
  exec s:hi('Todo',        { 'fg': 0xA, 'bg': 'bg', 'reverse': 1, 'bold': 1 })
  exec s:hi('Function',    { 'fg': 0xD })
  exec s:hi('Identifier',  { 'fg': 0x8 })
  hi! link Variable        Identifier
  " exec s:hi('Include',     { 'fg': 0xF })
  hi! link Include         Keyword
  exec s:hi('PreProc',     { 'fg': 0xA })
  exec s:hi('Label',       { 'fg': 0xA })
  hi! link Operator        NONE
  hi! link Delimiter       NONE
  exec s:hi('Special',     { 'fg': 0xC })
  exec s:hi('Tag',         { 'fg': 0xA })
  exec s:hi('Type',        { 'fg': 0xA })
  hi! link Typedef         Type

" }}}

" User interface {{{

  exec s:hi('Error',      { 'fg': 0x8, 'bg': 'bg', 'reverse': 1 })
  exec s:hi('ErrorMsg',   { 'fg': 0x8 })
  exec s:hi('WarningMsg', { 'fg': 0x9 })
  exec s:hi('TooLong',    { 'fg': 0x8 })
  exec s:hi('Debug',      { 'fg': 0x8 })

  exec s:hi('CocErrorSign',     { 'fg': 'bg', 'bg': 0x8 })
  exec s:hi('CocWarningSign',   { 'fg': 'bg', 'bg': 0xA })
  exec s:hi('CocInfoSign',      { 'fg': 'bg', 'bg': 0xD })
  exec s:hi('CocHintSign',      { 'fg': 'bg', 'bg': 0xD })
  " The float hlgroups are a fix for changes in
  " <https://github.com/neoclide/coc.nvim/commit/a34b3ecf6b45908fa5c86afa26874b20fb7851d3> and
  " <https://github.com/neoclide/coc.nvim/commit/a9a4b4c584a90784f95ba598d1cb6d37fb189e5a>.
  exec s:hi('CocErrorFloat',    { 'fg': 0x8 })
  exec s:hi('CocWarningFloat',  { 'fg': 0xA })
  exec s:hi('CocInfoFloat',     { 'fg': 0xD })
  exec s:hi('CocHintFloat',     { 'fg': 0xD })
  hi! link FgCocErrorFloatBgCocFloating   CocErrorSign
  hi! link FgCocWarningFloatBgCocFloating CocWarningSign
  hi! link FgCocInfoFloatBgCocFloating    CocInfoSign
  hi! link FgCocHintFloatBgCocFloating    CocHintSign
  exec s:hi('CocSelectedText',  { 'fg': 0xE, 'bg': 0x1, 'bold': 1 })
  exec s:hi('CocCodeLens',      { 'fg': 0x4 })
  exec s:hi('CocFadeOut',       { 'fg': 0x3 })
  exec s:hi('CocUnderline',     { 'underline':     1 })
  exec s:hi('CocStrikeThrough', { 'strikethrough': 1 })
  hi! link CocMarkdownLink      Underlined
  hi! link CocDiagnosticsFile   Directory
  hi! link CocOutlineName       NONE
  hi! link CocExtensionsLoaded  NONE
  hi! link CocSymbolsName       NONE
  hi! link CocOutlineIndentLine IndentLine
  hi! link CocSymbolsFile       Directory

  if has('nvim-0.5.0')
    let s:name_prefix = has('nvim-0.6.0') ? 'Diagnostic' : 'LspDiagnostics'
    let s:severities_colors = [0x8, 0xA, 0xD, 0xD]

    for s:severity in range(4)
      let s:severity_color = [0x8, 0xA, 0xD, 0xD][s:severity]
      " The `:hi clear` calls are done to undo the default settings:
      " <https://github.com/neovim/neovim/blob/v0.6.0/src/nvim/syntax.c#L6219-L6222>.
      if has('nvim-0.6.0')
        let s:severity_name = ['Error', 'Warn', 'Info', 'Hint'][s:severity]
        let s:default_hl_name = s:name_prefix.s:severity_name
      else
        let s:severity_name = ['Error', 'Warning', 'Information', 'Hint'][s:severity]
        let s:default_hl_name = s:name_prefix.'Default'.s:severity_name
      endif

      exec s:hi(s:default_hl_name, { 'fg': 'bg', 'bg': s:severity_color })
      exec s:hi(s:name_prefix.'Underline'.s:severity_name, { 'underline': 1 })
      exec 'hi! link '.s:name_prefix.'Floating'.s:severity_name.' '.s:default_hl_name
      exec 'hi! link '.s:name_prefix.'Sign'.s:severity_name.' '.s:default_hl_name

      if get(g:, 'dotfiles_lsp_diagnostics_gui_style')
        let s:severity_color = s:colors[s:severity_color]
        exec s:hi_raw(s:name_prefix.'Line'.s:severity_name, {
        \ 'guibg': s:color_to_css_hex(s:mix_colors(s:colors[0x0], s:severity_color, 0.1)),
        \ })
        exec s:hi_raw(s:name_prefix.'VirtualText'.s:severity_name, {
        \ 'ctermfg': 'bg', 'ctermbg': s:severity_color.cterm, 'guifg': s:severity_color.gui, 'gui': 'bold',
        \ })
      else
        exec 'hi! link '.s:name_prefix.'VirtualText'.s:severity_name.' '.s:default_hl_name
      endif
    endfor

    exec s:hi(s:name_prefix.'UnderlineUnnecessary', { 'fg': 0x3          })
    exec s:hi(s:name_prefix.'UnderlineDeprecated',  { 'strikethrough': 1 })

    hi! link LspHover Search
    " <https://github.com/neovim/neovim/pull/15018>
    exec s:hi('LspSignatureActiveParameter', { 'underline': 1 })
  endif

  exec s:hi('FoldColumn', { 'fg': 0xC, 'bg': 0x1 })
  exec s:hi('Folded',     { 'fg': 0x3, 'bg': 0x1 })

  exec s:hi('IncSearch', { 'fg': 0x1, 'bg': 0x9 })
  exec s:hi('Search',    { 'fg': 0x1, 'bg': 0xA })
  hi! link Substitute    Search

  exec s:hi('ModeMsg',  { 'fg': 0xB, 'bold': 1 })
  exec s:hi('Question', { 'fg': 0xB })
  hi! link MoreMsg      Question
  exec s:hi('Visual',   { 'bg': 0x2 })
  exec s:hi('WildMenu', { 'fg': 0x1, 'bg': 'fg' })

  exec s:hi('CursorLine',   {            'bg': 0x1 })
  hi! link CursorColumn     CursorLine
  exec s:hi('ColorColumn',  {            'bg': 0x1 })
  exec s:hi('LineNr',       { 'fg': 0x3, 'bg': 0x1 })
  exec s:hi('CursorLineNr', { 'fg': 0x4, 'bg': 0x1 })
  " exec s:hi('QuickFixLine', {            'bg': 0x2            })
  " exec s:hi('qfError',      { 'fg': 0x8, 'bg': 0x1, 'bold': 1 })
  " exec s:hi('qfWarning',    { 'fg': 0xA, 'bg': 0x1, 'bold': 1 })
  " exec s:hi('qfInfo',       { 'fg': 0xD, 'bg': 0x1, 'bold': 1 })
  " exec s:hi('qfNote',       { 'fg': 0xD, 'bg': 0x1, 'bold': 1 })
  " The secondary quickfix list setup. Requires a bunch of weird tricks with
  " reverse video to look nice. This is needed because highlighting of the
  " current qflist item with the QuickFixLine hlgroup is handled as a special
  " case (see <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/screen.c#L2391-L2394>),
  " and, unfortunately, QuickFixLine overrides the background colors set by
  " syntax-related hlgroups, in particular qfError/qfWarning/qfInfo/qfNote.
  exec s:hi('QuickFixLine', { 'fg': 0xE, 'underline': 1, 'sp': 0xE })
  exec s:hi('qfError',      { 'fg': 0x8, 'reverse': 1, 'bold': 1   })
  exec s:hi('qfWarning',    { 'fg': 0xA, 'reverse': 1, 'bold': 1   })
  exec s:hi('qfInfo',       { 'fg': 0xD, 'reverse': 1, 'bold': 1   })
  exec s:hi('qfNote',       { 'fg': 0xD, 'reverse': 1, 'bold': 1   })

  exec s:hi('SignColumn',   { 'fg': 0x3,  'bg': 0x1 })
  exec s:hi('StatusLine',   { 'fg': 0x4,  'bg': 0x1 })
  exec s:hi('StatusLineNC', { 'fg': 0x3,  'bg': 0x1 })
  exec s:hi('VertSplit',    { 'fg': 0x2,  'bg': 0x2 })
  hi! link TabLine          StatusLine
  hi! link TabLineFill      StatusLine
  exec s:hi('TabLineSel',   { 'fg': 0xB,  'bg': 0x1 })
  exec s:hi('NormalFloat',  { 'fg': 'fg', 'bg': 0x1 })
  hi! link FloatBorder      NormalFloat

  hi! link PMenu NormalFloat
  exec s:hi('PMenuSel',              { 'fg': 'bg', 'bg': 0xD })
  exec s:hi('CmpItemAbbrDefault',    { 'fg': 0x5 })
  exec s:hi('CmpItemAbbrMatch',      { 'fg': 0xA })
  exec s:hi('CmpItemAbbrMatchFuzzy', { 'fg': 0xE })
  exec s:hi('CmpItemKind',           { 'fg': 0xD })
  exec s:hi('CmpItemMenu',           { 'fg': 0x4 })
  exec s:hi('CmpItemAbbrDeprecated', { 'strikethrough': 1 })

  hi! link ctrlsfMatch     Search
  hi! link ctrlsfLnumMatch ctrlsfMatch

  exec s:hi('SpellBad',   { 'fg': s:is_kitty ? '' : 'bg', 'bg': s:is_kitty ? '' : 0x8, 'undercurl': s:is_kitty, 'sp': 0x8 })
  exec s:hi('SpellLocal', { 'fg': s:is_kitty ? '' : 'bg', 'bg': s:is_kitty ? '' : 0xC, 'undercurl': s:is_kitty, 'sp': 0xC })
  exec s:hi('SpellCap',   { 'fg': s:is_kitty ? '' : 'bg', 'bg': s:is_kitty ? '' : 0xD, 'undercurl': s:is_kitty, 'sp': 0xD })
  exec s:hi('SpellRare',  { 'fg': s:is_kitty ? '' : 'bg', 'bg': s:is_kitty ? '' : 0xE, 'undercurl': s:is_kitty, 'sp': 0xE })

  exec s:hi('Sneak',  { 'fg': 'bg', 'bg': 0xB, 'bold': 1 })
  hi! link SneakScope Visual
  hi! link SneakLabel Sneak

  " checkhealth UI
  exec s:hi('healthSuccess', { 'fg': 'bg', 'bg': 0xB, 'bold': 1 })
  exec s:hi('healthWarning', { 'fg': 'bg', 'bg': 0xA, 'bold': 1 })
  exec s:hi('healthError',   { 'fg': 'bg', 'bg': 0x8, 'bold': 1 })

  " Vimspector
  exec s:hi('vimspectorBP',         { 'fg': 'bg', 'bg': 0x8, 'bold': 1 })
  exec s:hi('vimspectorBPCond',     { 'fg': 'bg', 'bg': 0x9, 'bold': 1 })
  exec s:hi('vimspectorBPLog',      { 'fg': 'bg', 'bg': 0xA, 'bold': 1 })
  exec s:hi('vimspectorBPDisabled', { 'fg': 'bg', 'bg': 0xF, 'bold': 1 })
  exec s:hi('vimspectorPC',         { 'fg': 'bg', 'bg': 0xB, 'bold': 1 })
  hi! link vimspectorPCBP          vimspectorPC
  hi! link vimspectorCurrentThread vimspectorPC
  hi! link vimspectorCurrentFrame  vimspectorPC

" }}}

" LSP semantic tokens {{{
  " <https://github.com/neoclide/coc.nvim/blob/514f1191ee659191757d8020b297fc81c86c9024/plugin/coc.vim#L464-L497>

  hi! link CocSemKeyword Keyword
  hi! link CocSemDocumentationKeyword Special
  hi! link CocSemModifier StorageClass
  hi! link CocSemDeprecated Strikethrough

  " hi! link CocSemComment Comment  " Messes with TODOs in comments
  hi! link CocSemOperator Operator
  hi! link CocSemString String
  hi! link CocSemBoolean Boolean
  hi! link CocSemNumber Number
  hi! link CocSemLifetime Special
  hi! link CocSemRegexp Special

  hi! link CocSemFunction Function
  hi! link CocSemMethod Function
  hi! link CocSemMacro Define
  hi! link CocSemDeclarationMacro Function
  hi! link CocSemDefinitionMacro Function
  hi! link CocSemAttribute PreProc
  hi! link CocSemBuiltinAttribute PreProc
  hi! link CocSemEvent Function

  hi! link CocSemType Type
  hi! link CocSemClass Type
  hi! link CocSemInterface Type
  hi! link CocSemStruct Type
  hi! link CocSemEnum Type
  hi! link CocSemSelfTypeKeyword Type
  hi! link CocSemBuiltinType Type
  hi! link CocSemTypeAlias Type
  hi! link CocSemTypeParameter Special
  hi! link CocSemDecorator Special

  hi! link CocSemDeclarationParameter Variable
  hi! link CocSemDeclarationProperty Variable
  hi! link CocSemDeclarationVariable Variable
  hi! link CocSemDefinitionParameter Variable
  hi! link CocSemDefinitionProperty Variable
  hi! link CocSemDefinitionVariable Variable
  hi! link CocSemSelfKeyword Identifier
  hi! link CocSemNamespace Identifier
  hi! link CocSemEnumMember Function

" }}}

" Integrated terminal {{{
  let s:ansi_colors = g:dotfiles#colorscheme#ansi_colors_mapping
  if has('nvim')
    if s:has_nocombine
      exec s:hi('TermCursor', { 'fg': 'bg', 'bg': 'fg', 'nocombine': 1 })
    else
      exec s:hi('TermCursor', { 'reverse': 1 })
    endif
    hi! link TermCursorNC NONE
    for s:color in range(16)
      let g:terminal_color_{s:color} = s:colors[s:ansi_colors[s:color]].gui
    endfor
  elseif has('terminal') && (has('gui_running') || &termguicolors)
    exec s:hi('Terminal', { 'fg': 'fg', 'bg': 'bg' })
    let g:terminal_ansi_colors = []
    for s:color in range(16)
      call add(g:terminal_ansi_colors, s:colors[s:ansi_colors[s:color]].gui)
    endfor
  endif
" }}}

" Vim Help files {{{
  hi! link helpHyperTextEntry Function
  hi! link helpExample        String
  hi! link helpCommand        String
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
  exec s:hi('DiffAdd',     { 'fg': 0xB, 'bg': 0x1 })
  exec s:hi('DiffDelete',  { 'fg': 0x8, 'bg': 0x1 })
  exec s:hi('DiffText',    { 'fg': 0xE, 'bg': 0x1 })
  exec s:hi('DiffChange',  { 'fg': 0x3, 'bg': 0x1 })
  " diff file
  exec s:hi('diffAdded',   { 'fg': 0xB })
  exec s:hi('diffRemoved', { 'fg': 0x8 })
  exec s:hi('diffChanged', { 'fg': 0xE })
  hi! link diffNewFile     diffAdded
  hi! link diffFile        diffRemoved
  hi! link diffIndexLine   Bold
  hi! link diffLine        Title
  hi! link diffSubname     Include
" }}}

" XML {{{
  hi! link xmlTagName         Function
  hi! link xmlAttrib          Variable
  hi! link xmlTag             Comment
  hi! link xmlEndTag          Comment
  hi! link xmlAttribPunct     Delimiter
  hi! link xmlProcessingDelim Special
  hi! link xslElement         xmlTagName
  hi! link xmlNamespace       Label
" }}}

" Git {{{
  hi! link gitCommitOverflow  TooLong
  hi! link gitCommitSummary   String
  hi! link gitCommitComment   Comment
  hi! link gitcommitUntracked Comment
  hi! link gitcommitDiscarded Comment
  hi! link gitcommitSelected  Comment
  hi! link gitcommitHeader    Keyword
  exec s:hi('gitcommitSelectedType',  { 'fg': 0xD })
  exec s:hi('gitcommitUnmergedType',  { 'fg': 0xD })
  exec s:hi('gitcommitDiscardedType', { 'fg': 0xD })
  hi! link gitcommitBranch Function
  exec s:hi('gitcommitUntrackedFile', { 'fg': 0xA, 'bold': 1 })
  exec s:hi('gitcommitUnmergedFile',  { 'fg': 0x8, 'bold': 1 })
  exec s:hi('gitcommitDiscardedFile', { 'fg': 0x8, 'bold': 1 })
  exec s:hi('gitcommitSelectedFile',  { 'fg': 0xB, 'bold': 1 })

  hi! link GitGutterAdd          DiffAdd
  hi! link GitGutterDelete       DiffDelete
  hi! link GitGutterChange       DiffText
  hi! link GitGutterChangeDelete GitGutterDelete
  hi! link SignifySignAdd        DiffAdd
  hi! link SignifySignChange     DiffText
  hi! link SignifySignDelete     DiffDelete
  hi! link GitSignsAdd           DiffAdd
  hi! link GitSignsDelete        DiffDelete
  hi! link GitSignsTopDelete     GitSignsDelete
  hi! link GitSignsChange        DiffText
  hi! link GitSignsChangeDelete  GitSignsChange
  hi! link GitSignsUntracked     GitSignsAdd
" }}}

" Vim scripts {{{
  hi! link vimUserFunc      vimFuncName
  hi! link vimBracket       vimMapModKey
  hi! link vimFunction      vimFuncName
  hi! link vimParenSep      Delimiter
  hi! link vimSep           Delimiter
  hi! link vimVar           Variable
  hi! link vimFuncVar       Variable
  hi! link vimScriptDelim   Special
  hi! link vimSynType       vimCommand
  hi! link vimSynOption     vimVar
  hi! link vimSynReg        vimSynOption
  hi! link vimSynKeyRegion  vimString
  hi! link vimSyncLines     vimSynOption
  hi! link vimCommentString vimComment
" }}}

" C {{{
  hi! link cOperator Special
" }}}

" Rust {{{
  hi! link rustEnumVariant   Function
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
  hi! link scssProperty     cssProp
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
  hi! link jsFunctionKey       jsFuncName
  hi! link jsEnvComment        Special
  hi! link jsImport            Include
  hi! link jsExport            Include
  hi! link jsTemplateBraces    PreProc
  hi! link jsOf                Keyword
  hi! link jsxComponentName    Type
  hi! link jsxTagName          xmlTagName
  hi! link jsxAttrib           xmlAttrib
" }}}

" JSON {{{
  hi! link jsonNull Constant
" }}}

" TypeScript {{{
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
  hi! link typescriptRegexpString        Special
" }}}

" Markdown {{{
  hi! link markdownBoldDelimiter   Delimiter
  hi! link markdownItalicDelimiter Delimiter
  hi! link markdownCode            String
  hi! link markdownCodeDelimiter   markdownCode
  hi! link markdownUrl             htmlString
  hi! link markdownAutomaticLink   htmlLink
  hi! link mkdLinkDef              TypeDef
  hi! link mkdID                   Type
  hi! link mkdRule                 PreProc
" }}}

" Rendered Markdown (dotfiles.lsp.markup) {{{
  hi! link   cmarkNodeCode              String
  hi! link   cmarkNodeStrong            Bold
  hi! link   cmarkNodeEmph              Italic
  hi! link   cmarkNodeStrikethrough     Strikethrough
  hi! link   cmarkNodeHeading           Title
  hi! link   cmarkNodeBlockquote        Comment
  hi! link   cmarkNodeThematicBreak     PreProc
  hi! link   cmarkNodeLinkUrl           String
  hi! link   cmarkNodeLinkText          Underlined
  hi! link   cmarkNodeLinkTitle         cmarkNodeLinkUrl
  hi! link   cmarkNodeItem              Identifier
  hi! link   cmarkTodo                  Todo
" }}}

" Mail {{{
  for s:color in range(6)
    exec s:hi('mailQuoted' . (s:color + 1), { 'fg': 0x8 + s:color })
  endfor
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
  hi! link luaFuncCall       Function
  hi! link luaBraces         Delimiter
  hi! link luaFuncKeyword    Keyword
  hi! link luaFunction       luaFuncKeyword
  hi! link luaSymbolOperator Operator
  hi! link luaOperator       Keyword
  hi! link luaLocal          StorageClass
  hi! link luaSpecialTable   Type
  hi! link luaFuncArgName    Variable
  hi! link luaBuiltIn        Variable
  hi! link luaTable          Delimiter
  hi! link luaFunc           Function
  hi! link luaStringLongTag  luaStringLong
  hi! link luaIn             luaOperator
  hi! link luaErrHand        luaFuncCall
  hi! link luaDocTag         Special
" }}}

" Shell {{{
  hi! link shQuote     String
  hi! link zshFunction Function
  hi! link zshVariable Variable
" }}}

" Assembly {{{
  hi! link riscvRegister   Variable
  hi! link riscvCSRegister Special
  hi! link riscvLabel      Function
" }}}

" SQL {{{
  hi! link sqlKeyword   Keyword
  hi! link sqlStatement Statement
  hi! link sqlOperator  Keyword
" }}}

" Haskell {{{
  hi! link haskellOperators Keyword
" }}}

" TOML {{{
  hi! link tomlDotInKey NONE
" }}}

" Java {{{
  hi! link javaOperator       Keyword
  hi! link javaC_             Type
  hi! link javaDocParam       Label
  hi! link javaDocSeeTagParam Label
" }}}

" C# {{{
  hi! link csNewType Type
" }}}
