let s:palette = {}

let s:colors = g:dotfiles_colorscheme_base16_colors
function! s:base16_color(fg, bg)
  let l:fg = s:colors[a:fg]
  let l:bg = s:colors[a:bg]
  return [l:fg.gui, l:bg.gui, l:fg.cterm, l:bg.cterm]
endfunction

let s:section_a = s:base16_color(0x1, 0xB)
let s:section_b = s:base16_color(0x6, 0x2)
let s:section_c = s:base16_color(0x9, 0x1)
let s:palette.normal = airline#themes#generate_color_map(
\ s:section_a,
\ s:section_b,
\ s:section_c)

let s:section_a_overrides = {
\ 'insert' : s:base16_color(0x1, 0xD),
\ 'replace': s:base16_color(0x1, 0x8),
\ 'visual' : s:base16_color(0x1, 0xE),
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

let airline#themes#dotfiles#palette = s:palette
