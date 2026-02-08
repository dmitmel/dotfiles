let s:DIRECTION_TO_AXIS = { 'h': ['row', -1], 'j': ['col', 1], 'k': ['col', -1], 'l': ['row', 1] }

function! dotfiles#splits#navigate(direction) abort
  let [axis, step] = s:DIRECTION_TO_AXIS[a:direction]

  if !exists('*winlayout')
    execute 'wincmd' a:direction
    return
  endif

  let layout = winlayout()
  let winid = win_getid()
  let path = s:find_window_in_layout(winid, layout)
  if empty(path)
    execute 'wincmd' a:direction
    return
  endif

  let neighbors = []
  for node in path
    if node[0] is# axis
      let children = node[1]
      let pos = index(children, l:prev_node) + step
      if 0 <= pos && pos < len(children)
        call s:find_neighbors_on_axis(children[pos], axis, step, neighbors)
        if !empty(neighbors)
          break
        endif
      endif
    endif
    let l:prev_node = node
  endfor

  if len(neighbors) == 1
    call win_gotoid(neighbors[0])
  elseif !empty(neighbors)
    let min_time = 0
    let min_winid = 0
    for winid in neighbors
      let time = getwinvar(winid, 'dotfiles_last_visit_time')
      if time > min_time || min_winid == 0
        let min_time = time
        let min_winid = winid
      endif
    endfor
    call win_gotoid(min_winid)
  endif
endfunction

function! s:find_neighbors_on_axis(node, axis, step, out) abort
  let [type, children] = a:node
  if type is# 'leaf'
    call add(a:out, children)
  elseif type is# a:axis
    let nearest_node = children[a:step < 0 ? -1 : 0]
    call s:find_neighbors_on_axis(nearest_node, a:axis, a:step, a:out)
  else
    for node in children
      call s:find_neighbors_on_axis(node, a:axis, a:step, a:out)
    endfor
  endif
endfunction

function! s:find_window_in_layout(id, layout) abort
  let [type, children] = a:layout
  if type is# 'leaf'
    return children is# a:id ? [a:layout] : 0
  endif

  for node in children
    let path = s:find_window_in_layout(a:id, node)
    if !empty(path)
      call add(path, a:layout)
      return path
    endif
  endfor
  return 0
endfunction
