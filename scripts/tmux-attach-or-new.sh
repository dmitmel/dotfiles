#!/bin/sh
if tmux has-session; then
  exec tmux attach
else
  exec tmux new
fi
