if not vim.filetype then return end

vim.filetype.add({
  extension = {
    log = 'log',
    LOG = 'log',
    ioc = 'jproperties', -- STM32CubeMX project settings
    kicad_pcb = 'kicad',
    kicad_sch = 'kicad',
    kicad_dru = 'kicad',
    kicad_mod = 'kicad',
    kicad_sym = 'kicad',
    kicad_prl = 'json',
    kicad_pro = 'json',
  },
  filename = {
    ['.clangd'] = 'yaml',
    ['.vimspector.json'] = 'jsonc',
    ['.latexmkrc'] = 'perl',
    ['coc-settings.json'] = 'jsonc',
    ['pyrightconfig.json'] = 'jsonc',
    ['.luarc.json'] = 'jsonc',
  },
  pattern = {
    ['.*/assets/.*%.json%.patch'] = 'json',
    ['.*/etc/fonts/.*%.conf'] = 'xml',
    ['.*/fontconfig/.*%.conf'] = 'xml',
    ['.*/snippets/.*%.json'] = 'jsonc',
    ['.*/%.vscode/.*%.json'] = 'jsonc',
  },
})
