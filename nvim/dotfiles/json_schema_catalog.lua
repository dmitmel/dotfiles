return function(catalog)
  local patchsteps_pattern = '**/assets/**/*.json.patch'
  table.insert(catalog, {
    name = 'CrossCode PatchSteps',
    description = 'https://github.com/CCDirectLink/CLS/blob/master/standards/patch-steps.md',
    fileMatch = { patchsteps_pattern },
    url = 'https://raw.githubusercontent.com/dmitmel/ultimate-crosscode-typedefs/master/json-schemas/patch-steps.json',
  })
  for _, entry in ipairs(catalog) do
    if string.gsub(entry.url, '%.json$', '') == 'https://json.schemastore.org/json-patch' then
      table.insert(entry.fileMatch, '!' .. patchsteps_pattern)
    end
  end

  table.insert(catalog, {
    name = 'pyrightconfig.json',
    description = 'Pyright Configuration Schema',
    fileMatch = { 'pyrightconfig.json' },
    url = 'https://raw.githubusercontent.com/microsoft/pyright/main/packages/vscode-pyright/schemas/pyrightconfig.schema.json',
  })
end
