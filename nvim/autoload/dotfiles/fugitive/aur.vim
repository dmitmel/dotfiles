" Based on <https://github.com/tpope/vim-rhubarb/blob/3d444b5b4f636408c239a59adb88ee13a56486e0/autoload/rhubarb.vim>
" Also see <https://github.com/tpope/vim-fugitive/blob/0868c30cc08a4cf49b5f43e08412c671b19fa3f0/autoload/fugitive.vim#L6123-L6343>.
" Other intersting links:
" <https://git.zx2c4.com/cgit/>
" <https://github.com/shumphrey/fugitive-gitlab.vim/blob/f3e56ff60fe3fb5ebc891cbe5fd12cd8c59ae6ef/autoload/gitlab.vim#L6-L93>
" <https://github.com/tommcdo/vim-fubitive/blob/5717417ee75c39ea2f8f446a9491cdf99d5965e9/plugin/fubitive.vim>
" <https://github.com/LinuxSuRen/fugitive-gitee.vim/blob/96221852753a04daeb8136c54b0082db36d1ac5b/plugin/gitee.vim>
" <https://github.com/jparise/vim-phabricator/blob/d5c0571f44f2c44ba32df2d12e52b4dfcd4921ed/autoload/phabricator.vim>
" <https://github.com/cedarbaum/fugitive-azure-devops.vim/blob/4f1adeac33f54d1ec1949364d049237d7485dea1/autoload/azuredevops.vim>
function! dotfiles#fugitive#aur#handler(opts) abort
  if type(a:opts) != v:t_dict
    return ''
  endif
  let opts = a:opts

  let parsed = dotfiles#fugitive#aur#parse_url(get(opts, 'remote', ''))
  if empty(parsed)
    return ''
  endif

  let path = substitute(opts.path, '^/', '', '')
  if path =~# '^\.git/refs/heads/'
    let branch = path[16:-1]
    " AUR packages can have only a single branch, master, as it is mapped to
    " the branch named after the package in the central Git repository.
    if branch ==# 'master'
      return parsed.cgit_prefix . '/log/' . parsed.cgit_suffix
    endif
    return ''
  elseif path =~# '^\.git/refs/tags/'
    " Tags are not allowed for AUR packages.
    let tag = path[15:-1]
    return ''
  elseif path =~# '^\.git/refs/remotes/[^/]\+/.'
    let remote_branch = matchstr(path[18:-1], '^[^/]\+/\zs.*$')
    " Same story as with regular branches.
    if remote_branch ==# 'master'
      return parsed.cgit_prefix . '/log/' . parsed.cgit_suffix
    endif
    return ''
  elseif path =~# '^\.git/'
    return parsed.cgit_prefix . '/' . parsed.cgit_suffix
  endif

  if opts.commit =~# '^\d\=$'
    return ''
  elseif expand('%') =~? '^fugitive:'
    let commit = opts.commit
  else
    let commit = fugitive#RevParse('HEAD', opts.repo.git_dir)
  endif

  let line = min([opts.line1, opts.line2])
  let parsed.cgit_suffix .= '&id=' . substitute(commit, '#', '%23', 'g')
  if opts.type ==# 'blob' || opts.type ==# 'tree'
    return parsed.cgit_prefix . '/tree/' . substitute(path, '/$', '', 'g') . parsed.cgit_suffix . (line ? '#n'.line : '')
  elseif opts.type ==# 'commit' || opts.type ==# 'tag'
    return parsed.cgit_prefix . '/commit/' . parsed.cgit_suffix
  endif

  return ''
endfunction


" Based on <https://github.com/shumphrey/fugitive-gitlab.vim/blob/f3e56ff60fe3fb5ebc891cbe5fd12cd8c59ae6ef/autoload/gitlab.vim#L70-L79>
" and <https://github.com/tpope/vim-rhubarb/blob/3d444b5b4f636408c239a59adb88ee13a56486e0/autoload/rhubarb.vim#L32>.
" Also see <https://github.com/archlinux/aurweb/blob/d5e308550ad4682829c01feb32212540a6699100/web/html/404.php#L8>.
function! dotfiles#fugitive#aur#parse_url(url) abort
  let intro_re = '%(https=|git|ssh)\://%([^/@]+\@)='
  let domain_re = 'aur\.archlinux\.org'
  let repo_path_re = '[a-zA-Z0-9][a-zA-Z0-9_\.\+\-]{-}'
  let outro_re = '%(\.git)=/='
  let combined_re = '\v^'.intro_re.'\zs('.domain_re.')/('.repo_path_re.')\ze'.outro_re.'$'
  let matches = matchlist(a:url, combined_re)
  if empty(matches)
    return {}
  endif
  let domain = matches[1]
  let package = matches[2]
  let homepage = 'https://'.domain.'/pkgbase/'.package
  let cgit_prefix = 'https://'.domain.'/cgit/aur.git'
  let cgit_suffix = '?h='.package
  return {'domain': domain, 'package': package, 'homepage': homepage, 'cgit_prefix': cgit_prefix, 'cgit_suffix': cgit_suffix}
endfunction
