local theme = {}
theme.base16_name = "eighties"
theme.is_dark = true
---@type table<number, { gui: number, cterm: number, r: number, g: number, b: number }>
local colors = {
  [ 0] = { gui = 0x2d2d2d, cterm =  0, r = 0x2d, g = 0x2d, b = 0x2d },
  [ 1] = { gui = 0x393939, cterm = 18, r = 0x39, g = 0x39, b = 0x39 },
  [ 2] = { gui = 0x515151, cterm = 19, r = 0x51, g = 0x51, b = 0x51 },
  [ 3] = { gui = 0x747369, cterm =  8, r = 0x74, g = 0x73, b = 0x69 },
  [ 4] = { gui = 0xa09f93, cterm = 20, r = 0xa0, g = 0x9f, b = 0x93 },
  [ 5] = { gui = 0xd3d0c8, cterm =  7, r = 0xd3, g = 0xd0, b = 0xc8 },
  [ 6] = { gui = 0xe8e6df, cterm = 21, r = 0xe8, g = 0xe6, b = 0xdf },
  [ 7] = { gui = 0xf2f0ec, cterm = 15, r = 0xf2, g = 0xf0, b = 0xec },
  [ 8] = { gui = 0xf2777a, cterm =  1, r = 0xf2, g = 0x77, b = 0x7a },
  [ 9] = { gui = 0xf99157, cterm = 16, r = 0xf9, g = 0x91, b = 0x57 },
  [10] = { gui = 0xffcc66, cterm =  3, r = 0xff, g = 0xcc, b = 0x66 },
  [11] = { gui = 0x99cc99, cterm =  2, r = 0x99, g = 0xcc, b = 0x99 },
  [12] = { gui = 0x66cccc, cterm =  6, r = 0x66, g = 0xcc, b = 0xcc },
  [13] = { gui = 0x6699cc, cterm =  4, r = 0x66, g = 0x99, b = 0xcc },
  [14] = { gui = 0xcc99cc, cterm =  5, r = 0xcc, g = 0x99, b = 0xcc },
  [15] = { gui = 0xd27b53, cterm = 17, r = 0xd2, g = 0x7b, b = 0x53 },
}
theme.base16_colors = colors
theme.ansi_colors = {
  colors[0],
  colors[8],
  colors[11],
  colors[10],
  colors[13],
  colors[14],
  colors[12],
  colors[5],
  colors[3],
  colors[8],
  colors[11],
  colors[10],
  colors[13],
  colors[14],
  colors[12],
  colors[7],
  colors[9],
  colors[15],
  colors[1],
  colors[2],
  colors[4],
  colors[6],
}
theme.bg = colors[0]
theme.fg = colors[5]
theme.cursor_bg = colors[5]
theme.cursor_fg = colors[0]
theme.selection_bg = colors[2]
theme.selection_fg = colors[5]
theme.link_color = colors[12]
---@type table<number, number>
theme.ansi_to_base16_mapping = {0x0, 0x8, 0xB, 0xA, 0xD, 0xE, 0xC, 0x5, 0x3, 0x8, 0xB, 0xA, 0xD, 0xE, 0xC, 0x7, 0x9, 0xF, 0x1, 0x2, 0x4, 0x6}
---@type table<number, number>
theme.base16_to_ansi_mapping = {0x00, 0x12, 0x13, 0x08, 0x14, 0x07, 0x15, 0x0F, 0x01, 0x10, 0x03, 0x02, 0x06, 0x04, 0x05, 0x11}
return theme
