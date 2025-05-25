" <https://stackoverflow.com/a/7212314/12005228>
exe dotfiles#ft#set('&makeprg', 'awk --lint --source "BEGIN{exit(0)}END{exit(0)}" --file %:S')
" <https://github.com/WolfgangMehner/vim-plugins/blob/a673942f0b7fe9cbbb19282ee4c3ebe5decf2a1d/plugin/awk-support.vim#L570>
exe dotfiles#ft#set('&errorformat', 'awk: %f:%l: %m')
