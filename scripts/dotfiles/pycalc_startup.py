# pyright: reportUnusedImport=none, reportWildcardImportFromLibrary=none
# ruff: noqa: F401, F403, F405

import cmath
import math
from decimal import Decimal
from fractions import Fraction
from math import *


class _LazyImporter:
  def __init__(self, module: str, var_name: str) -> None:
    self._module = module
    self._var_name = var_name
    print("{} available as `{}`".format(module, var_name))

  def __getattribute__(self, key: str, /) -> object:
    module = object.__getattribute__(self, "_module")
    var_name = object.__getattribute__(self, "_var_name")
    vars_dict = globals()
    exec("import {} as {}".format(module, var_name), vars_dict, vars_dict)  # noqa: S102
    return getattr(vars_dict[var_name], key)


np = _LazyImporter("numpy", "np")
pd = _LazyImporter("pandas", "pd")
plt = _LazyImporter("matplotlib.pyplot", "plt")


def factors(n: int) -> "set[int]":
  result: "set[int]" = set()
  for i in range(1, int(sqrt(n)) + 1):
    if n % i == 0:
      result.add(i)
      result.add(n // i)
  return result


def solve_quadratic(a: float, b: float, c: float) -> None:
  d = b**2 - 4 * a * c
  sd = cmath.sqrt(d)
  print("sqrt(D) = " + str(sd))
  print("x1 = " + str((-b + sd) / (2 * a)))
  print("x2 = " + str((-b - sd) / (2 * a)))


def cot(x: float) -> float:
  return 1 / tan(x)


def acot(x: float) -> float:
  return pi / 2 - atan(x)


def coth(x: float) -> float:
  return 1 / tanh(x)


def acoth(x: float) -> float:
  return atanh(1 / x)


def relative_error(real: float, measured: float) -> float:
  return abs(measured - real) / real
