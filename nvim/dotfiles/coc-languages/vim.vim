" This plugin ended up being useless.
finish

call dotutils#add_unique(g:coc_global_extensions, 'coc-vimlsp')

let g:coc_user_config['vimlsp'] = {
\ 'suggest.fromRuntimepath': v:true,
\ }

" The coc-vimlsp plugin is basically reimplemented here because it doesn't do
" much beyond just wrapping the language server and passing some init options,
" but having two processes (plugin+LSP) almost doubles the memory usage.
"
" On a second thought... Apparently that's just how this extension works...
" Either way it spawns two processes (with the controller process having
" roughly the same memory usage regardless of being in a coc extension). And
" having updates through :CocUpdate is nice, so I'm gonna use the coc-vimlsp
" plugin itself. The janky reimplementation is left in this file for better
" times and bragging purposes.
finish

" <https://github.com/iamcco/coc-vimlsp/blob/38beb0033c24a50e306343282acb071ffae6eed4/src/index.ts#L47-L82>
" workspace.isNvim: <https://github.com/neoclide/coc.nvim/blob/1c25102840e1d6d36bca9db8114e8a56f480afc4/autoload/coc/util.vim#L539>
let g:coc_user_config['languageserver.vimls'] = {
\ 'filetypes': ['vim'],
\ 'command': 'vim-language-server',
\ 'args': ['--stdio'],
\ 'initializationOptions': {
\   'isNeovim': has('nvim'),
\   'iskeyword': &iskeyword,
\   'vimruntime': $VIMRUNTIME,
\   'runtimepath': &runtimepath,
\   'suggest.fromRuntimepath': v:true,
\   },
\ }

augroup dotfiles_coc_vimls
  autocmd!

  " NOTE: Apparently delaying runtimepath initialization even until VimEnter
  " is not enough, as coc-snippets adds its plugin to rtp during coc
  " intialization phase which happens sometime after VimEnter[1]. Although,
  " judging by the coc source code, custom language servers are initialized
  " just before activation of extensions[2], and coc-snippets adds its plugin
  " to rtp in the activation phase[3], so this might be reasonable for us.
  " [1]: <https://github.com/neoclide/coc.nvim/blob/1c25102840e1d6d36bca9db8114e8a56f480afc4/src/attach.ts#L111-L115>
  " [2]: <https://github.com/neoclide/coc.nvim/blob/1c25102840e1d6d36bca9db8114e8a56f480afc4/src/plugin.ts#L445-L446>
  " [3]: <https://github.com/neoclide/coc-snippets/blob/053311a0d9edcc88b9dc0a8e8375dd82b7705f61/src/index.ts#L102>
  autocmd VimEnter * let g:coc_user_config['languageserver.vimls.initializationOptions.runtimepath'] = &runtimepath

  autocmd User CocNvimInit call CocNotify('vimls', '$/change/iskeyword', &iskeyword)
  autocmd OptionSet iskeyword call CocNotify('vimls', '$/change/iskeyword', v:option_new)
augroup END
