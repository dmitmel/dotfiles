--- <https://github.com/neoclide/coc.nvim/blob/master/data/schema.json>
local M = require('dotfiles.autoload')('dotfiles.lsp.global_settings')

local lsp_protocol = require('vim.lsp.protocol')
local utils = require('dotfiles.utils')


-- <https://github.com/neoclide/coc.nvim/blob/705135211e84725766e434f59e63ae3592c609d9/data/schema.json#L992-L996>
M.MAX_FILE_SIZE = 1 * 1024 * 1024  -- 1 MB

M.IGNORED_FILETYPES = {}

M.DEFAULT_FLOAT_BORDER_STYLE = nil

-- <https://github.com/neoclide/coc.nvim/blob/705135211e84725766e434f59e63ae3592c609d9/data/schema.json#L631-L640>
M.DIAGNOSTIC_WINDOW_MAX_WIDTH, M.DIAGNOSTIC_WINDOW_MAX_HEIGHT = 80, 8
-- <https://github.com/neoclide/coc.nvim/blob/705135211e84725766e434f59e63ae3592c609d9/data/schema.json#L684-L694>
M.SIGNATURE_WINDOW_MAX_WIDTH, M.SIGNATURE_WINDOW_MAX_HEIGHT = 80, 8
-- <https://github.com/neoclide/coc.nvim/blob/705135211e84725766e434f59e63ae3592c609d9/data/schema.json#L750-L758>
M.HOVER_WINDOW_MAX_WIDTH, M.HOVER_WINDOW_MAX_HEIGHT = 80, 24
-- <https://github.com/neoclide/coc.nvim/blob/73861dc2aefa8bf7c9e6daaf0c2f313abb41372d/data/schema.json#L910-L914>
M.LOCATION_PREVIEW_WINDOW_MAX_WIDTH, M.LOCATION_PREVIEW_WINDOW_MAX_HEIGHT = 100, 12

M.MARKDOWN_SYNTAX_NAMES_MAPPING = {}

M.MARKDOWN_DISABLED_SYNTAXES = {}


-- TODO: Fetch schemas directly from <https://www.schemastore.org/api/json/catalog.json>
M.JSON_SCHEMAS_CATALOG = {}
for _, catalog_path in ipairs(vim.api.nvim_get_runtime_file('dotfiles/json_schema_catalog.json', true)) do
  local catalog_json = utils.json_decode(utils.read_file(catalog_path))
  assert(
    catalog_json['$schema'] == 'https://json.schemastore.org/schema-catalog' or
    catalog_json['$schema'] == 'https://json.schemastore.org/schema-catalog.json'
  )
  assert(catalog_json.version == 1)
  vim.list_extend(M.JSON_SCHEMAS_CATALOG, catalog_json.schemas)
end
for _, catalog_script_path in ipairs(vim.api.nvim_get_runtime_file('dotfiles/json_schema_catalog.lua', true)) do
  local patcher_fn = dofile(catalog_script_path)
  patcher_fn(M.JSON_SCHEMAS_CATALOG)
end


local SymbolKind = lsp_protocol.SymbolKind
-- See also: <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#symbolKind>.
M.SYMBOL_KIND_LABELS = {
  [SymbolKind.File] = 'File';
  [SymbolKind.Module] = 'Mod';
  [SymbolKind.Namespace] = 'NS';
  [SymbolKind.Package] = 'Pkg';
  [SymbolKind.Class] = 'Class';
  [SymbolKind.Method] = 'Method';
  [SymbolKind.Property] = 'Prop';
  [SymbolKind.Field] = 'Field';
  [SymbolKind.Constructor] = 'Constructor';
  [SymbolKind.Enum] = 'Enum';
  [SymbolKind.Interface] = 'Interface';
  [SymbolKind.Function] = 'Func';
  [SymbolKind.Variable] = 'Var';
  [SymbolKind.Constant] = 'Const';
  [SymbolKind.String] = 'Str';
  [SymbolKind.Number] = 'Num';
  [SymbolKind.Boolean] = 'Bool';
  [SymbolKind.Array] = 'Arr';
  [SymbolKind.Object] = 'Obj';
  [SymbolKind.Key] = 'Key';
  [SymbolKind.Null] = 'Null';
  [SymbolKind.EnumMember] = 'EnMem';
  [SymbolKind.Struct] = 'Struct';
  [SymbolKind.Event] = 'Event';
  [SymbolKind.Operator] = 'Op';
  [SymbolKind.TypeParameter] = 'Type';
}
M.FALLBACK_SYMBOL_KIND_LABEL = '???'


local CompletionItemKind = lsp_protocol.CompletionItemKind
-- Copied from <https://github.com/neoclide/coc.nvim/blob/30a46412ebc66c0475bca7e49deb119fb14f0f00/src/sources/index.ts#L55-L81>.
-- <https://github.com/neoclide/coc.nvim/blob/daab29410d816a23f0f162ea786024d4f33abe31/data/schema.json#L466-L499>
-- See also: <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#completionItemKind>.
M.COMPLETION_KIND_LABELS = {
  [CompletionItemKind.Text] = 't';
  [CompletionItemKind.Method] = 'f';
  [CompletionItemKind.Function] = 'f';
  [CompletionItemKind.Constructor] = 'f';
  [CompletionItemKind.Field] = 'm';
  [CompletionItemKind.Variable] = 'v';
  [CompletionItemKind.Class] = 'C';
  [CompletionItemKind.Interface] = 'I';
  [CompletionItemKind.Module] = 'M';
  [CompletionItemKind.Property] = 'm';
  [CompletionItemKind.Unit] = 'U';
  [CompletionItemKind.Value] = 'v';
  [CompletionItemKind.Enum] = 'E';
  [CompletionItemKind.Keyword] = 'k';
  [CompletionItemKind.Snippet] = 'S';
  [CompletionItemKind.Color] = 'v';
  [CompletionItemKind.File] = 'F';
  [CompletionItemKind.Reference] = 'r';
  [CompletionItemKind.Folder] = 'F';
  [CompletionItemKind.EnumMember] = 'm';
  [CompletionItemKind.Constant] = 'v';
  [CompletionItemKind.Struct] = 'S';
  [CompletionItemKind.Event] = 'E';
  [CompletionItemKind.Operator] = 'O';
  [CompletionItemKind.TypeParameter] = 'T';
}
M.FALLBACK_COMPLETION_KIND_LABEL = ''


return M
