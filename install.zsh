#!/usr/bin/env zsh

DOTFILES_PATH="${0:a:h}"

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
  zsh_file_path="$DOTFILES_PATH/zsh/$zsh_file_name"
  install_dotfile "$HOME/.$zsh_file_name" "source ${(q)zsh_file_path}"
done
unset zsh_file_name zsh_file_path

# Neovim
install_dotfile ~/.config/nvim/init.vim "source $DOTFILES_PATH/nvim/init.vim"
install_dotfile ~/.config/nvim/ginit.vim "source $DOTFILES_PATH/nvim/ginit.vim"
