let s:palette = {
\ "inactive"    : {},
\ "replace"     : {},
\ "normal"      : {},
\ "visual"      : {},
\ "insert"      : {},
\ "terminal"    : {},
\ "commandline" : {},
\ }

let s:colors = g:dotfiles_colorscheme_base16_colors
function! s:base16_color(fg, bg)
  let fg = s:colors[a:fg]
  let bg = s:colors[a:bg]
  return [fg.gui, bg.gui, fg.cterm, bg.cterm]
endfunction

let s:section_a = s:base16_color(0x1, 0xB)
let s:section_b = s:base16_color(0x6, 0x2)
let s:section_c = s:base16_color(0x9, 0x1)
let s:palette.normal = airline#themes#generate_color_map(
\ s:section_a,
\ s:section_b,
\ s:section_c)

let s:section_a_overrides = {
\ 'insert'      : s:base16_color(0x1, 0xD),
\ 'visual'      : s:base16_color(0x1, 0xE),
\ 'replace'     : s:base16_color(0x1, 0x8),
\ 'terminal'    : s:base16_color(0x1, 0xD),
\ 'commandline' : s:base16_color(0x1, 0xC),
\ }
for [s:mode, s:color] in items(s:section_a_overrides)
  let s:palette[s:mode] = { 'airline_a': s:color, 'airline_z': s:color }
endfor

let s:section_inactive = s:base16_color(0x5, 0x1)
let s:palette.inactive = airline#themes#generate_color_map(
\ s:section_inactive,
\ s:section_inactive,
\ s:section_inactive)

if get(g:, 'loaded_ctrlp', 0)
  let s:ctrlp_dark  = s:base16_color(0x7, 0x2)
  let s:ctrlp_light = s:base16_color(0x7, 0x4)
  let s:ctrlp_white = s:base16_color(0x5, 0x1) + ['bold']
  let s:palette.ctrlp = airline#extensions#ctrlp#generate_color_map(
  \ s:ctrlp_dark,
  \ s:ctrlp_light,
  \ s:ctrlp_white)
endif

for s:mode in keys(s:palette)
  let s:palette[s:mode]['airline_warning'] = s:base16_color(0x0, 0xA)
  let s:palette[s:mode]['airline_error']   = s:base16_color(0x0, 0x8)
  let s:palette[s:mode]['airline_term']    = s:base16_color(0x9, 0x1)
endfor

let airline#themes#dotfiles#palette = s:palette
