#!/usr/bin/env python3
# pyright: standard

import sys

import json5


def main():
  for _, snippet in json5.load(sys.stdin).items():
    print(f"snippet {snippet['prefix']} {snippet.get('description', '')}")
    for line in snippet["body"]:
      print("\t" + line)


if __name__ == "__main__":
  main()
