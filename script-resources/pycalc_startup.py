from math import *
from fractions import Fraction


def factors(n):
    result = set()
    for i in range(1, int(sqrt(n)) + 1):
        if n % i == 0:
            result.add(i)
            result.add(n // i)
    return result


print("loaded Python calculator")
