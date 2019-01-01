#!/usr/bin/env bash

for zsh_file_name in zshrc; do
  zsh_file="$HOME/.$zsh_file_name"

  if [[ -f "$zsh_file" ]]; then
    zsh_file_backup="$zsh_file.dmitmel-dotfiles-backup"
    echo "Backing up $zsh_file to $zsh_file_backup"
    mv -vi "$zsh_file" "$zsh_file_backup"
  fi

  cat > "$zsh_file" <<EOF
#!/usr/bin/env zsh

source "$PWD/$zsh_file_name"
EOF
done
