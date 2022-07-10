autocmd BufNewFile,BufRead *
\ if !did_filetype() && expand("<amatch>") !~ g:ft_ignore_pat && getline(1) =~ '^<?xml' |
\   setf xml |
\ endif
