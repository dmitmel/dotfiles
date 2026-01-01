#!/usr/bin/env python3
# pyright: standard

import json
import re
import sys
import textwrap


def main():
  result = {}
  current = None

  for line in sys.stdin:
    line = line.rstrip("\n\r")
    match = re.match(r"^snippet\s+(\S+)\s*(.*)?$", line)
    if match:
      prefix = match.group(1)
      description = match.group(2)
      current = {"prefix": prefix, "description": description, "body": []}
      result[prefix] = current
    elif current is not None:
      current["body"].append(line)

  for current in result.values():
    current["body"] = textwrap.dedent("\n".join(current["body"])).split("\n")

  json.dump(result, sys.stdout, indent=2)


if __name__ == "__main__":
  main()
