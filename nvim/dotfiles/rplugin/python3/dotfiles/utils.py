from typing import List, Tuple


def simple_line_diff(
  old_lines: List[str],
  new_lines: List[str],
  search_from_start_offset: int = 0,
  search_from_end_offset: int = 0,
) -> Tuple[bool, int, int]:
  """
  Re-implementation of `dotfiles.lsp.utils.simple_line_diff` from the Lua side.
  """
  min_lines_len = min(len(old_lines), len(new_lines))
  common_lines_from_start, common_lines_from_end = 0, 0
  for i in range(search_from_start_offset, min_lines_len):
    if old_lines[i] != new_lines[i]:
      break
    common_lines_from_start += 1
  if len(old_lines) == len(new_lines) and common_lines_from_start == len(old_lines):
    return False, common_lines_from_start, common_lines_from_end
  for i in range(search_from_end_offset, min_lines_len - common_lines_from_start):
    if old_lines[-i - 1] != new_lines[-i - 1]:
      break
    common_lines_from_end += 1
  assert len(old_lines) >= common_lines_from_start + common_lines_from_end, 'sanity check'
  assert len(new_lines) >= common_lines_from_start + common_lines_from_end, 'sanity check'
  return True, common_lines_from_start, common_lines_from_end
