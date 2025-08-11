#!/usr/bin/env node

/**
 * @module
 * This script is my alternative to prettierd, which currently is the de-facto
 * tool for integrating Prettier with Neovim. I've had a couple of problems with
 * prettierd: firstly, it spawns a separate daemon per workspace directory, all
 * of which just hang in the background even if the editor is closed, and
 * secondly, it cannot access the LSP settings managed by `neoconf.nvim`. I
 * solve this by wrapping Prettier in a Language Server with this script, whose
 * lifecycle is managed by Neovim (or any other LSP client) and which accesses
 * the workspace settings like any other Language Server. This script is written
 * in JS instead of TS so that I can run it directly without an extra
 * compilation step, but the JSDoc annotations enable me to use the TS compiler
 * to typecheck my code. Also, I deliberately stuck to the older ES2018 syntax,
 * so that this program works on my university's server, which only has Node v12
 * installed.
 *
 * This code is roughly based on:
 * - <https://github.com/prettier/prettier-vscode>
 * - <https://github.com/neoclide/coc-prettier>
 * - <https://github.com/fsouza/prettierd>
 * - <https://github.com/sosukesuzuki/prettier-language-server-deprecated>
 * - <https://github.com/microsoft/vscode-extension-samples/blob/main/lsp-sample/server/src/server.ts>
 *
 * See also:
 * - <https://github.com/prettier/prettier-vscode/pull/3016>
 * - <https://github.com/prettier/prettier-vscode/pull/2947>
 * I've tried to follow the semantics of the VSCode extension and implement most
 * of its features, but only as a guideline, not as an iron law.
 */

const LS = require('vscode-languageserver/node');
const { TextDocument } = require('vscode-languageserver-textdocument');
const { URI } = require('vscode-uri');
const { createRequire } = require('module');
const Path = require('path');
const Util = require('util');
const packageJson = require('./package.json');

// This directive is equivalent to the `import type` statement in TypeScript: it
// brings the namespace and the types of the requested module into the scope
// without actually importing it.
/** @import * as prettier from 'prettier' */

/**
 * @typedef {Object} PrettierServerSettings Extra options implemented by the
 * server. The list of all options of the prettier-vscode extension can be seen
 * here: <https://github.com/prettier/prettier-vscode#extension-settings>.
 * @property {boolean} [enable]
 * @property {string[]} [disableLanguages]
 * @property {string} [prettierPath]
 * @property {string} [ignorePath]
 * @property {string} [configPath]
 * @property {boolean} [withNodeModules]
 * @property {boolean} [requireConfig]
 * @property {boolean} [useEditorConfig]
 * @property {boolean} [onlyUseLocalVersion]
 * @property {boolean} [resolveGlobalModules] TODO
 * @property {'npm'|'yarn'|'pnpm'} [packageManager] TODO
 */

/** @typedef {prettier.Options & PrettierServerSettings} Settings */

/**
 * @typedef {Object} CachedPrettierModule
 * @property {typeof import('prettier')} module
 * @property {PrettierServerSettings} settings
 * @property {Promise<prettier.SupportInfo>} supportInfo
 */

let connection = LS.createConnection(LS.ProposedFeatures.all);
let documents = new LS.TextDocuments(TextDocument);

/** @type {LS.ClientCapabilities} */
let clientCapabilities;
/** @type {LS.WorkspaceFolder[]|null|undefined} */
let workspaceFolders;
/** @type {Settings?} */
let globalSettings = null;
/** @type {Map<string, Promise<Settings|null>>} */
let documentSettings = new Map();
/** @type {Map<string, CachedPrettierModule>} */
let cachedPrettierModules = new Map();

/** Poor man's optional chaining (replacement for the `a?.b` operator). */
function get(/** @type {any} */ obj, /** @type {Array<string|number>} */ ...path) {
  return path.reduce((obj, key) => (obj != null ? obj[key] : obj), obj);
}

connection.onInitialize((/** @type {LS.InitializeParams} */ params) => {
  clientCapabilities = params.capabilities;
  workspaceFolders = params.workspaceFolders;

  /** @type {LS.ServerCapabilities} */
  let serverCapabilities = {
    textDocumentSync: LS.TextDocumentSyncKind.Incremental,
    documentFormattingProvider: true,
    documentRangeFormattingProvider: true,
    workspace: {
      workspaceFolders: {
        supported: true,
        changeNotifications: true,
      },
    },
  };

  return {
    serverInfo: { name: packageJson.name, version: packageJson.version },
    capabilities: serverCapabilities,
  };
});

