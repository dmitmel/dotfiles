let s:palette = {}

let s:colors = g:dotfiles#colorscheme#base16_colors
function! s:base16(fg, bg) abort
  let fg = s:colors[a:fg]
  let bg = s:colors[a:bg]
  return [fg.gui, bg.gui, fg.cterm, bg.cterm]
endfunction

let s:section_a = s:base16(0x1, 0xB)
let s:section_b = s:base16(0x6, 0x2)
let s:section_c = s:base16(0x9, 0x1)
let s:palette.normal = airline#themes#generate_color_map(s:section_a, s:section_b, s:section_c)

let s:inactive  = s:base16(0x5, 0x1)
let s:palette.inactive = airline#themes#generate_color_map(s:inactive, s:inactive, s:inactive)

for [s:mode, s:color] in items({
\ 'insert'      : s:base16(0x1, 0xD),
\ 'visual'      : s:base16(0x1, 0xE),
\ 'replace'     : s:base16(0x1, 0x8),
\ 'terminal'    : s:base16(0x1, 0xD),
\ 'commandline' : s:base16(0x1, 0xC),
\ })
  let s:palette[s:mode] = { 'airline_a': s:color, 'airline_z': s:color }
endfor

for s:mode in keys(s:palette)
  call extend(s:palette[s:mode], {
  \ 'airline_warning': s:base16(0x0, 0xA),
  \ 'airline_error':   s:base16(0x0, 0x8),
  \ 'airline_term':    s:base16(0x9, 0x1),
  \ })
endfor

let airline#themes#dotfiles#palette = s:palette
