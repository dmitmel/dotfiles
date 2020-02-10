syn clear pythonOperator
syn match pythonOperator '\V=\|-\|+\|*\|@\|/\|%\|&\||\|^\|~\|<\|>\|!='
syn keyword pythonOperatorKeyword and in is not or
syn cluster pythonExpression add=pythonOperatorKeyword
