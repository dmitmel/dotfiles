" modified version of base16-vim (https://github.com/chriskempson/base16-vim)
" by Chris Kempson (http://chriskempson.com)

set background=dark
hi clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'dotfiles'

" This lookup table will be built in the `setup` function.
let s:lookup = {}

function! s:hi(group, defs) abort
  let fg = s:lookup[get(a:defs, 'fg', '')]
  let bg = s:lookup[get(a:defs, 'bg', '')]
  let sp = s:lookup[get(a:defs, 'sp', '')]
  let attr = get(a:defs, 'attr', 'NONE')
  return 'hi ' . a:group
  \ . ' guifg='.(fg.gui) . ' ctermfg='.(fg.cterm)
  \ . ' guibg='.(bg.gui) . ' ctermbg='.(bg.cterm)
  \ . ' gui='.attr . ' cterm='.attr . ' guisp='.(sp.gui)
endfunction

function! s:lerp_byte(a, b, t) abort
  " Floating-point numbers were added in vim-7.2, bit operations in
  " patch-7.3.377. That's old enough for all intents and purposes.
  return min([0xff, max([0, float2nr(round(a:a * (1 - a:t) + a:b * a:t))])])
endfunction

function! s:mix_colors(color1, color2, factor) abort
  let r = s:lerp_byte(a:color1.r, a:color2.r, a:factor)
  let g = s:lerp_byte(a:color1.g, a:color2.g, a:factor)
  let b = s:lerp_byte(a:color1.b, a:color2.b, a:factor)
  return printf('#%02x%02x%02x', r, g, b)
endfunction

