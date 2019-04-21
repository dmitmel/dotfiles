#!/usr/bin/env zsh

install_dotfile() {
  local dest="$1"

  if [[ -f "$dest" ]]; then
    mv -vi "$dest" "$dest.dmitmel-dotfiles-backup"
  fi

  mkdir -p "${dest:h}"
  cat > "$dest"
}

# ZSH
for zsh_file_name in zshrc; do
  install_dotfile "$HOME/.$zsh_file_name" <<EOF
#!/usr/bin/env zsh
source "$PWD/$zsh_file_name"
EOF
done
unset zsh_file_name

# Neovim
install_dotfile ~/.config/nvim/init.vim <<EOF
source $PWD/nvim/init.vim
EOF
install_dotfile ~/.config/nvim/ginit.vim <<EOF
source $PWD/nvim/ginit.vim
EOF
