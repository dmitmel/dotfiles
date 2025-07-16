" This script will be executed for `html` and for every filetype derived from `html`.
" This code needs to be located in a file that is loaded earlier than the ftplugins of vim-matchup.
if exists('g:matchup_matchpref')
  let g:matchup_matchpref[&filetype] = { 'tagnameonly': 1, 'nolists': 1 }
endif
