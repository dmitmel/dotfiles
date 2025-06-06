import cmath
import math
from decimal import Decimal
from fractions import Fraction
from math import *
from typing import Set

try:
  import pandas as pd

  print("pandas available as `pd`")
except ImportError:
  pass

try:
  import matplotlib.pyplot as plt

  print("matplotlib.pyplot available as `plt`")
except ImportError:
  pass


def factors(n: int) -> Set[int]:
  result: Set[int] = set()
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
