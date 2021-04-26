from math import *
from fractions import Fraction


def factors(n):
  result = set()
  for i in range(1, int(sqrt(n)) + 1):
    if n % i == 0:
      result.add(i)
      result.add(n // i)
  return result


def solve_quadratic(a, b, c):
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


print("loaded Python calculator")
