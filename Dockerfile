# syntax=docker/dockerfile:1

# docker build --tag dotfiles:ubuntu20.04 .
# docker run --rm --volume "${PWD}:/pwd" --detach --name dotfiles --interactive                            dotfiles:ubuntu20.04
# docker run --rm --volume "${PWD}:/pwd"          --name dotfiles --interactive --tty -e TERM -e COLORTERM dotfiles:ubuntu20.04
# docker exec                                                     --interactive --tty -e TERM -e COLORTERM dotfiles

# ubuntu=24.04; podman build --tag dotfiles:ubuntu${ubuntu} ~/dotfiles --build-arg=from=ubuntu:${ubuntu} && podman run --rm -it -e TERM -e COLORTERM -v ~/dotfiles:/dotfiles dotfiles:ubuntu${ubuntu}

ARG from=ubuntu:24.04
FROM ${from}

ENV DEBIAN_FRONTEND=noninteractive

# <https://github.com/moby/buildkit/blob/v0.26.3/frontend/dockerfile/docs/reference.md#example-cache-apt-packages>
RUN --mount=type=cache,sharing=locked,target=/var/cache/apt/archives \
  rm -f /etc/apt/apt.conf.d/docker-clean && \
  echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache && \
  apt-get update && if command -v unminimize || apt-get install -y unminimize; \
    then yes | unminimize; else apt-get dist-upgrade -y; fi

RUN --mount=type=cache,sharing=locked,target=/var/cache/apt/archives \
  apt-get install --no-install-recommends -y \
    ccache ninja-build gettext cmake curl build-essential git ca-certificates

RUN --mount=type=cache,sharing=shared,target=/var/cache/ccache \
  nvim_dir='/usr/local/src/neovim' && \
  git -c advice.detachedHead=false clone --progress --branch=stable --depth=1 -- \
    'https://github.com/neovim/neovim.git' "$nvim_dir" && \
  export PATH="/usr/lib/ccache:$PATH" CCACHE_DIR='/var/cache/ccache' && \
  make -C "$nvim_dir" CMAKE_INSTALL_PREFIX='/usr/local' CMAKE_BUILD_TYPE='RelWithDebInfo' \
    CMAKE_EXTRA_FLAGS='-DENABLE_LTO=OFF' install || true && \
  ccache -s && rm -rf -- "$nvim_dir"

# Delete the compilation cache from my container. It will still be preserved in
# Docker's database, but absent from the resulting container.
RUN rm -rf '/var/cache/ccache'

RUN --mount=type=cache,sharing=locked,target=/var/cache/apt/archives \
  packages='' && \
  for name in build-essential curl wget zsh vim neovim git pv jq zip unzip kitty-terminfo file \
    less man-db tree python3 python-is-python3 python3-psutil python3-colorama python3-distro \
    command-not-found; do if apt-cache show "$name" >/dev/null; then packages="${packages} ${name}"; fi; done && \
  apt-get install --no-install-recommends -y $packages && \
  apt-get update  # to update the command-not-found database

ARG dotfiles_dir=/dotfiles
COPY . ${dotfiles_dir}
ENV DOTFILES_DIR=${dotfiles_dir}

RUN \
  chsh -s /bin/zsh && \
  echo "source ${DOTFILES_DIR}/zsh/zshrc" > ~/.zshrc && \
  echo "skip_global_compinit=1" > ~/.zshenv && \
  mkdir -p ~/.config/nvim && echo "source ${DOTFILES_DIR}/nvim/init.vim" > ~/.config/nvim/init.vim && \
  mkdir -p ~/.vim && echo "source ${DOTFILES_DIR}/nvim/init.vim" > ~/.vim/vimrc && \
  for dir in git lf ranger tmux; do ln -sr "${DOTFILES_DIR}/misc/${dir}" -t ~/.config/; done

RUN \
  mkdir -p /usr/local/lib/kitty && \
  curl -Lf https://github.com/kovidgoyal/kitty/archive/refs/heads/master.tar.gz | \
    tar -C /usr/local/lib/kitty -xzvf - --strip-components=1 kitty-master/shell-integration && \
  DOTFILES_ZSHRC_SILENT=1 zsh -i -c 'nvim --headless +"qa!" || true'

CMD /bin/zsh
