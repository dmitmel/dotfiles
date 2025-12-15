" modified version of base16-vim (https://github.com/chriskempson/base16-vim)
" by Chris Kempson (http://chriskempson.com)

" NOTE: Rewriting this in Lua is not worth it. I have already optimized the
" logic in this file well enough --- the `:hi` commands take up the most
" execution time anyway. As of 2025-04-16, in nvim v0.11.0, the Vimscript
" colorscheme consumes about 4 ms of startup time, and a Lua version (that
" implements 95% of the functionality) lowers that to ~2 ms. This is a very
" maginal improvement, plus we lose compatibility with regular Vim (apparently
" not every machine I have to work with has Vim built with `if_lua`), so my
" time is better spent optimizing code elsewhere.
" NOTE: using `nvim_set_hl()` or `hlset()` is not worth it here either.
" Creating the dictionaries for those takes more time than constructing a `:hi`
" command string.

set background=dark
highlight clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'dotfiles'

function! s:lerp_byte(a, b, t) abort
  return min([0xff, max([0, float2nr(round(a:a * (1 - a:t) + a:b * a:t))])])
endfunction

function! s:mix_colors(color1, color2, factor) abort
  let r = s:lerp_byte(a:color1.r, a:color2.r, a:factor)
  let g = s:lerp_byte(a:color1.g, a:color2.g, a:factor)
  let b = s:lerp_byte(a:color1.b, a:color2.b, a:factor)
  return printf('#%02x%02x%02x', r, g, b)
endfunction

let s:NONE = { 'gui': 'NONE', 'cterm': 'NONE' }
function! s:Hi(group, def) abort
  let fg = get(a:def, 'fg', s:NONE)
  let bg = get(a:def, 'bg', s:NONE)
  let sp = get(a:def, 'sp', s:NONE)
  let attr = get(a:def, 'attr', 'NONE')
  exe 'hi' a:group
  \ 'guifg='.(fg.gui) 'ctermfg='.(fg.cterm)
  \ 'guibg='.(bg.gui) 'ctermbg='.(bg.cterm)
  \ 'gui='.attr 'cterm='.attr 'guisp='.(sp.gui)
endfunction

