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
for file_name in zshrc; do
  file_path="$DOTFILES_PATH/zsh/$file_name"
  install_dotfile "$HOME/.$file_name" "source ${(q)file_path}"
done

# Neovim
for file_name in {init,ginit}.vim; do
  file_path="$DOTFILES_PATH/nvim/$file_name"
  install_dotfile "$HOME/.config/nvim/$file_name" "source ${(q)file_path}"
done

# Kitty
file_name=kitty.conf
file_path="$DOTFILES_PATH/kitty/$file_name"
install_dotfile "$HOME/.config/kitty/$file_name" "include ${(q)file_path}"