connection.onInitialized(() => {
  if (get(clientCapabilities, 'workspace', 'didChangeConfiguration', 'dynamicRegistration')) {
    connection.client.register(LS.DidChangeConfigurationNotification.type, { section: 'prettier' });
  }
  if (get(clientCapabilities, 'workspace', 'workspaceFolders')) {
    connection.workspace.onDidChangeWorkspaceFolders(async (_event) => {
      // I don't want to bother with parsing and tracking the `added` and
      // `removed` folders sent in the notification, so just re-request the
      // whole list from the client instead.
      workspaceFolders = await connection.workspace.getWorkspaceFolders();
    });
  }
});

connection.onDidChangeConfiguration(({ settings }) => {
  globalSettings = get(settings, 'prettier');
  documentSettings.clear();
});

documents.onDidClose((/** @type {LS.TextDocumentChangeEvent<TextDocument>} */ event) => {
  documentSettings.delete(event.document.uri);
  cachedPrettierModules.delete(event.document.uri);
});

connection.onDocumentFormatting(formattingHandler);
connection.onDocumentRangeFormatting(formattingHandler);

documents.listen(connection);
connection.listen();

/**
 * The handler for the methods `textDocument/formatting` and
 * `textDocument/rangeFormatting`. They are so similar that I use a single
 * function to process both of them.
 * @param {LS.DocumentFormattingParams|LS.DocumentRangeFormattingParams} params
 * @return {Promise<LS.TextEdit[]>}
 */
async function formattingHandler(params) {
  try {
    let document = documents.get(params.textDocument.uri);
    if (!document) return [];

    let {
      enable = true,
      disableLanguages = [],
      prettierPath,
      ignorePath = '.prettierignore',
      configPath,
      withNodeModules = false,
      requireConfig = false,
      useEditorConfig = true,
      onlyUseLocalVersion = false,
      resolveGlobalModules = false,
      packageManager = 'npm',
      ...optionsFromSettings
    } = (await getDocumentSettings(document.uri)) || {};

    if (!enable || disableLanguages.includes(document.languageId)) return [];

    let uri = URI.parse(document.uri);
    let workspaceFolder = getWorkspaceFolderOf(document.uri);
    let workspaceUri = workspaceFolder ? URI.parse(workspaceFolder.uri) : undefined;

    function resolveWorkspaceRelativePath(/** @type {string|undefined} */ path) {
      if (path) {
        if (Path.isAbsolute(path)) {
          return path;
        } else if (workspaceUri && workspaceUri.scheme === 'file') {
          return Path.join(workspaceUri.fsPath, path);
        }
      }
      return undefined;
    }

    let cacheKey = document.uri;
    let wasCached = cachedPrettierModules.has(cacheKey);
    let prettier = loadPrettierModuleCached(cacheKey, uri, {
      onlyUseLocalVersion,
      prettierPath: resolveWorkspaceRelativePath(prettierPath),
      resolveGlobalModules,
      packageManager,
    });
    if (!prettier) return [];

    /** @type {prettier.Options?} */
    let resolvedConfig = null;
    if (uri.scheme === 'file') {
      // Configuration files and Editorconfig can be resolved only for local files.
      resolvedConfig = await prettier.module.resolveConfig(uri.fsPath, {
        config: resolveWorkspaceRelativePath(configPath),
        editorconfig: useEditorConfig,
        useCache: wasCached,
      });
      if (requireConfig && !resolvedConfig) return [];
    }

    let { ignored, inferredParser } = await prettier.module.getFileInfo(uri.fsPath, {
      resolveConfig: uri.scheme === 'file',
      ignorePath: resolveWorkspaceRelativePath(ignorePath),
      withNodeModules,
    });
    if (ignored) return [];

    /** @type {prettier.Options} */
    let options = {};
    if ('options' in params) {
      // Infer the basic options from the LSP request -- they will be respected
      // when no config is available at all.
      options.tabWidth = params.options.tabSize;
      options.useTabs = !params.options.insertSpaces;
    }

    // The language ID is supplied to us by the Language Client. By default,
    // Neovim will send the value of the `&filetype` option as the language ID.
    // Fortunately, they correspond pretty much 1-to-1 between VSCode and Vim.
    let { languageId } = document;
    if (inferredParser) {
      options.parser = inferredParser;
    } else if (languageId === 'html' || languageId === 'json') {
      // The parser detection logic below does not work correctly for some file
      // types, see <https://github.com/prettier/prettier-vscode/blob/v11.0.0/src/languageFilters.ts#L9-L14>.
      options.parser = languageId;
    } else {
      let language = (await prettier.supportInfo).languages.find((lang) => {
        return lang.vscodeLanguageIds && lang.vscodeLanguageIds.includes(languageId);
      });
      options.parser = get(language, 'parsers', 0);
    }

    // This must be an either-OR selection. The options read from the config and
    // the ones read from LSP settings shouldn't be mixed.
    Object.assign(options, resolvedConfig || optionsFromSettings);

    options.filepath = uri.fsPath;
    if ('range' in params) {
      options.rangeStart = document.offsetAt(params.range.start);
      options.rangeEnd = document.offsetAt(params.range.end);
    }

    let code = document.getText();
    try {
      code = await prettier.module.format(code, options);
    } catch (error) {
      // Prettier throws SyntaxErrors if parsing fails.
      if (error instanceof SyntaxError) return [];
      throw error;
    }
    return makeMinimalEdit(document, code);
  } catch (error) {
    // This will hopefully display any kind of error thrown inside the callback.
    // The default error handler does not add stack traces of errors:
    // <https://github.com/microsoft/vscode-languageserver-node/blob/release/server/9.0.1/jsonrpc/src/common/connection.ts#L886-L893>
    let message = String((error instanceof Error && error.stack) || error);
    throw new LS.ResponseError(LS.ErrorCodes.InternalError, message);
  }
}

