#!/usr/bin/python3
"""
Profiling
========================
demo code for profiling

@modified: 2018-07-16 09:43:44
@author: winman@lucidsci.com
"""

import os
import time
import random
import math
import logging

log = logging.getLogger(__name__)


def junk_calc(e=6):
    N = int(10**e)
    sumout = 1
    starttime = time.clock()
    log.info("Running calc for N = 10^{} = {:,}".format(e, N))
    for i in range(N):
        sumout += inner_calc(i)
        sumout += inner_2(i)
    endtime = time.clock()
    log.info("Process took {:,.0f} ms".format(1000*(endtime - starttime)))
    return sumout

def inner_calc(N):
    faci = 1
    for j in range(N):
        faci *= j
    return faci

def inner_2(N):
    tot = 0
    for j in range(N):
        tot += random.randint(0, 1000)
    return tot

if __name__ == "__main__":
    import sys
    import argparse
    import matplotlib.pyplot as plt
    from massxport.helpers import plot_flow
    from collections import OrderedDict

    logging.basicConfig(level=logging.DEBUG)


    def _make_parser():
        parser = argparse.ArgumentParser(description="Probe Step Simulations")
        parser.add_argument('-e', '--exponent', type=float, default=3.2,
                help='Size of the calc')
        parser.add_argument('-p', '--profile', action='store_true',
                help='Run a profile operation')
        return parser

    parser = _make_parser()
    args = parser.parse_args()

    if args.profile:
        import cProfile
        pr = cProfile.Profile()
        pr.enable()

    # DO YOUR CALCULATIONS HERE
    c = junk_calc(args.exponent)

    if args.profile:
        pr.disable()
        pr.dump_stats('cprof.out')
        if False:   # print profile to terminal
            import io
            import pstats
            s = io.StringIO()
            sortby = 'cumulative'
            ps = pstats.Stats(pr, stream=s).sort_stats(sortby)
            ps.print_stats()
            print(s.getvalue())
        print("use snakeviz (pip install snakeviz) to view profile output")
        print("$ python3 -m cProfile -o cprof.out ./stepsimulation.py")
        print("$ snakeviz cprof.out")
