#!/usr/bin/python3
"""
Game of the Year
================

- try to get numbers between 1 & 100

highest
- 62: 1925, 1592
- 61: 1926
- 60: 1492, 1682, 1825, 1826
"""

from collections import defaultdict
import logging
import argparse

log = logging.getLogger(__name__)

default_year = 1492

unity_ops = (None, 'abs', 'neg')
operations = ('+', '-', '/', '*', '^')

def get_result(digits, ops, order, negs, abss):
    digits = list(digits)
    ops = list(ops)
    order = list(order)
    negs = list(negs)
    abss = list(abss)

    fmt_strs = [str(d) for d in digits]

    max_iter = 5
    while len(order) > 0:
        max_iter -= 1
        if max_iter == 0:
            raise ValueError("What happened???")
        ondx = order[0]
        log.debug("doing operation {} now".format(ondx))
        op = ops.pop(ondx - 1)
        n = negs.pop(0)
        a = abss.pop(0)

        lhs = digits.pop(ondx-1)
        rhs = digits.pop(ondx-1)
        ls = fmt_strs.pop(ondx-1)
        rs = fmt_strs.pop(ondx-1)

        if n == 'neg':
            lhs = lhs * -1
            ls = '-' + ls

        if op == '+':
            r = lhs + rhs
        elif op == '-':
            r = lhs - rhs
        elif op == '/':
            if rhs == 0:
                return False, None
            r = lhs / rhs
        elif op == '*':
            r = lhs * rhs
        elif op == '^':
            if lhs == 0 and rhs < 0:
                return False, None
            if abs(rhs) > 100:
                return False, None
            try:
                r = lhs ** rhs
            except Exception:
                log.error("cannot do {}**{}".format(lhs, rhs))
                raise

        rs = ls + op + rs

        if a == 'abs':
            r = abs(r)
            rs = '|' + rs + '|'
        else:
            rs = '(' + rs + ')'

        if ondx == 1:
            digits.insert(0, r)
            fmt_strs.insert(0, rs)
        elif ondx == 2:
            digits.insert(1, r)
            fmt_strs.insert(1, rs)
        else:
            digits.insert(2, r)
            fmt_strs.insert(2, rs)

        if isinstance(r, complex) or r > 1e10 or r < -1e10:
            pass
        else:
            log.debug("  operation {}: {} {} {} = {}".format(ondx, lhs, op, rhs, r))
        new_order = [o if o < ondx else o - 1 for o in order[1:]]
        log.debug("order was {}, new order is {}".format(order, new_order))
        order = new_order
    return r, rs

def print_winners(year, results, max_eq=None):
    for winner, eqs in sorted(results.items()):
        print("FOUND {} eqs that result in {:.0f}".format(len(eqs), winner))
        if max_eq is not None:
            eqs = eqs[:max_eq]
        for eq in eqs:
            print("  {}".format(eq))

    print("Found equations for {:3} numbers using year {}".format(len(results), year))

def find_winners(year, order_list, ops_list, negs_list, abs_list):
    digits = [int(c) for c in '{:04.0f}'.format(year % 10000)]
    winners = list(range(101))
    results = defaultdict(list)

    for ops in ops_list:
        for order in order_list:
            for negs in negs_list:
                for abss in abs_list:
                    result, eq_fmt = get_result(digits, ops, order, negs, abss)
                    if isinstance(result, complex):
                        if result.imag != 0:
                            continue
                        result = result.real
                    if result not in winners:
                        if result < 1e10 and result > -1e10:
                            log.info("{} = {:.6e} is not a winner".format(eq_fmt, result))
                        continue
                    results[result].append(eq_fmt)
    return results

ops_list = list()
for op1 in operations:
    for op2 in operations:
        for op3 in operations:
            ops_list.append([op1, op2, op3])


abs_list = list()
for u0 in (None, 'abs'):
    for u1 in (None, 'abs'):
        for u2 in (None, 'abs'):
            abs_list.append([u0, u1, u2])


negs_list = list()
for u0 in (None, 'neg'):
    for u1 in (None, 'neg'):
        for u2 in (None, 'neg'):
            negs_list.append([u0, u1, u2])


order_list = list()
for first in range(3):
    for second in range(3):
        if first == second:
            continue
        for third in range(3):
            if first == third:
                continue
            if second == third:
                continue
            order_list.append([first+1, second+1, third+1])

parser = argparse.ArgumentParser(
                    prog='Game of the Year',
                    description='Answers to game of the year')

parser.add_argument("-y", '--year', default=default_year, nargs='?', type=int)
parser.add_argument('-m', '--max-eq', nargs='?', type=int)

args = parser.parse_args()


#logging.basicConfig(level=logging.INFO)
print("Finding equations for year {}".format(args.year))
results = find_winners(args.year, order_list, ops_list, negs_list, abs_list)
print_winners(args.year, results, max_eq=args.max_eq)
