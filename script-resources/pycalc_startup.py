from math import *
from fractions import Fraction
from typing import Set


def factors(n: int) -> Set[int]:
  result: Set[int] = set()
  for i in range(1, int(sqrt(n)) + 1):
    if n % i == 0:
      result.add(i)
      result.add(n // i)
  return result


def solve_quadratic(a: float, b: float, c: float) -> None:
  if a == 0:
    raise Exception("not a quadratic equation")
  else:
    d = b ** 2 - 4 * a * c
    print("D = " + str(d))
    if d < 0:
      print("no solutions")
    elif d > 0:
      sd = sqrt(d)
      print("sqrt(D) = " + str(sd))
      print("x1 = " + str((-b + sd) / (2 * a)))
      print("x2 = " + str((-b - sd) / (2 * a)))
    else:
      print("x = " + str(-b / (2 * a)))


def cot(x: float) -> float:
  return 1 / tan(x)


def acot(x: float) -> float:
  return pi / 2 - atan(x)


def coth(x: float) -> float:
  return 1 / tanh(x)


def acoth(x: float) -> float:
  return atanh(1 / x)
