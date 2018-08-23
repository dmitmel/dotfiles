#!/usr/bin/env bash

ZSHRC=~/.zshrc
ZSHRC_BACKUP=~/.zshrc.pre-dmitmel-dotfiles

if [[ -f $ZSHRC ]]; then
  echo "Backing up $ZSHRC to $ZSHRC_BACKUP"
  mv $ZSHRC $ZSHRC_BACKUP
fi

cat > $ZSHRC <<EOF
#!/usr/bin/env zsh

export DOTFILES_PATH="\$HOME/.dotfiles"
export OH_MY_ZSH_PATH="\$HOME/.oh-my-zsh"
source "\$DOTFILES_PATH/zshrc"
EOF
