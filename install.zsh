#!/usr/bin/env zsh

install_dotfile() {
  local dest="$1"
  local contents="$2"

  if [[ -f "$dest" ]]; then
    mv -vi "$dest" "$dest.dmitmel-dotfiles-backup"
  fi

  mkdir -p "${dest:h}"
  echo "$contents" > "$dest"
}

# ZSH
for zsh_file_name in zshrc; do
  install_dotfile "$HOME/.$zsh_file_name" '
#!/usr/bin/env zsh
source "$PWD/zsh/$zsh_file_name"
'
done
unset zsh_file_name

# Neovim
install_dotfile ~/.config/nvim/init.vim 'source $PWD/nvim/init.vim'
install_dotfile ~/.config/nvim/ginit.vim 'source $PWD/nvim/ginit.vim'
