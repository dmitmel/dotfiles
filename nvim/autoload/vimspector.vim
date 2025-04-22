" This file will get sourced if vimspector has not been loaded yet.
call dotplug#load('vimspector')
execute 'source' dotplug#plugin_dir('vimspector').'/autoload/vimspector.vim'
