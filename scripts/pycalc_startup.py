from math import *
from fractions import Fraction


def factors(n):
    result = set()
    for i in range(1, int(sqrt(n)) + 1):
        div, mod = divmod(n, i)
        if mod == 0:
            result.add(div)
            result.add(mod)
    return result


print("loaded Python calculator")
