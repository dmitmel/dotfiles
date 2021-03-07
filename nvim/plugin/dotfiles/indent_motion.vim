for [s:plug_mapping, s:direction, s:user_mapping] in [["prev", -1, "("], ["next", 1, ")"]]
  let s:plug_mapping = "<Plug>dotfiles_indent_motion_".s:plug_mapping
  for s:mode in ["n", "v", "o"]
    execute s:mode."noremap" "<silent>" s:plug_mapping "<Cmd>call dotfiles#indent_motion#run(".s:direction.")<CR>"
    if !empty(s:user_mapping)
      execute s:mode."map" s:user_mapping s:plug_mapping
    endif
  endfor
endfor
