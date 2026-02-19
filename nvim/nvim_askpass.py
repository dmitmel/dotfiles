#!/usr/bin/env python3

import os
import sys

import pynvim

prompt = sys.argv[1]
address = os.environ.get("NVIM") or os.environ["NVIM_LISTEN_ADDRESS"]

with pynvim.attach("socket", path=address) as nvim:
  print(nvim.call("dotfiles#nvim#sudo#askpass", prompt), end="")
