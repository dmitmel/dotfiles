if !exists('g:dotfiles_boot_reltime')
  let g:dotfiles_boot_reltime = reltime()
  let g:dotfiles_boot_localtime = localtime()
endif

let g:nvim_dotfiles_dir = expand('<sfile>:p:h')
let g:dotfiles_dir = expand('<sfile>:p:h:h')

let g:vim_ide = get(g:, 'vim_ide', 0)
let g:dotfiles_build_coc_from_source = get(g:, 'dotfiles_build_coc_from_source', 0)

function! s:configure_runtimepath() abort
  " NOTE: Vim actually might handle escaping of commas in RTP and such if you
  " write `^,` or something, but honestly I don't want to think about that too
  " hard. Even vim-plug doesn't care about that.
  let rtp = split(&runtimepath, ',')
  let dotf = g:nvim_dotfiles_dir
  if index(rtp, dotf         ) < 0 | call insert(rtp, dotf         ) | endif
  if index(rtp, dotf.'/after') < 0 | call    add(rtp, dotf.'/after') | endif
  let &runtimepath = join(rtp, ',')
endfunction
call s:configure_runtimepath()

" Indent detection hack, stage 1 {{{
" HACK: Set `shiftwidth` to something unreasonable to make Polyglot's built-in
" indentation detector believe that it's the "default" value. The problem
" comes from the fact that Polyglot bundles vim-sleuth, but executes it in an
" autoload script, which is loaded by an ftdetect script, which is... loaded
" when vim-plug invokes `filetype on`. Thus vim-sleuth is loaded way before
" the primary chunk of my configuration is loaded, so it won't see my
" preferred indentation value, save 8 (Vim's default) to a local variable
" `s:default_shiftwidth` and always assume that some ftplugin explicitly
" modified the shiftwidth to 2 (my real default value) for that particular
" filetype. So instead I use a classic approach to rectify the problem:
" ridiculously hacky workarounds. In any case, blame this commit:
" <https://github.com/sheerun/vim-polyglot/commit/113f9b8949643f7e02c29051ad2148c3265b8131>.
let s:fake_default_shiftwidth = 0
let &shiftwidth = s:fake_default_shiftwidth
" }}}

call dotfiles#plugman#auto_install()
call dotfiles#plugman#begin()
runtime! dotfiles/plugins-list.vim
call dotfiles#plugman#end()
" Automatically install/clean plugins (because I'm a programmer)
autocmd VimEnter * call dotfiles#plugman#check_sync()

" NOTE: What the following block does is effectively source the files
" `filetype.vim`, `ftplugin.vim`, `indent.vim`, `syntax/syntax.vim` from
" `$VIMRUNTIME` IN ADDITION TO sourcing the plugin scripts, `plugin/**/*.vim`.
" The last bit is very important because the rest of vimrc runs in a world when
" all plugins have been initialized, and so adjustments to e.g. autocommands
" are possible.
if has('autocmd') && !(exists('g:did_load_filetypes') && exists('g:did_load_ftplugin') && exists('g:did_indent_on'))
  filetype plugin indent on
endif
if has('syntax') && !exists('g:syntax_on')
  syntax enable
endif

" Indent detection hack, stage 2 {{{
if exists(':Sleuth')
  " HACK: Continuation of the indentation detection hack. Here I first destroy
  " Polyglot's vim-sleuth's autocommands, fortunately there is just one, which
  " calls `s:detect_indent()` on `BufEnter`. And also registration into tpope's
  " statusline plugin, which I don't use, therefore I don't care.
  augroup polyglot-sleuth
    autocmd!
    " HACK: Now I install my own autocommand, which first resets the local
    " shiftwidth to the unreasonable value picked above, which vim-sleuth
    " internally compares with its local `s:default_shiftwidth`, sees that both
    " are the same, and proceeds to execute the indent detection algorithm.
    " ALSO Note how I'm not using `BufEnter` as vim-sleuth does because
    " apparently `BufWinEnter` leads to better compatibility with the
    " indentLine plugin and potentially less useless invocations (see the note
    " about window splits in the docs for this event). Oh, one last thing:
    " vim-sleuth forgets to assign the tabstop options, which I have to do as
    " well. But anyway, boom, my work here is done.
    autocmd BufWinEnter *
      \  let &l:shiftwidth = s:fake_default_shiftwidth
      \| Sleuth
      \| let &l:tabstop = &l:shiftwidth
      \| let &l:softtabstop = &l:shiftwidth
  augroup END

  " HACK: In case you are wondering why I'm using Polyglot's bundled vim-sleuth
  " given that it requires those terrible hacks to function normally and respect
  " my configs, and not something like <https://github.com/idbrii/detectindent>
  " (this is a fork I used to use and which checks syntax groups to improve
  " detection quality). ...Well, frankly, even though vim-sleuth's detector uses
  " unreliable (at first glance) regex heuristics, in practice it still works
  " better than detectindent's syntax group querying.
endif
" }}}

colorscheme dotfiles
