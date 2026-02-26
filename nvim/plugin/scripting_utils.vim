function! Hex(n) abort
  return printf('%x', a:n)
endfunction

function! Bin(n) abort
  return printf('%b', a:n)
endfunction

function! Oct(n) abort
  return printf('%o', a:n)
endfunction

" Colllect the output of an Ex command and display it in a new window.
command! -nargs=+ -complete=command CollectOutput
  \ silent! let s:output = execute(<q-args>) |
  \ new |
  \ setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nomodeline |
  \ setlocal nospell nofoldenable colorcolumn= |
  \ call append(1, split(s:output, "\n")) | 1 delete _ |
  \ unlet s:output

" Same as typing Ex commands literally, but creating local variables doesn't
" pollute the global scope.
command! -nargs=+ -complete=command LocalScope call s:execute_with_local_scope(<q-args>)

function! s:execute_with_local_scope(cmd) abort
  execute a:cmd
endfunction

" Measure execution time of an Ex command.
command! -nargs=+ -complete=command -count=1 Timeit
  \ let s:repeats = <count>
  \|if s:repeats > 1
  \|  let s:start_time = reltime()
  \
  \|  while s:repeats > 0
  \|    execute <q-args>
  \|    let s:repeats -= 1
  \|  endwhile
  \
  \|  let s:elapsed = reltimefloat(reltime(s:start_time)) / <count>
  \|else
  \|  execute 'let s:start_time = reltime() |' <q-args>
  \|  let s:elapsed = reltimefloat(reltime(s:start_time))
  \|endif
  \
  \|if abs(s:elapsed) < 0.001
  \|  echo printf('%f μs', s:elapsed * 1000000)
  \|elseif abs(s:elapsed) < 1.0
  \|  echo printf('%f ms', s:elapsed * 1000)
  \|else
  \|  echo printf('%f s', s:elapsed)
  \|endif
  \
  \|unlet s:start_time s:repeats s:elapsed
