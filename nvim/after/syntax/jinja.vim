" This script exists due to an unfortunate case of a certain syntax file
" overstepping its boundaries. Here is the full investigation:
"
" 1. `syntax/nginx.vim` includes `syntax/jinja.vim` as a secondary syntax
"    <https://github.com/chr4/nginx.vim/blob/cffaec54f0c7f9518de053634413a20e90eac825/syntax/nginx.vim#L2289-L2298>
"    <https://github.com/neovim/neovim/blob/v0.6.0/runtime/syntax/nginx.vim#L2256-L2265>
" 2. `syntax/jinja.vim` was not bundled with Vim/Nvim for a very long time
"    <https://github.com/neovim/neovim/commit/13d6f6cbb2337c1db5b3fceb607d36a2a632dc03>
" 3. Naturally, the editor would attempt to find it elsewhere. It is not
"    shipped vim-polyglot either, but it will be found if you've got the
"    `python3-jinja2` package installed on Debian/Ubuntu/Mint etc, which will
"    install the file `/usr/share/vim/addons/syntax/jinja.vim`.
"    <https://sources.debian.org/src/jinja2/3.1.6-1/debian/jinja.vim/>
" 4. The Debian package used to get this file from the upstream, but the
"    upstream stopped shipping this script in version 3.0.0.
"    <https://salsa.debian.org/python-team/packages/jinja2/-/commit/94a468822d3ecc8cfb2daccc0543b4a561c0fbd0>
" 5. The old versions of this Vim script from the Jinja2 python library is the
"    culprit. It used to change `comments` and `commentstring` options, which
"    is not the responsibility of syntax scripts.
"    <https://github.com/pallets/jinja/blob/2.11.3/ext/Vim/jinja.vim#L85-L87>
" 6. This would, of course, break the ftplugin for the nginx filetype which
"    sets the comment options (because ftplugins run before syntax scripts).
"
" This bug has now been resolved by the Debian package shipping a fixed version
" of `jinja.vim` without `set com cms`, and both Vim and Nvim now ship with a
" built-in syntax file for Jinja which does not have this bug, but I'm leaving
" my fix for two reasons: a) this being a really cool detective story; b) me
" having to work on servers with outdated system packages.
let [&l:comments, &l:commentstring] = b:dotfiles_jinja_fix
unlet b:dotfiles_jinja_fix