function! s:setup() abort
  let ansi_colors = g:dotfiles#colorscheme#ansi_colors_mapping
  let colors = g:dotfiles#colorscheme#base16_colors

  let s:lookup = {}
  for [key, color] in items(colors)
    let s:lookup[key] = color
  endfor
  let s:lookup['fg'] = {'gui': 'fg', 'cterm': 'fg'}
  let s:lookup['bg'] = {'gui': 'bg', 'cterm': 'bg'}
  let s:lookup[''] = {'gui': 'NONE', 'cterm': 'NONE'}

  let has_nocombine = has('patch-8.0.0914') || has('nvim-0.5.0')
  let attr_nocombine = has_nocombine ? 'nocombine' : 'NONE'

  " funcref() is marginally faster in Neovim for some reason /shrug
  let l:Hi = has('nvim') && has('patch-7.4.2137') ? funcref('s:hi') : function('s:hi')

  " General syntax highlighting {{{

  exec Hi('Normal',        { 'fg': 0x5, 'bg': 0x0 })
  exec Hi('Italic',        { 'fg': 0xE, 'attr': 'italic'    })
  exec Hi('Bold',          { 'fg': 0xA, 'attr': 'bold'      })
  exec Hi('Underlined',    { 'fg': 0x8, 'attr': 'underline' })
  exec Hi('Strikethrough', { 'attr': 'strikethrough' })
  exec Hi('Title',         { 'fg': 0xD })
  hi! link Directory Title
  exec Hi('Conceal',       { 'fg': 0xC })
  hi! link SpecialKey Special
  exec Hi('MatchParen',    { 'fg': 'fg', 'bg': 0x3 })

  " The idea of using the `nocombine` attribute was taken from
  " <https://github.com/lukas-reineke/indent-blankline.nvim/blob/0a98fa8dacafe22df0c44658f9de3968dc284d20/lua/indent_blankline/utils.lua#L221>.
  exec Hi('NonText',    { 'fg': 0x3, 'attr': attr_nocombine })
  exec Hi('IndentLine', { 'fg': 0x2, 'attr': attr_nocombine })
  hi! link IndentBlanklineChar               IndentLine
  hi! link IndentBlanklineSpaceChar          Whitespace
  hi! link IndentBlanklineSpaceCharBlankline Whitespace
  hi! link IndentBlanklineContextChar        Label

  let g:indent_blankline_char_highlight_list = []
  for color in range(7)
    exec 'hi clear IndentLineRainbow' . color
    if get(g:, 'dotfiles_rainbow_indent_opacity', 0) !=# 0
      call add(g:indent_blankline_char_highlight_list, 'IndentLineRainbow' . color)
      exec 'hi IndentLineRainbow' . color
      \ 'ctermfg=' . colors[0x2].cterm
      \   'guifg=' . s:mix_colors(colors[0x0], colors[8 + color], g:dotfiles_rainbow_indent_opacity)
      \     'gui=' . attr_nocombine
      \   'cterm=' . attr_nocombine
    endif
  endfor

  exec Hi('Keyword',     { 'fg': 0xE })
  hi! link Statement       Keyword
  hi! link Repeat          Keyword
  hi! link StorageClass    Keyword
  hi! link Exception       Keyword
  hi! link Structure       Keyword
  hi! link Conditional     Keyword
  exec Hi('Constant',    { 'fg': 0x9 })
  hi! link Boolean         Constant
  hi! link Float           Constant
  hi! link Number          Constant
  exec Hi('String',      { 'fg': 0xB })
  hi! link Character       String
  hi! link Quote           String
  hi! link StringDelimiter String
  exec Hi('Comment',     { 'fg': 0x3 })
  hi! link SpecialComment  Comment
  exec Hi('Todo',        { 'fg': 0xA, 'bg': 'bg', 'attr': 'reverse,bold' })
  exec Hi('Function',    { 'fg': 0xD })
  exec Hi('Identifier',  { 'fg': 0x8 })
  hi! link Variable        Identifier
  " exec Hi('Include',     { 'fg': 0xF })
  hi! link Include         Keyword
  exec Hi('PreProc',     { 'fg': 0xA })
  exec Hi('Label',       { 'fg': 0xA })
  hi! link Operator      NONE
  hi! link Delimiter     NONE
  exec Hi('Special',     { 'fg': 0xC })
  exec Hi('Tag',         { 'fg': 0xA })
  exec Hi('Type',        { 'fg': 0xA })
  hi! link Typedef         Type

  " }}}

  " User interface {{{

  exec Hi('Error',      { 'fg': 0x8, 'bg': 'bg', 'attr': 'reverse' })
  exec Hi('ErrorMsg',   { 'fg': 0x8 })
  exec Hi('WarningMsg', { 'fg': 0x9 })
  exec Hi('TooLong',    { 'fg': 0x8 })
  exec Hi('Debug',      { 'fg': 0x8 })

  exec Hi('CocErrorSign',     { 'fg': 'bg', 'bg': 0x8 })
  exec Hi('CocWarningSign',   { 'fg': 'bg', 'bg': 0xA })
  exec Hi('CocInfoSign',      { 'fg': 'bg', 'bg': 0xD })
  exec Hi('CocHintSign',      { 'fg': 'bg', 'bg': 0xD })
  " The float hlgroups are a fix for changes in
  " <https://github.com/neoclide/coc.nvim/commit/a34b3ecf6b45908fa5c86afa26874b20fb7851d3> and
  " <https://github.com/neoclide/coc.nvim/commit/a9a4b4c584a90784f95ba598d1cb6d37fb189e5a>.
  exec Hi('CocErrorFloat',    { 'fg': 0x8 })
  exec Hi('CocWarningFloat',  { 'fg': 0xA })
  exec Hi('CocInfoFloat',     { 'fg': 0xD })
  exec Hi('CocHintFloat',     { 'fg': 0xD })
  hi! link FgCocErrorFloatBgCocFloating   CocErrorSign
  hi! link FgCocWarningFloatBgCocFloating CocWarningSign
  hi! link FgCocInfoFloatBgCocFloating    CocInfoSign
  hi! link FgCocHintFloatBgCocFloating    CocHintSign

  exec Hi('CocSelectedText',  { 'fg': 0xE, 'bg': 0x1, 'attr': 'bold' })
  exec Hi('CocSearch',        { 'fg': 0xD })
  exec Hi('CocVirtualText',   { 'fg': 0x4 })
  hi! link CocCodeLens          CocVirtualText
  hi! link CocInlayHint         CocVirtualText
  exec Hi('CocFadeOut',       { 'fg': 0x3 })
  hi! link CocDisabled          CocFadeOut
  hi! link CocFloatDividingLine CocFadeOut
  exec Hi('CocUnderline',     { 'attr': 'underline'     })
  exec Hi('CocStrikeThrough', { 'attr': 'strikethrough' })
  hi! link CocMarkdownLink      Underlined
  hi! link CocLink              Underlined
  hi! link CocDiagnosticsFile   Directory
  hi! link CocOutlineName       NONE
  hi! link CocExtensionsLoaded  NONE
  hi! link CocSymbolsName       NONE
  hi! link CocOutlineIndentLine IndentLine
  hi! link CocSymbolsFile       Directory

  if has('nvim-0.5.0')
    let name_prefix = has('nvim-0.6.0') ? 'Diagnostic' : 'LspDiagnostics'
    let severities_colors = [0x8, 0xA, 0xD, 0xD]

    for severity in range(4)
      let severity_color = [0x8, 0xA, 0xD, 0xD][severity]
      if has('nvim-0.6.0')
        let severity_name = ['Error', 'Warn', 'Info', 'Hint'][severity]
        let default_hl_name = name_prefix . severity_name
      else
        let severity_name = ['Error', 'Warning', 'Information', 'Hint'][severity]
        let default_hl_name = name_prefix.'Default'.severity_name
      endif

      exec Hi(default_hl_name, { 'fg': 'bg', 'bg': severity_color })
      exec Hi(name_prefix.'Underline'.severity_name, { 'attr': 'underline' })
      exec 'hi! link '.name_prefix.'Floating'.severity_name.' '.default_hl_name
      exec 'hi! link '.name_prefix.'Sign'.severity_name.' '.default_hl_name

      if get(g:, 'dotfiles_lsp_diagnostics_gui_style')
        let severity_color = colors[severity_color]
        exec 'hi' name_prefix.'Line'.severity_name
        \ 'guibg=' s:mix_colors(colors[0x0], severity_color, 0.1)
        exec 'hi' name_prefix.'VirtualText'.severity_name
        \ 'ctermfg=bg'
        \ 'ctermbg=' . severity_color.cterm
        \ 'guifg=' . severity_color.gui
        \ 'gui=bold'
      else
        exec 'hi! link '.name_prefix.'VirtualText'.severity_name.' '.default_hl_name
      endif
    endfor

    exec Hi(name_prefix.'UnderlineUnnecessary', { 'fg': 0x3 })
    exec Hi(name_prefix.'UnderlineDeprecated',  { 'attr': 'strikethrough' })

    hi! link LspHover Search
    " <https://github.com/neovim/neovim/pull/15018>
    exec Hi('LspSignatureActiveParameter', { 'attr': 'underline' })
  endif

  exec Hi('FoldColumn', { 'fg': 0xC, 'bg': 0x1 })
  exec Hi('Folded',     { 'fg': 0x3, 'bg': 0x1 })

  exec Hi('IncSearch', { 'fg': 0x1, 'bg': 0x9 })
  exec Hi('Search',    { 'fg': 0x1, 'bg': 0xA })
  hi! link Substitute    Search
  hi! link CurSearch     Search

  exec Hi('ModeMsg',  { 'fg': 0xB, 'attr': 'bold' })
  exec Hi('Question', { 'fg': 0xB })
  hi! link MoreMsg      Question
  exec Hi('Visual',   { 'bg': 0x2 })
  exec Hi('WildMenu', { 'fg': 0x1, 'bg': 'fg' })

  " exec Hi('Cursor',       { 'bg': 'fg' })
  exec Hi('CursorLine',   {            'bg': 0x1 })
  hi! link CursorColumn     CursorLine
  exec Hi('ColorColumn',  {            'bg': 0x1 })
  exec Hi('LineNr',       { 'fg': 0x3, 'bg': 0x1 })
  exec Hi('CursorLineNr', { 'fg': 0x4, 'bg': 0x1 })
  " exec Hi('QuickFixLine', {            'bg': 0x2                 })
  " exec Hi('qfError',      { 'fg': 0x8, 'bg': 0x1, 'attr': 'bold' })
  " exec Hi('qfWarning',    { 'fg': 0xA, 'bg': 0x1, 'attr': 'bold' })
  " exec Hi('qfInfo',       { 'fg': 0xD, 'bg': 0x1, 'attr': 'bold' })
  " exec Hi('qfNote',       { 'fg': 0xD, 'bg': 0x1, 'attr': 'bold' })
  " The secondary quickfix list setup. Requires a bunch of weird tricks with
  " reverse video to look nice. This is needed because highlighting of the
  " current qflist item with the QuickFixLine hlgroup is handled as a special
  " case (see <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/screen.c#L2391-L2394>),
  " and, unfortunately, QuickFixLine overrides the background colors set by
  " syntax-related hlgroups, in particular qfError/qfWarning/qfInfo/qfNote.
  exec Hi('QuickFixLine', { 'fg': 0xE, 'attr': 'underline', 'sp': 0xE })
  exec Hi('qfError',      { 'fg': 0x8, 'attr': 'reverse,bold' })
  exec Hi('qfWarning',    { 'fg': 0xA, 'attr': 'reverse,bold' })
  exec Hi('qfInfo',       { 'fg': 0xD, 'attr': 'reverse,bold' })
  exec Hi('qfNote',       { 'fg': 0xD, 'attr': 'reverse,bold' })

  exec Hi('SignColumn',   { 'fg': 0x3,  'bg': 0x1 })
  exec Hi('StatusLine',   { 'fg': 0x4,  'bg': 0x1 })
  exec Hi('StatusLineNC', { 'fg': 0x3,  'bg': 0x1 })
  exec Hi('VertSplit',    { 'fg': 0x2,  'bg': 0x2 })
  hi! link WinSeparator     VertSplit
  hi! link TabLine          StatusLine
  hi! link TabLineFill      StatusLine
  exec Hi('TabLineSel',   { 'fg': 0xB,  'bg': 0x1 })
  exec Hi('NormalFloat',  { 'fg': 'fg', 'bg': 0x1 })
  hi! link FloatBorder      NormalFloat
  hi! link CocFloating      NormalFloat

  hi! link Pmenu                     NormalFloat
  exec Hi('PmenuSel',              { 'fg': 'bg', 'bg': 0xD })
  hi! link PmenuThumb                Cursor
  hi! link CocMenuSel                PmenuSel
  exec Hi('CocPumSearch',          { 'fg': 0xA })
  exec Hi('CocPumDetail',          { 'fg': 0x4 })
  hi! link CocPumShortcut            CocPumDetail
  exec Hi('CmpItemAbbrDefault',    { 'fg': 0x5 })
  exec Hi('CmpItemAbbrMatch',      { 'fg': 0xA })
  exec Hi('CmpItemAbbrMatchFuzzy', { 'fg': 0xE })
  exec Hi('CmpItemKind',           { 'fg': 0xD })
  exec Hi('CmpItemMenu',           { 'fg': 0x4 })
  exec Hi('CmpItemAbbrDeprecated', { 'attr': 'strikethrough' })

  hi! link ctrlsfMatch     Search
  hi! link ctrlsfLnumMatch ctrlsfMatch

  if $TERM ==# 'xterm-kitty'
    exec Hi('SpellBad',   { 'attr': 'undercurl', 'sp': 0x8 })
    exec Hi('SpellLocal', { 'attr': 'undercurl', 'sp': 0xC })
    exec Hi('SpellCap',   { 'attr': 'undercurl', 'sp': 0xD })
    exec Hi('SpellRare',  { 'attr': 'undercurl', 'sp': 0xE })
  else
    exec Hi('SpellBad',   { 'attr': 'undercurl', 'sp': 0x8, 'fg': 'bg', 'bg': 0x8 })
    exec Hi('SpellLocal', { 'attr': 'undercurl', 'sp': 0xC, 'fg': 'bg', 'bg': 0xC })
    exec Hi('SpellCap',   { 'attr': 'undercurl', 'sp': 0xD, 'fg': 'bg', 'bg': 0xD })
    exec Hi('SpellRare',  { 'attr': 'undercurl', 'sp': 0xE, 'fg': 'bg', 'bg': 0xE })
  endif

  exec Hi('Sneak',  { 'fg': 'bg', 'bg': 0xB, 'attr': 'bold' })
  hi! link SneakScope Visual
  hi! link SneakLabel Sneak

  " checkhealth UI
  exec Hi('healthSuccess', { 'fg': 'bg', 'bg': 0xB, 'attr': 'bold' })
  exec Hi('healthWarning', { 'fg': 'bg', 'bg': 0xA, 'attr': 'bold' })
  exec Hi('healthError',   { 'fg': 'bg', 'bg': 0x8, 'attr': 'bold' })

  " Vimspector
  exec Hi('vimspectorBP',         { 'fg': 'bg', 'bg': 0x8, 'attr': 'bold' })
  exec Hi('vimspectorBPCond',     { 'fg': 'bg', 'bg': 0x9, 'attr': 'bold' })
  exec Hi('vimspectorBPLog',      { 'fg': 'bg', 'bg': 0xA, 'attr': 'bold' })
  exec Hi('vimspectorBPDisabled', { 'fg': 'bg', 'bg': 0xF, 'attr': 'bold' })
  exec Hi('vimspectorPC',         { 'fg': 'bg', 'bg': 0xB, 'attr': 'bold' })
  hi! link vimspectorPCBP          vimspectorPC
  hi! link vimspectorCurrentThread vimspectorPC
  hi! link vimspectorCurrentFrame  vimspectorPC

  " }}}

  " LSP semantic tokens {{{
  " <https://github.com/neoclide/coc.nvim/blob/514f1191ee659191757d8020b297fc81c86c9024/plugin/coc.vim#L464-L497>
  " <https://github.com/neoclide/coc.nvim/blob/04405633dee69c74ae6b503d7bf74466729c8ceb/plugin/coc.vim#L563-L596>
  " <https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#semanticTokenTypes>
  " <https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#semanticTokenModifiers>
  " <https://github.com/rust-lang/rust-analyzer/blob/ad51a17c627b4ca57f83f0dc1f3bb5f3f17e6d0b/editors/code/package.json#L1855-L2079>
  " <https://github.com/rust-lang/rust-analyzer/blob/ad51a17c627b4ca57f83f0dc1f3bb5f3f17e6d0b/crates/ide/src/syntax_highlighting.rs#L65-L182>
  " NOTE: <https://github.com/neoclide/coc.nvim/commit/b01ae44a99fd90ac095fbf101ebd234ccf0335d6>

  hi! link CocSemTypeKeyword Keyword
  hi! link CocSemTypeModKeywordDocumentation Special
  hi! link CocSemTypeModifier StorageClass
  hi! link CocSemModDeprecated Strikethrough

  " hi! link CocSemTypeComment Comment  " Messes with TODOs in comments
  hi! link CocSemTypeOperator Operator
  hi! link CocSemTypeString String
  hi! link CocSemTypeBoolean Boolean
  hi! link CocSemTypeNumber Number
  hi! link CocSemTypeLifetime Special
  hi! link CocSemTypeRegexp Special

  hi! link CocSemTypeFunction Function
  hi! link CocSemTypeMethod Function
  hi! link CocSemTypeMacro Define
  hi! link CocSemTypeModMacroDeclaration Function
  hi! link CocSemTypeModMacroDefinition Function
  hi! link CocSemTypeAttribute PreProc
  hi! link CocSemTypeBuiltinAttribute PreProc
  hi! link CocSemTypeEvent Function

  hi! link CocSemTypeType Type
  hi! link CocSemTypeClass Type
  hi! link CocSemTypeInterface Type
  hi! link CocSemTypeStruct Type
  hi! link CocSemTypeEnum Type
  hi! link CocSemTypeSelfTypeKeyword Type
  hi! link CocSemTypeBuiltinType Type
  hi! link CocSemTypeTypeAlias Type
  hi! link CocSemTypeTypeParameter Special
  hi! link CocSemTypeDecorator Special

  hi! link CocSemTypeModParameterDeclaration Variable
  hi! link CocSemTypeModPropertyDeclaration Variable
  hi! link CocSemTypeModVariableDeclaration Variable
  hi! link CocSemTypeModParameterDefinition Variable
  hi! link CocSemTypeModPropertyDefinition Variable
  hi! link CocSemTypeModVariableDefinition Variable
  hi! link CocSemTypeSelfKeyword Identifier
  hi! link CocSemTypeNamespace Identifier
  hi! link CocSemTypeEnumMember Function

  " }}}

  " Integrated terminal {{{
  if has('nvim')
    if has_nocombine
      exec Hi('TermCursor', { 'fg': 'bg', 'bg': 'fg', 'attr': 'nocombine' })
    else
      exec Hi('TermCursor', { 'attr': 'reverse' })
    endif
    hi! link TermCursorNC NONE
    for color in range(16)
      let g:terminal_color_{color} = colors[ansi_colors[color]].gui
    endfor
  elseif has('terminal') && (has('gui_running') || &termguicolors)
    exec Hi('Terminal', { 'fg': 'fg', 'bg': 'bg' })
    let g:terminal_ansi_colors = []
    for color in range(16)
      call add(g:terminal_ansi_colors, colors[ansi_colors[color]].gui)
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
  exec Hi('DiffAdd',     { 'fg': 0xB, 'bg': 0x1 })
  exec Hi('DiffDelete',  { 'fg': 0x8, 'bg': 0x1 })
  exec Hi('DiffText',    { 'fg': 0xE, 'bg': 0x1 })
  exec Hi('DiffChange',  { 'fg': 0x3, 'bg': 0x1 })
  " diff file
  exec Hi('diffAdded',   { 'fg': 0xB })
  exec Hi('diffRemoved', { 'fg': 0x8 })
  exec Hi('diffChanged', { 'fg': 0xE })
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
  exec Hi('gitcommitSelectedType',  { 'fg': 0xD })
  exec Hi('gitcommitUnmergedType',  { 'fg': 0xD })
  exec Hi('gitcommitDiscardedType', { 'fg': 0xD })
  hi! link gitcommitBranch Function
  exec Hi('gitcommitUntrackedFile', { 'fg': 0xA, 'attr': 'bold' })
  exec Hi('gitcommitUnmergedFile',  { 'fg': 0x8, 'attr': 'bold' })
  exec Hi('gitcommitDiscardedFile', { 'fg': 0x8, 'attr': 'bold' })
  exec Hi('gitcommitSelectedFile',  { 'fg': 0xB, 'attr': 'bold' })

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
  hi! link cFormat   PreProc
  " }}}

  " C++ {{{
  hi! link cppOperator Keyword
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
  for color in range(6)
    exec Hi('mailQuoted' . (color + 1), { 'fg': 0x8 + color })
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
  hi! link pythonStrTemplate PreProc
  hi! link pythonStrFormat PreProc
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

endfunction

call s:setup()
