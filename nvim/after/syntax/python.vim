let s:saved_syntax = b:current_syntax
unlet! b:current_syntax
syntax include @SQL syntax/sql.vim
syntax case match
let b:current_syntax = s:saved_syntax
unlet! s:saved_syntax

" <https://github.com/sublimehq/Packages/blob/759d6eed9b4beed87e602a23303a121c3a6c2fb3/Python/Python.sublime-syntax#L39>
" <https://github.com/neovim/neovim/blob/7f93b2ab01c93720820712a3c81462a58d04dfa0/runtime/syntax/python.vim#L123-L135>
" <https://github.com/sheerun/vim-polyglot/blob/4d4aa5fe553a47ef5c5c6d0a97bb487fdfda2d5b/syntax/python.vim#L165-L251>
" <https://thegreata.pe/articles/2020/07/11/vim-syntax-highlighting-for-sql-strings-inside-python-code/>
" <https://github.com/gbishop/vim-python-sql/blob/6ba46ec3c5b87b3d60617dac9d468ea40897ad0c/after/syntax/python.vim>
" <https://stackoverflow.com/questions/35868798/vim-higlight-sql-inside-python-triple-quote-string>
" <https://gist.github.com/mdzhang/eaab47b323d49feb5db81a3b92fc128c/18c9416627c667efd71255bb61c03967fa744c55>
" <https://github.com/MathSquared/vim-python-sql/commit/67ed65351b3024821770efd9dc28a100f9034225>
syn region pythonSqlString start=/\v\C\z("""|''')\zs\_s*<(sql|SQL|SELECT|INSERT|UPSERT|UPDATE|SET|DELETE|CREATE|REPLACE|ALTER|WITH|DROP|TRUNCATE|PRAGMA)>/ end=/\ze\z1/ contains=@SQL contained containedin=pythonString,pythonFString,pythonRawString,pythonRawFString

syn keyword pythonOperatorKeyword and in is not or
hi def link pythonOperatorKeyword Keyword
syn cluster pythonExpression add=pythonOperatorKeyword

if hlexists('pythonTodo')
  syn clear pythonTodo
  execute 'syn match pythonTodo contained' dotfiles#todo_comments#get_pattern()
endif
