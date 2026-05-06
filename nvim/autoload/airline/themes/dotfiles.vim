function! s:pair(fg, bg) abort
  return [a:fg.gui, a:bg.gui, a:fg.cterm, a:bg.cterm]
endfunction

function! s:make_palette() abort
  let palette = {}

  let base16 = g:dotfiles#colorscheme#base16_colors
  let [red, orange, yellow, green, cyan, blue, magenta, brown] = base16[8:15]
  let gray = base16[0:7]

  let section_a = s:pair(gray[1], green)
  let section_b = s:pair(gray[6], gray[2])
  let section_c = s:pair(orange, gray[1])
  let palette.normal = airline#themes#generate_color_map(section_a, section_b, section_c)

  let inactive  = s:pair(gray[5], gray[1])
  let palette.inactive = airline#themes#generate_color_map(inactive, inactive, inactive)

  for [mode, color] in items({
  \ 'insert'      : s:pair(gray[1], blue),
  \ 'visual'      : s:pair(gray[1], magenta),
  \ 'replace'     : s:pair(gray[1], red),
  \ 'terminal'    : s:pair(gray[1], blue),
  \ 'commandline' : s:pair(gray[1], cyan),
  \ })
    let palette[mode] = { 'airline_a': color, 'airline_z': color }
  endfor

  for mode in keys(palette)
    call extend(palette[mode], {
    \ 'airline_warning': s:pair(gray[0], yellow),
    \ 'airline_error':   s:pair(gray[0], red),
    \ 'airline_term':    s:pair(orange, gray[1]),
    \ })
  endfor

  let palette.accents = map(
  \ { 'red': red, 'green': green, 'blue': blue, 'yellow': yellow, 'orange': orange, 'purple': magenta },
  \ '[v:val.gui, "", v:val.cterm, ""]')

  return palette
endfunction

let airline#themes#dotfiles#palette = s:make_palette()
