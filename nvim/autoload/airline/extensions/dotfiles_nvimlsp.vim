" NvimLSP-through-CoC
"
" Airline's built-in `nvimlsp` extension doesn't display progress and some
" other things (such as line number of the first error/warning), hence I
" decided to roll my own (as usual). On the other hand, Airline creates
" components for `nvimlsp` diagnostics, but not for the status. So, instead of
" copying the lists of components in every section into my configs
" (<https://github.com/vim-airline/vim-airline/blob/05bd105cabf2cf1ab1cc3edeb6988423d567d8b4/autoload/airline/init.vim#L209-L250>)
" I hijack the components intended for coc.nvim, which won't be loaded anyway.
"
" The code is based on:
" <https://github.com/vim-airline/vim-airline/blob/0cfd829c92a6fd208bfdcbdd2881105462224636/autoload/airline/extensions/nvimlsp.vim>
" <https://github.com/vim-airline/vim-airline/blob/0cfd829c92a6fd208bfdcbdd2881105462224636/autoload/airline/extensions/coc.vim>
" <https://github.com/vim-airline/vim-airline/blob/0cfd829c92a6fd208bfdcbdd2881105462224636/autoload/airline/extensions/lsp.vim>

if !(has('nvim') && exists('*luaeval') && luaeval('vim.lsp ~= nil')) | finish | endif

function! airline#extensions#dotfiles_nvimlsp#init(ext) abort
  call airline#parts#define_function('coc_error_count', 'airline#extensions#dotfiles_nvimlsp#get_error')
  call airline#parts#define_function('coc_warning_count', 'airline#extensions#dotfiles_nvimlsp#get_warning')
  call airline#parts#define_function('coc_status', 'airline#extensions#dotfiles_nvimlsp#get_progress')
  lua <<EOF
    local lsp_diagnostics = require('dotfiles.lsp.diagnostics')
    function dotfiles._airline_extension_on_diagnostics_changed()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local stats = lsp_diagnostics.get_severity_stats_for_statusline(bufnr)
        if stats then
          pcall(vim.api.nvim_buf_set_var, bufnr, 'dotfiles_airline_lsp_diagnostics_stats', stats)
        else
          pcall(vim.api.nvim_buf_del_var, bufnr, 'dotfiles_airline_lsp_diagnostics_stats')
        end
      end
    end
EOF
  augroup dotfiles_airline_nvimlsp_progress
    autocmd!
    autocmd User LspProgressUpdate redrawstatus
    autocmd User LspDiagnosticsChanged call v:lua.dotfiles._airline_extension_on_diagnostics_changed()
    autocmd User LspDiagnosticsChanged redrawstatus
    if exists('#DiagnosticChanged')
      autocmd DiagnosticChanged * call v:lua.dotfiles._airline_extension_on_diagnostics_changed()
      autocmd DiagnosticChanged * redrawstatus
    endif
  augroup END
endfunction

let s:diagnostic_symbols = {
\ 'Error': get(g:, 'airline#extensions#dotfiles_nvimlsp#error_symbol', 'E:'),
\ 'Warning': get(g:, 'airline#extensions#dotfiles_nvimlsp#warning_symbol', 'W:'),
\ }

function! airline#extensions#dotfiles_nvimlsp#get_diagnostics(severity) abort
  let stats = get(b:, 'dotfiles_airline_lsp_diagnostics_stats', v:null)
  if stats isnot# v:null
    let cnt = stats.count[a:severity]
    if cnt > 0
      let lnum = stats.first_line[a:severity]
      return printf('%s%d(L%d)', get(s:diagnostic_symbols, a:severity), cnt, lnum)
    endif
  endif
  return ''
endfunction

function! airline#extensions#dotfiles_nvimlsp#get_warning() abort
  return airline#extensions#dotfiles_nvimlsp#get_diagnostics('Warning')
endfunction

function! airline#extensions#dotfiles_nvimlsp#get_error() abort
  return airline#extensions#dotfiles_nvimlsp#get_diagnostics('Error')
endfunction

function! airline#extensions#dotfiles_nvimlsp#get_progress() abort
  return printf(' %.3fMB %s', v:lua.vim.loop.resident_set_memory() / 1024.0 / 1024.0, luaeval('require("dotfiles.lsp.progress").get_status_text()'))
endfunction