function! s:setup() " NOTE: not abort
  let Hi = function('s:Hi')

  let base16 = g:dotfiles#colorscheme#base16_colors
  let [red, orange, yellow, green, cyan, blue, magenta, brown] = base16[8:15]
  let gray = base16[0:7]
  let fg = base16[5]
  let bg = base16[0]

  let nocombine     = has('patch-8.0.0914') ? 'nocombine'     : 'NONE'
  let strikethrough = has('patch-8.0.1038') ? 'strikethrough' : 'NONE'

  " General syntax highlighting {{{

  call Hi('Normal',        { 'fg': fg, 'bg': bg })
  call Hi('Italic',        { 'fg': magenta, 'attr': 'italic' })
  call Hi('Bold',          { 'fg': yellow, 'attr': 'bold' })
  call Hi('Underlined',    { 'fg': blue, 'attr': 'underline' })
  call Hi('Strikethrough', { 'attr': strikethrough })
  call Hi('Title',         { 'fg': blue })
  hi! link Directory         Title
  call Hi('Conceal',       { 'fg': gray[4] })
  call Hi('MatchParen',    { 'fg': orange, 'bg': gray[2], 'attr': 'bold' })
  call Hi('NonText',       { 'fg': gray[3] })
  " `nocombine` is necessary for indentation because:
  " <https://github.com/lukas-reineke/indent-blankline.nvim/issues/72>
  call Hi('IblIndent',     { 'fg': gray[2], 'attr': nocombine })
  hi! link IndentLine        IblIndent
  call Hi('IblSpace',      { 'fg': gray[3], 'attr': nocombine })
  call Hi('IblScope',      { 'fg': gray[3], 'attr': nocombine })
  call Hi('Added',         { 'fg': green   })
  call Hi('Removed',       { 'fg': red     })
  call Hi('Changed',       { 'fg': magenta })

  if get(g:, 'dotfiles_highlight_url_under_cursor', 0)
    call Hi('Underlined',       { 'fg': blue, 'attr': 'underline', 'sp': gray[2] })
    call Hi('ReallyUnderlined', { 'fg': blue, 'attr': 'underline', 'sp': blue })
  endif

  let rainbow_indent_opacity = get(g:, 'dotfiles_rainbow_indent_opacity', 0)
  let indent_scope_opacity   = get(g:, 'dotfiles_indent_scope_opacity', 0.2)

  if indent_scope_opacity != 0
    exe 'hi IblScope guifg=' . s:mix_colors(gray[2], blue, indent_scope_opacity)
  endif

  let g:indent_blankline_char_highlight_list    = []
  let g:indent_blankline_context_highlight_list = []
  for color in range(7)
    exe 'hi clear IblIndent' . color
    exe 'hi clear IblScope'  . color
    if rainbow_indent_opacity != 0
      call add(g:indent_blankline_char_highlight_list,    'IblIndent' . color)
      call add(g:indent_blankline_context_highlight_list, 'IblScope' . color)
      exe 'hi IblIndent'.color 'guifg='.s:mix_colors(bg, base16[8 + color], rainbow_indent_opacity)
      exe 'hi IblScope'.color  'guifg='.s:mix_colors(bg, base16[8 + color], indent_scope_opacity)
    endif
  endfor

  call Hi('Keyword',     { 'fg': magenta })
  hi! link Statement       Keyword
  hi! link Repeat          Keyword
  hi! link StorageClass    Keyword
  hi! link Exception       Keyword
  hi! link Structure       Keyword
  hi! link Conditional     Keyword
  hi! link Include         Keyword
  call Hi('Constant',    { 'fg': orange })
  hi! link Boolean         Constant
  hi! link Float           Constant
  hi! link Number          Constant
  call Hi('String',      { 'fg': green })
  hi! link Character       String
  hi! link Quote           String
  hi! link StringDelimiter String
  call Hi('Comment',     { 'fg': gray[3] })
  call Hi('Todo',        { 'fg': yellow, 'bg': bg, 'attr': 'reverse,bold' })
  call Hi('Function',    { 'fg': blue })
  hi! link Tag             Function
  call Hi('Identifier',  { 'fg': red })
  hi! link Variable        Identifier
  call Hi('PreProc',     { 'fg': yellow })
  call Hi('Label',       { 'fg': yellow })
  call Hi('Special',     { 'fg': cyan })
  hi! link SpecialKey      Special
  hi! link SpecialComment  Special
  call Hi('Type',        { 'fg': yellow })
  hi! link Typedef         Type
  call Hi('Operator',    { 'fg': fg })
  call Hi('Delimiter',   { 'fg': fg })

  " }}}

  if has('nvim-0.8.0') " Treesitter {{{

    " This group is used to reset highlighting in places like string interpolation.
    call Hi('@none', { 'fg': fg })

    hi! link @variable                  @none
    hi! link @variable.builtin          Special
    hi! link @variable.member           Variable
    hi! link @variable.parameter        Variable
    hi! link @variable.declaration      Variable
    hi! link @variable.cmake            Variable
    hi! link @variable.parameter.bash   @none
    hi! link @variable.parameter.vimdoc Special

    hi! link @module                Identifier
    hi! link @module.builtin        PreProc
    " hi! link @function.builtin      PreProc
    hi! link @type.builtin          Type

    hi! link @lsp.type.comment                    NONE
    hi! link @lsp.type.variable                   NONE
    hi! link @lsp.type.operator                   NONE
    hi! link @lsp.typemod.variable.declaration    @variable.declaration
    hi! link @lsp.typemod.variable.definition     @variable.declaration
    hi! link @lsp.typemod.function.defaultLibrary PreProc
    hi! link @lsp.typemod.variable.defaultLibrary PreProc
    hi! link @lsp.typemod.variable.defaultLibrary.go NONE
    hi! link @lsp.typemod.variable.global         PreProc
    hi! link @lsp.typemod.variable.readonly       Constant
    hi! link @lsp.typemod.keyword.documentation   SpecialComment

    hi! link @markup.raw            String
    hi! link @markup.raw.block      NONE

    hi! link @markup.link           Identifier
    hi! link @markup.link.url       Underlined
    hi! link @markup.link.label     String
    hi! link @markup.list           Identifier

    hi! link @markup.strong         Bold
    hi! link @markup.italic         Italic
    hi! link @markup.strikethrough  Strikethrough
    hi! link @markup.underline      Underlined

    hi! link @keyword.directive     PreProc
    hi! link @tag.delimiter         Comment
    hi! link @tag.attribute         Identifier
    hi! link @constant.macro        Macro
    hi! link @operator.regex        Special
    hi! link @constructor           Type

    hi! link @comment.todo Todo
    for [kind, color] in items({ 'note': blue, 'warning': yellow, 'error': red })
      call Hi('@comment.' . kind, { 'fg': color, 'bg': bg, 'attr': 'reverse,bold' })
    endfor
    hi! link @punctuation.delimiter.comment  NONE
    hi! link @punctuation.bracket.comment    NONE

  endif " }}}

  " User interface {{{

  call Hi('Error',      { 'fg': red, 'bg': bg, 'attr': 'reverse' })
  call Hi('ErrorMsg',   { 'fg': red })
  call Hi('WarningMsg', { 'fg': orange })
  call Hi('Debug',      { 'fg': red })

  call Hi('CocSelectedText',  { 'fg': magenta, 'bg': gray[1], 'attr': 'bold' })
  call Hi('CocSearch',        { 'fg': blue })
  call Hi('CocVirtualText',   { 'fg': gray[4] })
  hi! link CocCodeLens          CocVirtualText
  hi! link CocInlayHint         CocVirtualText
  call Hi('CocFadeOut',       { 'fg': gray[3] })
  hi! link CocDisabled          CocFadeOut
  hi! link CocFloatDividingLine WinSeparator
  call Hi('CocUnderline',     { 'attr': 'underline' })
  call Hi('CocStrikeThrough', { 'attr': strikethrough })
  hi! link CocMarkdownLink      Underlined
  hi! link CocLink              Underlined
  hi! link CocDiagnosticsFile   Directory
  hi! link CocOutlineName       NONE
  hi! link CocExtensionsLoaded  NONE
  hi! link CocSymbolsName       NONE
  hi! link CocOutlineIndentLine IndentLine
  hi! link CocSymbolsFile       Directory

  for [severity, color] in items({
        \ 'Error': red, 'Warn': yellow, 'Info': blue, 'Hint': blue, 'Ok': green })
    call Hi('Diagnostic'.severity, { 'fg': color })
    call Hi('DiagnosticFloating'.severity, { 'fg': color })
    call Hi('DiagnosticUnderline'.severity, { 'attr': 'underline' })

    exe 'hi clear DiagnosticLine'.severity
    exe 'hi DiagnosticLine'.severity 'guibg='.s:mix_colors(bg, color, 0.1)

    let linenr_attrs = 'guibg=' . s:mix_colors(bg, color, 0.1)
    \               . ' guifg=' . color.gui
    \             . ' ctermfg=' . gray[1].cterm
    \             . ' ctermbg=' . color.cterm

    exe 'hi clear DiagnosticLineNr'.severity
    exe 'hi DiagnosticLineNr'.severity linenr_attrs

    exe 'hi clear DiagnosticSign'.severity
    exe 'hi DiagnosticSign'.severity linenr_attrs 'cterm=bold' 'gui=bold'

    exe 'hi clear DiagnosticVirtualText'.severity
    " NOTE: in regular Vim, even when `termguicolors` mode is used, it still
    " uses `cterm` attributes instead of `gui` ones. Well, tough shit!
    exe 'hi DiagnosticVirtualText'.severity
    \ 'ctermfg='.(bg.cterm) 'ctermbg='.(color.cterm) 'guifg='.(color.gui) 'gui=bold'

    if severity ==# 'Ok'
      continue  " This one is actually an undocumented addition to vim.diagnostic
    endif

    " Translate the name of the severity into ye olde language
    let coc_severity = severity ==# 'Warn' ? 'Warning' : severity
    exe 'hi! link' 'Coc'.coc_severity.'Float' 'DiagnosticFloating'.severity
    exe 'hi! link' 'Coc'.coc_severity.'Line' 'DiagnosticLine'.severity
    exe 'hi! link' 'Coc'.coc_severity.'Sign' 'DiagnosticSign'.severity
    exe 'hi! link' 'Coc'.coc_severity.'Underline' 'DiagnosticUnderline'.severity
    exe 'hi! link' 'Coc'.coc_severity.'VirtualText' 'DiagnosticVirtualText'.severity

    " Translate once more into an even more ancient tongue
    let qf_severity = coc_severity ==# 'Hint' ? 'Note' : coc_severity

    " The second quickfix list setup. Requires a bunch of weird tricks with
    " reverse video to look nice. This is needed because highlighting of the
    " current qflist item with the QuickFixLine hlgroup is handled as a special
    " case (see <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/screen.c#L2391-L2394>),
    " and, unfortunately, QuickFixLine overrides the background colors set by
    " syntax-related hlgroups, in particular qfError/qfWarning/qfInfo/qfNote.
    call Hi('qf'.qf_severity, { 'fg': color, 'attr': 'reverse,bold' })
  endfor

  " This links to Normal by default, which looks super ugly when `cursorline` is enabled.
  hi! link qfText NONE

  call Hi('DiagnosticUnnecessary',       { 'fg': gray[3] })
  call Hi('DiagnosticDeprecated',        { 'attr': strikethrough })
  hi! link DiagnosticUnderlineUnnecessary  DiagnosticUnnecessary
  hi! link DiagnosticUnderlineDeprecated   DiagnosticDeprecated
  hi! link CocUnusedHighlight              DiagnosticUnnecessary
  hi! link CocDeprecatedHighlight          DiagnosticDeprecated

  hi! link LspReferenceText Visual
  call Hi('LspSignatureActiveParameter', { 'attr': 'underline' })

  call Hi('IncSearch', { 'fg': orange, 'bg': bg, 'attr': 'reverse' })
  call Hi('Search',    { 'fg': yellow, 'bg': bg, 'attr': 'reverse' })
  hi! link Substitute    Search
  hi! link CurSearch     Search

  " call Hi('CurSearch', { 'fg': yellow, 'bg': bg,      'attr': 'reverse' })
  " call Hi('Search',    { 'fg': yellow, 'bg': gray[7], 'attr': 'reverse' })
  " exe 'hi Search guifg='.s:mix_colors(gray[0], yellow, 0.33) 'ctermbg='.(bg.cterm)

  call Hi('ModeMsg',  { 'fg': green, 'attr': 'bold' })
  call Hi('Question', { 'fg': green })
  hi! link MoreMsg      Question
  call Hi('Visual',   { 'bg': gray[2] })
  call Hi('WildMenu', { 'fg': gray[1], 'bg': fg })

  call Hi('Cursor',         { 'fg': bg, 'bg': fg })
  call Hi('CursorLine',     { 'bg': gray[1] })
  hi! link CursorColumn       CursorLine
  call Hi('ColorColumn',    { 'bg': gray[1] })
  call Hi('LineNr',         { 'fg': gray[3] })
  call Hi('CursorLineNr',   { 'fg': gray[4], 'bg': gray[1] })
  hi! link SignColumn         LineNr
  hi! link CursorLineSign     CursorLineNr
  call Hi('Folded',         { 'fg': gray[3], 'bg': gray[1] })
  call Hi('FoldColumn',     { 'fg': gray[2], 'bg': gray[1] })
  hi! link FoldColumn         WinSeparator
  call Hi('CursorLineFold', { 'fg': gray[3], 'bg': gray[1] })
  call Hi('QuickFixLine',   { 'fg': magenta, 'attr': 'underline', 'sp': magenta })

  call Hi('StatusLine',   { 'fg': fg,      'bg': gray[1] })
  call Hi('StatusLineNC', { 'fg': gray[4], 'bg': gray[1] })
  call Hi('WinSeparator', { 'fg': gray[2] })
  hi! link MsgSeparator     WinSeparator
  hi! link VertSplit        WinSeparator
  hi! link TabLine          StatusLine
  hi! link TabLineFill      StatusLine
  call Hi('TabLineSel',   { 'fg': green,   'bg': gray[1] })
  call Hi('NormalFloat',  { 'fg': fg,      'bg': gray[1] })
  call Hi('FloatBorder',  { 'fg': gray[2], 'bg': gray[1] })
  hi! link CocFloating      NormalFloat
  call Hi('WinBar',       { 'fg': gray[6], 'bg': gray[2] })
  call Hi('WinBarNC',     { 'fg': fg,      'bg': gray[1] })
  hi! link BqfPreviewRange  Search
  hi! link BqfPreviewTitle  Label
  hi! link BqfPreviewBorder WinSeparator

  if has('nvim-0.4.0')
    highlight FloatShadow        ctermbg=Black guibg=Black blend=70
    highlight FloatShadowThrough ctermbg=Black guibg=Black blend=100
  endif

  call Hi('Pmenu',                  { 'fg': fg, 'bg': gray[1] })
  call Hi('PmenuSel',               { 'fg': bg, 'bg': blue })
  hi! link PmenuSbar                  Pmenu
  call Hi('PmenuThumb',             { 'bg': gray[5] })
  call Hi('PmenuKind',              { 'fg': blue })
  call Hi('PmenuExtra',             { 'fg': gray[4] })
  call Hi('PmenuMatch',             { 'fg': yellow })
  hi! link PmenuMatchSel              PmenuSel
  hi! link CocMenuSel                 PmenuSel
  hi! link CocPumSearch               PmenuMatch
  hi! link CocPumDetail               PmenuExtra
  hi! link CocPumShortcut             CocPumDetail
  hi! link CocListSearch              PmenuMatch
  hi! link BlinkCmpKind               PmenuKind
  hi! link BlinkCmpLabelMatch         PmenuMatch
  hi! link BlinkCmpLabelDeprecated    DiagnosticDeprecated
  hi! link BlinkCmpDocSeparator       NonText
  " Based on: <https://github.com/neoclide/coc.nvim/blob/a9ab3e4885bc8ed0aa38c5a8ee5953b0a7bc9bd3/plugin/coc.vim#L614-L649>
  " List of all CompletionItemKinds: <https://github.com/Saghen/blink.cmp/blob/7856f05dd48ea7f2c68ad3cba40202f8a9369b9e/lua/blink/cmp/types.lua#L20-L45>
  hi! link BlinkCmpKindText           Comment
  hi! link BlinkCmpKindMethod         Function
  hi! link BlinkCmpKindFunction       Function
  hi! link BlinkCmpKindConstructor    Type
  hi! link BlinkCmpKindField          Identifier
  hi! link BlinkCmpKindVariable       Variable
  hi! link BlinkCmpKindClass          Type
  hi! link BlinkCmpKindInterface      Type
  hi! link BlinkCmpKindModule         Identifier
  hi! link BlinkCmpKindProperty       Identifier
  hi! link BlinkCmpKindUnit           Constant
  hi! link BlinkCmpKindValue          Constant
  hi! link BlinkCmpKindEnum           Type
  hi! link BlinkCmpKindKeyword        Keyword
  hi! link BlinkCmpKindSnippet        Special
  hi! link BlinkCmpKindColor          Special
  hi! link BlinkCmpKindFile           String
  hi! link BlinkCmpKindReference      Constant
  hi! link BlinkCmpKindFolder         Directory
  hi! link BlinkCmpKindEnumMember     Identifier
  hi! link BlinkCmpKindConstant       Constant
  hi! link BlinkCmpKindStruct         Type
  hi! link BlinkCmpKindEvent          Function
  hi! link BlinkCmpKindOperator       Operator
  hi! link BlinkCmpKindTypeParameter  Identifier

  hi! link FzfLuaBorder         WinSeparator
  hi! link FzfLuaSearch         Search
  call Hi('FzfLuaPathColNr',  { 'fg': magenta })
  call Hi('FzfLuaPathLineNr', { 'fg': green })
  hi! link FzfLuaBufNr          Number
  hi! link FzfLuaBufFlagCur     Conditional
  hi! link FzfLuaBufFlagAlt     Special
  hi! link FzfLuaBufId          Number
  call Hi('FzfLuaTabTitle',   { 'fg': blue,   'attr': 'bold' })
  call Hi('FzfLuaTabMarker',  { 'fg': orange, 'attr': 'bold' })
  hi! link FzfLuaHeaderBind     SpecialKey
  hi! link FzfLuaHeaderText     Function

  hi! link SnacksNormal                   Normal
  hi! link SnacksPicker                   Normal
  hi! link SnacksInputNormal              NormalFloat
  hi! link SnacksPickerInput              NormalFloat
  hi! link SnacksPickerBorder             WinSeparator
  call Hi('SnacksPickerListCursorLine', { 'bg': gray[1], 'attr': 'bold' })
  hi! link SnacksPickerMatch              PmenuMatch
  call Hi('SnacksPickerPrompt',         { 'fg': blue,    'attr': 'bold' })
  call Hi('SnacksPickerInputSearch',    { 'fg': magenta, 'attr': 'bold' })
  hi! link SnacksPickerDir                Directory
  hi! link SnacksPickerBufFlags           Special
  call Hi('SnacksPickerRow',            { 'fg': green })
  call Hi('SnacksPickerCol',            { 'fg': magenta })
  hi! link SnacksPickerDiagnosticCode     PmenuExtra
  hi! link SnacksPickerDiagnosticSource   PmenuExtra

  for [spell_hl, color] in items({
        \ 'SpellBad': red, 'SpellLocal': cyan, 'SpellCap': blue, 'SpellRare': magenta })
    exe 'hi clear' spell_hl
    exe 'hi' spell_hl 'gui=undercurl guisp=' color.gui
    if has('nvim-0.3.2') && $TERM ==# 'xterm-kitty'
      exe 'hi' spell_hl 'cterm=undercurl'
    else
      exe 'hi' spell_hl 'cterm=reverse ctermfg=' color.cterm 'ctermbg=' bg.cterm
    endif
  endfor

  call Hi('Sneak', { 'fg': bg, 'bg': green, 'attr': 'bold' })
  hi! link SneakScope Visual
  hi! link SneakLabel Sneak
  call Hi('SneakCurrent', { 'fg': bg, 'bg': magenta, 'attr': 'bold' })

  " checkhealth UI
  call Hi('healthSuccess', { 'fg': bg, 'bg': green,  'attr': 'bold' })
  call Hi('healthWarning', { 'fg': bg, 'bg': yellow, 'attr': 'bold' })
  call Hi('healthError',   { 'fg': bg, 'bg': red,    'attr': 'bold' })

  " vim tutor
  call Hi('tutorLink', { 'fg': blue, 'attr': 'underline' })

  " Vimspector
  call Hi('vimspectorBP',         { 'fg': red })
  call Hi('vimspectorBPCond',     { 'fg': orange })
  call Hi('vimspectorBPLog',      { 'fg': yellow })
  call Hi('vimspectorBPDisabled', { 'fg': gray[3] })
  exe 'hi clear vimspectorPCLine'
  exe 'hi clear vimspectorPC'
  let line_bg = s:mix_colors(bg, green, 0.1)
  exe 'hi vimspectorPCLine guibg=' line_bg
  exe 'hi vimspectorPC guibg=' line_bg 'guifg=' green.gui 'ctermfg=' green.cterm

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
  hi! link CocSemModDeprecated DiagnosticDeprecated

  if has('nvim')
    " Semantic highlighting of comments messes with the my highlights of TODOs and such
    hi! link CocSemTypeComment NONE
  else
    " Unfortunately, I cannot disable a single type of semantic token in regular Vim.
    hi! link CocSemTypeComment Comment
  endif

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
  let ansi_colors = g:dotfiles#colorscheme#ansi_colors_mapping
  if has('nvim')
    call Hi('TermCursor', { 'attr': 'reverse' })
    for color in range(16)
      let g:terminal_color_{color} = base16[ansi_colors[color]].gui
    endfor
  elseif has('terminal') && (has('gui_running') || &termguicolors)
    call Hi('Terminal', { 'fg': fg, 'bg': bg })
    let g:terminal_ansi_colors = []
    for color in range(16)
      call add(g:terminal_ansi_colors, base16[ansi_colors[color]].gui)
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
  for [diff_hl, color] in items({ 'Add': green, 'Delete': red, 'Text': magenta, 'Change': gray[3] })
    exe 'hi clear Diff'.diff_hl
    exe 'hi Diff'.diff_hl
    \ 'guifg=' (diff_hl ==# 'Delete' ? s:mix_colors(bg, color, 0.32) : 'NONE')
    \ 'guibg=' s:mix_colors(bg, color, diff_hl ==# 'Text' ? 0.24 : 0.08)
    \ 'guisp=' gray[3].gui
    \ 'ctermfg=' color.cterm
    \ 'ctermbg=' gray[1].cterm
  endfor
  " diff file
  hi! link diffAdded       Added
  hi! link diffRemoved     Removed
  hi! link diffChanged     Changed
  hi! link diffNewFile     Added
  hi! link diffOldFile     Removed
  hi! link diffFile        Structure
  hi! link diffIndexLine   Label
  hi! link diffLine        Title
  hi! link diffSubname     Include
  " }}}

  " XML {{{
  hi! link xmlTagName         Tag
  hi! link xmlAttrib          Variable
  hi! link xmlTag             Comment
  hi! link xmlEndTag          Comment
  hi! link xmlAttribPunct     Delimiter
  hi! link xmlProcessingDelim Special
  hi! link xslElement         xmlTagName
  hi! link xmlNamespace       Label
  " }}}

  " Git {{{
  hi! link gitCommitOverflow  ErrorMsg
  hi! link gitCommitSummary   String
  hi! link gitCommitComment   Comment
  hi! link gitcommitUntracked Comment
  hi! link gitcommitDiscarded Comment
  hi! link gitcommitSelected  Comment
  hi! link gitcommitHeader    Keyword
  call Hi('gitcommitSelectedType',  { 'fg': blue })
  call Hi('gitcommitUnmergedType',  { 'fg': blue })
  call Hi('gitcommitDiscardedType', { 'fg': blue })
  hi! link gitcommitBranch Function
  call Hi('gitcommitUntrackedFile', { 'fg': yellow, 'attr': 'bold' })
  call Hi('gitcommitUnmergedFile',  { 'fg': red,    'attr': 'bold' })
  call Hi('gitcommitDiscardedFile', { 'fg': red,    'attr': 'bold' })
  call Hi('gitcommitSelectedFile',  { 'fg': green,  'attr': 'bold' })

  hi! link GitGutterAdd          Added
  hi! link GitGutterDelete       Removed
  hi! link GitGutterChange       Changed
  hi! link GitGutterChangeDelete GitGutterDelete
  hi! link SignifySignAdd        Added
  hi! link SignifySignChange     Changed
  hi! link SignifySignDelete     Removed
  hi! link GitSignsAdd           Added
  hi! link GitSignsDelete        Removed
  hi! link GitSignsTopDelete     GitSignsDelete
  hi! link GitSignsChange        Changed
  hi! link GitSignsChangeDelete  GitSignsChange
  hi! link GitSignsUntracked     GitSignsAdd

  call Hi('fugitiveStagedHeading',   { 'fg': green,  'attr': 'bold' })
  call Hi('fugitiveUnstagedHeading', { 'fg': yellow, 'attr': 'bold' })
  hi! link fugitiveUntrackedHeading fugitiveUnstagedHeading
  " }}}

  " Vim scripts {{{
  hi! link vimVar            Variable     " highlight ALL variables (this makes the code very red)
  hi! link vimVimVar         Special      " special `v:` variables: `v:count`, `v:progpath` etc
  hi! link vimVimVarName     vimVimVar    " the name after `v:`, see |vim-variable|
  hi! link vimVarNameError   Error        " `nonexistent` in `&nonexistent` or `v:nonexistent`
  hi! link vimOptionVar      vimOption    " `&columns`, `&l:spell`, `&g:undofile`, |expr-option|
  hi! link vimOptionVarName  vimOption    " the option name after `&` in |expr-option|

  hi! link vimUserFunc       vimFuncName  " calls to user-defined and autoloaded functions
  hi! link vimFuncVar        Variable     " `arg` and `other` in `:function UserFunc(arg, other)`
  hi! link vimFunctionParam  Variable     " same, but for newer `$VIMRUNTIME/syntax/vim.vim`
  hi! link vimFunctionName   vimFuncName  " `name` in `:function s:name()` with the new syntax file
  hi! link vimLambdaOperator Keyword      " highlight `->` in lambdas like `=>` is in JavaScript

  " A patch[1] was added recently which FINALLY improves highlighting of user
  " function names both in definitions and calls. Before it there wasn't really
  " a syntax group for the name of the function in a `:function` definition, so
  " instead I would just link the whole region that starts after `:function` and
  " ends at the beginning of function arguments.
  " [1]: <https://github.com/vim/vim/commit/51289207f81772592a5a34f1576f2aeb7d5530b7>
  if !(has('nvim-0.12.0') || has('patch-9.1.1455')) | hi! link vimFunction vimFuncName | endif

  hi! link vimBracket        vimMapModKey " highlight `<` and `>` around key names in mappings
  hi! link vimParenSep       Delimiter    " parentheses in function calls and expressions
  hi! link vimSep            Delimiter    " brackets and braces in array and dictionary literals
  hi! link vimScriptDelim    Special      " heredoc markers for `:lua`, `:python` and so on
  hi! link vimCommentString  vimComment   " don't let doubly-quoted strings stand out in comments

  hi! link vimSynType        vimCommand   " `match`/`cluster`/`region`/`case` etc after `:syntax`
  hi! link vimSynOption      Identifier   " `containedin=...`, `skipwhite` and others in `:syntax`
  hi! link vimSynReg         vimSynOption " `start=...` and `end=...` in `:syntax region ...`
  hi! link vimSynKeyRegion   vimString    " `keepend` in `:syntax region ...`
  hi! link vimSyncLines      vimSynOption " keyword strings in `:syntax keyword ...`
  hi! link vimGroupName      vimGroup     " custom hlgroups in `:hi` commands after Nvim v0.12.0
  hi! link vimGroupList      vimGroup     " hlgroup names in various places in `:syntax` commands
  hi! link vimHiTerm         Identifier   " `term` in `hi Group term=bold` (any `:hi` option, really)
  hi! link vimHiAttrib       Constant     " `bold` in `hi Group term=bold`

  " <https://github.com/vim/vim/commit/ddbb6fe2d0344e93436c5602b7a06169f49a9b52>
  if has('nvim-0.11.0') || has('patch-9.1.0613')
    hi! link vimSetEqual       vimString    " `make` in `setl ft=make` and `F` in `set shortmess+=F`
    hi! link vimSetEscape      vimEscape    " see |option-backslash|
    hi! link vimSetBarEscape   vimSetEscape " `\|` in `:set ...`
    hi! link vimSetQuoteEscape vimSetEscape " `\"` in `:set ...`
  endif

  hi! link vimSetMod         Special      " `&vim` in `set cpo&vim` and `&` in `set fillchars&`
  hi! link vimBang           Special      " `!` after all sorts of commands. Make it stand out.
  hi! link vimCatchPattern   vimString    " `pat` in `:catch /pat/`
  hi! link vimAugroupEnd     Special      " `END` in `augroup END`
  hi! link vimSpecFile       Special      " `<sfile>`, `%:h`, `#` etc
  " }}}

  " C {{{
  hi! link cOperator Special
  hi! link cFormat   PreProc
  " }}}

  " C++ {{{
  hi! link cppOperator Keyword
  " }}}

  " Rust {{{
  hi! link rustEnumVariant    Function
  hi! link rustSelf           Variable
  hi! link rustSigil          rustOperator
  hi! link rustMacroVariable  Variable
  hi! link rustModPath        Identifier
  hi! link rustCommentLineDoc Comment
  " }}}

  " HTML {{{
  hi! link htmlBold           Bold
  hi! link htmlItalic         Italic
  hi! link htmlStrike         Strikethrough
  call Hi('htmlBoldItalic', { 'fg': magenta, 'attr': 'bold,italic' })
  hi! link htmlH1             Identifier
  hi! link htmlTag            xmlTag
  hi! link htmlTagName        xmlTagName
  hi! link htmlSpecialTagName PreProc
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
  hi! link jsFuncArgs          Variable
  hi! link jsFuncArgOperator   Operator
  hi! link jsVariableDef       Variable
  hi! link jsDocParam          Identifier
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
  hi! link typescriptFuncCallArg         NONE
  " }}}

  " Markdown {{{
  hi! link markdownBoldDelimiter   Delimiter
  hi! link markdownItalicDelimiter Delimiter
  hi! link markdownCode            String
  hi! link markdownCodeDelimiter   markdownCode
  hi! link markdownUrl             htmlString
  hi! link markdownAutomaticLink   htmlLink
  call Hi('mkdBlockquote', { 'fg': gray[4] })
  hi! link mkdLinkDef    TypeDef
  hi! link mkdID         Type
  hi! link mkdRule       PreProc
  hi! link mkdHeading    Keyword
  hi! link mkdBold       htmlBold
  hi! link mkdItalic     htmlItalic
  hi! link mkdBoldItalic htmlBoldItalic
  hi! link mkdStrike     htmlStrike
  " }}}

  " Mail {{{
  for color in range(6)
    call Hi('mailQuoted' . (color + 1), { 'fg': base16[0x8 + color] })
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
  hi! link pythonStrFormat   PreProc
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
  hi! link luaFuncName       Function
  hi! link luaFuncId         NONE
  hi! link luaBraces         Delimiter
  hi! link luaFunction       Keyword
  hi! link luaSymbolOperator Operator
  hi! link luaOperator       Keyword
  hi! link luaLocal          StorageClass
  hi! link luaSpecialTable   PreProc
  hi! link luaSpecialValue   PreProc
  hi! link luaErrHand        PreProc
  hi! link luaFunc           PreProc
  hi! link luaFuncArgName    Variable
  hi! link luaBuiltIn        Special
  hi! link luaStringLongTag  luaStringLong
  hi! link luaIn             luaOperator
  hi! link luaDocTag         Special
  " }}}

  " Shell {{{
  " <https://github.com/lunacookies/vim-sh/blob/cebda390c56654a4c9f96f66727e9be076a7aee3/syntax/sh.vim#L32-L50>
  hi! link shQuote        StringDelimiter
  hi! link zshFunction    Function
  hi! link zshVariable    Variable
  hi! link shArithmetic   NONE
  hi! link shCommandSub   NONE
  hi! link shForPP        NONE
  hi! link shTestOpr      Operator
  hi! link shEscape       Special
  hi! link shOption       Special
  hi! link zshOption      Special
  hi! link shCaseLabel    String
  hi! link shFor          Variable
  hi! link zshPrecommand  Statement
  hi! link shFunctionKey  Statement
  hi! link zshDeref       Variable
  hi! link shDerefSimple  Variable
  hi! link shOperator     Operator
  hi! link zshOperator    Operator
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

  " Java {{{
  hi! link javaOperator       Keyword
  hi! link javaC_             Type
  hi! link javaDocParam       Label
  hi! link javaDocSeeTagParam Label
  " }}}

  " C# {{{
  hi! link csNewType Type
  " }}}

  " Golang {{{
  hi! link goFunctionCall Function
  hi! link goBuiltins     Special
  hi! link goVarAssign    NONE
  hi! link goVarDefs      NONE
  " }}}

  " lfrc {{{
  hi! link lfIgnore NONE
  " }}}

endfunction

call s:setup()
