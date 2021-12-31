" Has to be the only thing in its own module, so that it is impossible for
" user's snippets to break variables in the script-local scope.
function! dotfiles#sandboxed_execute#(cmd) abort
  execute a:cmd
endfunction

function! dotfiles#sandboxed_execute#capture(cmd) abort
  return execute(a:cmd)
endfunction

" Time measurement functions have to be called here so that the impact on the
" results from making an autoloaded function call is minimal.
function! dotfiles#sandboxed_execute#timeit(cmd) abort
  let s:start_time = reltime()
  execute a:cmd
  let elapsed = reltime(s:start_time)
  unlet s:start_time
  return elapsed
endfunction
