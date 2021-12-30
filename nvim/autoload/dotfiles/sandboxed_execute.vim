" Has to be the only thing in its own module, so that it is impossible for
" user's snippets to break variables in the script-local scope.
function! dotfiles#sandboxed_execute#(cmd) abort
  execute a:cmd
endfunction

function! dotfiles#sandboxed_execute#capture(cmd) abort
  return execute(a:cmd)
endfunction
