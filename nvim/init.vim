let g:nvim_dotfiles_dir = expand('<sfile>:p:h')
let g:dotfiles_dir = expand('<sfile>:p:h:h')

let g:vim_ide = get(g:, 'vim_ide', 0)
let g:vim_ide_treesitter = get(g:, 'vim_ide_treesitter', 0)

let &runtimepath = g:nvim_dotfiles_dir.','.&runtimepath.','.g:nvim_dotfiles_dir.'/after'


let s:vim_config_dir = stdpath("config")
let s:vim_plug_script = s:vim_config_dir . '/autoload/plug.vim'
let s:vim_plug_home = s:vim_config_dir . '/plugged'

let s:just_installed_vim_plug = 0
if !filereadable(s:vim_plug_script)
  execute '!curl -fL https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim --create-dirs -o' shellescape(s:vim_plug_script)
  autocmd VimEnter * PlugInstall --sync
endif

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

call plug#begin(s:vim_plug_home)
Plug 'junegunn/vim-plug'
runtime! dotfiles/plugins-list.vim
call plug#end()
if g:vim_ide_treesitter
  runtime! dotfiles/treesitter.vim
endif

" Automatically install/clean plugins (because I'm a programmer) {{{
  augroup vimrc-plugins
    autocmd!
    autocmd VimEnter *
      \  if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
      \|   PlugInstall --sync | q
      \| endif
  augroup END
" }}}

colorscheme dotfiles

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
