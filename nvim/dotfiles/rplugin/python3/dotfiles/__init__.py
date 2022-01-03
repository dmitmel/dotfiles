# type: ignore

# <https://github.com/PyCQA/isort/blob/main/isort/main.py>
# <https://github.com/PyCQA/flake8/blob/master/src/flake8/main/application.py>

# NOTE: Don't use synchronous functions.
# <https://github.com/neovim/pynvim/issues/434>
# <https://github.com/neovim/pynvim/pull/496>

import os
from pathlib import Path
import tempfile
from typing import Any, Dict, List, Optional, cast

import pynvim

import dotfiles.utils


@pynvim.plugin
class DotfilesHelperPlugin:

  def __init__(self, vim: pynvim.Nvim) -> None:
    self.vim = vim

  @pynvim.function('_dotfiles_rplugin_init')
  def rpc_init(self, args: List[Any]) -> Any:
    return 'ok'

  @pynvim.function('_dotfiles_rplugin_lsp_formatter_yapf', sync=True)
  def rpc_lsp_formatter_yapf(self, args: List[Any]) -> Any:
    buf_path: Optional[str]
    buf_root_dir: str
    default_config_path: str
    fmt_ranges: Optional[List[List[int]]]
    buf_lines: List[str]
    buf_path, buf_root_dir, default_config_path, fmt_ranges, buf_lines = args

    try:
      from yapf.yapflib.yapf_api import FormatCode
      from yapf.yapflib import file_resources
      from yapf.yapflib.errors import YapfError
      from lib2to3.pgen2.parse import ParseError as ParseError2to3
    except ModuleNotFoundError as err:
      raise pynvim.ErrorResponse('yapf is not installed: {}'.format(err))

    # The following code is essentially a reimplementation of
    # <https://github.com/google/yapf/blob/v0.31.0/yapf/__init__.py#L82-L114>.
    try:
      buf_dir = os.path.dirname(buf_path) if buf_path is not None else buf_root_dir
      config_path = default_config_path
      if buf_dir is not None:
        # This thing is actually not possible to pull off just through shelling
        # out to Yapf because it only has an option to override the config
        # globally and without any regard for project-local settings.
        config_path = file_resources.GetDefaultStyleForDir(buf_dir, default_config_path)

      if buf_root_dir is not None and buf_path is not None:
        # It should be mentioned that this function doesn't look for files in
        # parent directories, which is a shame.
        excluded_patterns = file_resources.GetExcludePatternsForDir(buf_root_dir)
        if buf_path.startswith(buf_root_dir):
          buf_path = buf_path[len(buf_root_dir):]
        if file_resources.IsIgnored(buf_path, excluded_patterns):
          return None

      # TODO: comment here about normalization of newlines by yapf and how a
      # string takes up less space than an array of them when encoded also how
      # Vim handles BOM
      buf_text = '\n'.join(buf_lines) + '\n'

      try:
        fmt_text, changed = FormatCode(
          buf_text,
          filename=buf_path if buf_path is not None else '<unknown>',
          style_config=config_path,
          lines=fmt_ranges,
          verify=False
        )
      except ParseError2to3 as err:
        # lineno, offset = err.context[1]
        # raise pynvim.ErrorResponse(
        #   'yapf: syntax error on {}:{}: {}'.format(lineno, offset, err.msg)
        # )
        return None
      except SyntaxError as err:
        # raise pynvim.ErrorResponse(
        #   'yapf: syntax error on {}:{}: {}'.format(err.lineno, err.offset, err.msg)
        # )
        return None
      if not changed:
        return None

      # TODO: write a continuation of that comment here as well
      fmt_lines = (fmt_text[:-1] if fmt_text.endswith('\n') else fmt_text).split('\n')
      changed, common_lines_from_start, common_lines_from_end = (
        dotfiles.utils.simple_line_diff(buf_lines, fmt_lines)
      )
      if not changed:
        return None
      if common_lines_from_start > 0:
        fmt_lines = fmt_lines[common_lines_from_start:]
      if common_lines_from_end > 0:
        fmt_lines = fmt_lines[:-common_lines_from_end]
      return (common_lines_from_start, common_lines_from_end, fmt_lines)

    except YapfError as err:
      # <https://github.com/google/yapf/blob/5fda04e1cdf50f548e121173337e07cc5304b752/yapf/__init__.py#L363-L365>
      # raise pynvim.ErrorResponse('yapf: {}'.format(err))
      return None

  @pynvim.function('_dotfiles_rplugin_lsp_linter_vint', sync=True)
  def rpc_lsp_formatter_vint(self, args: List[Any]) -> Any:
    buf_path: Optional[str]
    buf_root_dir: str
    buf_lines: List[str]
    buf_path, buf_root_dir, buf_lines = args

    try:
      from vint.bootstrap import init_linter
      from vint.linting.env import build_environment
      from vint.linting.config.config_container import ConfigContainer
      from vint.linting.config.config_cmdargs_source import ConfigCmdargsSource
      from vint.linting.config.config_default_source import ConfigDefaultSource
      from vint.linting.config.config_global_source import ConfigGlobalSource
      from vint.linting.config.config_project_source import ConfigProjectSource
      from vint.linting.policy_set import PolicySet
      from vint.linting.linter import Linter
    except ModuleNotFoundError as err:
      raise pynvim.ErrorResponse('vint is not installed: {}'.format(err))

    init_linter()

    lint_file_path = Path(buf_path if buf_path is not None else os.devnull)
    # The codebase seems to always check for presence of keys in `cmdargs`,
    # possibly because they can be specified as an dictionary in a config file,
    # as such construction of a realistic dictionary is not necessary.
    # lint_cmdargs = vars(vint.linting.cli.CLI()._build_argparser().parse_args([]))
    lint_cmdargs = {
      # Stub for v0.4a1 and later, see below.
      'stdin_display_name': str(lint_file_path)
    }
    lint_env: Dict[str, Any] = build_environment(lint_cmdargs)
    lint_env['cwd'] = Path(buf_root_dir)
    lint_env['file_paths'] = ['-']  # Basically a stub but is not read at all.

    config = ConfigContainer(
      ConfigDefaultSource(lint_env),
      ConfigGlobalSource(lint_env),
      ConfigProjectSource(lint_env),
      ConfigCmdargsSource(lint_env),
    )
    config_dict: Any = config.get_config_dict()

    # TODO: same comment
    buf_text = '\n'.join(buf_lines) + '\n'

    # Alright, so, here's the deal... We can't use `lint_text` directly. That
    # is because in all versions since 0.2.0 there is this policy
    # `MissingScriptEncoding` which attempts to read the file to check its
    # encoding. `lint_text` is normally called when the linted file is supplied
    # via stdin, then the `Linter` class sets the path of the file to the
    # special string `stdin` (Note: relax, this will not lead to hilarious bugs
    # when linting a legitimate file named `stdin`, this is not Javascript with
    # its lazy comparison rules, real paths are instances of the `pathlib.Path`
    # class), which the aforementioned policy checks to determine where to read
    # the file contents from. In our case, however, the file is supplied from a
    # string and not from a real file, and stdin is used for PRC with Nvim, so
    # this leads to a crash.
    #
    # ...However, the above problem occurs just in my bizarre Vim setup, but do
    # you know what's even better? There is another policy, `NoAbortFunction`,
    # which ensures that all functions defined in files in the `autoload`
    # directory have a `!` and `abort`... and, because it treats the path
    # parameter as a `pathlib.Path`, it will ALWAYS crash when the file is
    # supplied via stdin (like `vint - < init.vim`, which is entirely normal
    # usage of the program)! Because, of course, the special value `stdin` is
    # used. This rule was already implemented in version 0.0.0.
    #
    # Now, I can only imagine why this blatant bug has gone unnoticed for so
    # frikin long, although stdin support has not always been present, it was
    # actually added only relatively recently as part of 0.3.19:
    # <https://github.com/Vimjas/vint/commit/cac0cf731dc34ed0a3ffcf1191774d91fbfa8f89>.
    # However, what this means for me is that I have to either write the buffer
    # text to disk into a temporary file, or use the knowledge of internals and
    # write code which essentially combines both `lint_text` and `lint_file`.
    #
    # Thankfully, 0.4a1 and onwards implement a LintTarget abstraction which
    # solves this problem, but currently this version is not available in
    # Arch's repos, so there. See
    # <https://github.com/Vimjas/vint/commit/3a2729eb6a5eb809054a1357ae1e1f32bc59cb1c>.

    violations: List[Dict[str, Any]] = []

    if hasattr(Linter, 'lint'):
      # For >=0.4
      from vint.linting.policy_registry import get_policy_classes
      from vint.linting.lint_target import AbstractLintTarget

      class LintTargetInMemory(AbstractLintTarget):

        def __init__(self, path: Path, contents: bytes) -> None:
          super().__init__(path)
          self.contents = contents

        def read(self) -> bytes:
          return self.contents

      policy_set = PolicySet(get_policy_classes())
      linter = Linter(policy_set, config_dict)
      violations = linter.lint(LintTargetInMemory(lint_file_path, buf_text.encode('utf8')))

    elif hasattr(Linter, 'lint_text'):
      # For >=0.3.19 <0.4
      from vint._bundles import vimlparser
      from vint.encodings.decoder import EncodingDetectionError
      from vint.linting.policy.prohibit_missing_scriptencoding import ProhibitMissingScriptEncoding

      policy_set = PolicySet()
      linter = Linter(policy_set, config_dict)
      linter._log_file_path_to_lint(lint_file_path)

      # However, additionally I still patch out the function which is
      # responsible for reading the file in `MissingScriptEncoding`, this is to
      # ensure that it can work on unsaved files and if the file doesn't even
      # exist. I also think that this is the cleanest way to do the
      # monkey-patch because only one instance of the policy is affected, and
      # they are always newly created in the `PolicySet`'s constructor.
      broken_policy: Any = policy_set._all_policies_map.get('ProhibitMissingScriptEncoding')
      if type(broken_policy) == ProhibitMissingScriptEncoding:

        def check_script_has_multibyte_char(lint_context: Any) -> bool:
          # <https://stackoverflow.com/a/51141941/12005228>
          return not buf_text.isascii()

        broken_policy._check_script_has_multibyte_char = check_script_has_multibyte_char

      root_ast = None
      have_parsing_error = False
      try:
        root_ast = linter._parser.parse(buf_text)
      except vimlparser.VimLParserException as err:
        violations = [linter._create_parse_error(lint_file_path, str(err))]
        have_parsing_error = True
      except EncodingDetectionError as err:
        # NOTE: EncodingDetectionError can only be thrown when calling
        # `linter._parser.parse_file`, but I handle it for completeness.
        violations = [linter._create_decoding_error(lint_file_path, str(err))]
        have_parsing_error = True

      if not have_parsing_error:
        linter._traverse(root_ast, lint_file_path)
        violations = linter._violations

    else:
      # For <0.3.19
      policy_set = PolicySet()
      linter = Linter(policy_set, config_dict)

      # Poor man's method involving a temporary file.
      tmp_dir: Optional[str] = None
      tmp_prefix: Optional[str] = None
      tmp_suffix: Optional[str] = '.vim'
      if buf_path is not None:
        tmp_dir = os.path.dirname(buf_path)
        if not os.path.isdir(tmp_dir):
          tmp_dir = None
        tmp_prefix, tmp_suffix = os.path.splitext(os.path.basename(buf_path))

      with tempfile.NamedTemporaryFile(
        dir=tmp_dir, prefix=tmp_prefix, suffix=tmp_suffix
      ) as tmp_buf_file:
        tmp_buf_file.write(buf_text.encode('utf8'))
        tmp_buf_file.flush()
        violations = linter.lint_file(Path(tmp_buf_file.name))

    rpc_result: List[List[Any]] = []
    for idx, violation in enumerate(violations):
      rpc_result.append([
        violation['position']['line'],
        violation['position']['column'],
        violation['level'].value,
        violation['name'],
        violation['description'],
        violation['reference'],
      ])

    return rpc_result

  def vim_print(
    self, *objects: object, sep: str = ' ', end: str = '\n', err: bool = False
  ) -> None:
    self.vim.request(
      'nvim_err_write' if err else 'nvim_out_write',
      str(sep).join(map(str, objects)) + str(end),
      async_=True,
    )