/** @returns {Promise<Settings|null>} */
function getDocumentSettings(/** @type {string} */ uri) {
  if (get(clientCapabilities, 'workspace', 'configuration')) {
    let promise = documentSettings.get(uri);
    if (!promise) {
      promise = connection.workspace.getConfiguration({ section: 'prettier', scopeUri: uri });
      documentSettings.set(uri, promise);
    }
    return promise;
  }
  return Promise.resolve(globalSettings);
}

/**
 * Finds the longest match in workspaceFolders, in other words, the deepest
 * folder that contains the given URI. This follows the behavior of
 * `vscode.workspace.getWorkspaceFolder()`:
 * <https://github.com/microsoft/vscode/blob/1.101.1/src/vs/workbench/api/common/extHostWorkspace.ts#L169-L175>.
 * @returns {LS.WorkspaceFolder|undefined}
 */
function getWorkspaceFolderOf(/** @type {string} */ uri) {
  let result;
  let maxLength = 0;
  for (let folder of Array.isArray(workspaceFolders) ? workspaceFolders : []) {
    let folderUri = folder.uri + (folder.uri.endsWith('/') ? '' : '/');
    if (uri.startsWith(folderUri) && folderUri.length > maxLength) {
      result = folder;
      maxLength = folderUri.length;
    }
  }
  return result;
}

/** @returns {CachedPrettierModule|null} */
function loadPrettierModuleCached(
  /** @type {string} */ cacheKey,
  /** @type {URI} */ uri,
  /** @type {PrettierServerSettings} */ settings,
) {
  let cached = cachedPrettierModules.get(cacheKey);
  if (!cached || !Util.isDeepStrictEqual(cached.settings, settings)) {
    let module = loadPrettierModule(uri, settings);
    if (!module) return null;
    cached = { module, settings, supportInfo: module.getSupportInfo() };
    cachedPrettierModules.set(cacheKey, cached);
  }
  return cached;
}

/** @returns {null | typeof import('prettier')} */
function loadPrettierModule(
  /** @type {URI} */ uri,
  /** @type {PrettierServerSettings} */ settings,
) {
  if (uri.scheme === 'file') {
    // This will create a `require()` function that works as if it was called
    // within the given file, looking into the `node_modules` directories
    // relative to it and so on.
    let localRequire = createRequire(uri.fsPath);
    try {
      return localRequire(settings.prettierPath || 'prettier');
    } catch (/** @type {any} */ error) {
      if (error.code !== 'MODULE_NOT_FOUND') throw error;
    }
  }
  if (!settings.onlyUseLocalVersion) {
    return require('prettier'); // The bundled Prettier is lazy-loaded if necessary.
  }
  return null;
}

/** Taken from <https://github.com/prettier/prettier-vscode/blob/v11.0.0/src/PrettierEditService.ts#L372-L397>.
 * @returns {LS.TextEdit[]} */
function makeMinimalEdit(/** @type {TextDocument} */ document, /** @type {string} */ after) {
  let before = document.getText();
  if (before === after) return [];

  let minLength = Math.min(before.length, after.length);

  let i = 0; // length of the common prefix
  while (i < minLength && before[i] === after[i]) {
    i++;
  }

  let j = 0; // length of the common suffix
  while (i + j < minLength && before[before.length - j - 1] === after[after.length - j - 1]) {
    j++;
  }

  let start = document.positionAt(i);
  let end = document.positionAt(before.length - j);
  let newText = after.substring(i, after.length - j);

  return [{ range: { start, end }, newText }];
}
