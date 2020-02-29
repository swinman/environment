#!/usr/bin/python3
"""
Gradient color maker
========================
demo code for making gradients

@modified: 2019-01-10 12:49:13
"""

import colorsys
import math
import random

import logging
log = logging.getLogger(__name__)

DEFAULT_SAURATION = 75 / 100
DEFAULT_VALUE = 100 / 100
DEFAULT_DHUE = 5 / 100
DEFAULT_NUM_SWATCHES = 20

def _rgb_to_text(r, g, b, uint8=False):
    rgb = r, g, b
    if not uint8:
        rgb = [int(0xff * c) % 0x100 for c in rgb]
    txt = '#{:02X}{:02X}{:02X}'.format(*rgb)
    return txt

def make_rgb_from_hsv(hue, saturation, value):
    rgb = colorsys.hsv_to_rgb(hue % 1.0, saturation, value)
    log.debug("RGB for hue {:.2f} is [{}] {} total {:.2f}".format(hue % 1.0,
        ', '.join('{:.2f}'.format(round(c, 2)) for c in rgb),
        _rgb_to_text(*rgb), sum(rgb)))
    rgb_uint8 = [int(c * 0xff) % 0x100 for c in rgb]
    return rgb_uint8

def make_rgb_sin(hue, saturation, value):
    color_min = 1 - saturation
    color_max = value
    amplitude = 0.5 * (color_max - color_min)
    center = 0.5 * (color_max + color_min)

    r = amplitude * math.cos(hue * 2 * math.pi) + center
    g = amplitude * math.cos((hue + 1/3) * 2 * math.pi) + center
    b = amplitude * math.cos((hue + 2/3) * 2 * math.pi) + center
    rgb = (r, g, b)

    log.debug("RGB for hue {:.2f} is [{}] {} total {:.2f}".format(hue % 1.0,
        ', '.join('{:.2f}'.format(round(c, 2)) for c in rgb),
        _rgb_to_text(*rgb), sum(rgb)))
    rgb_uint8 = [min(int(c * 0xff), 0xff) for c in rgb]
    return rgb_uint8

# TODO : add RYB (red yellow blue)
# https://github.com/bahamas10/ryb/blob/gh-pages/js/RXB.js#L252-L330
# https://bahamas10.github.io/ryb/assets/ryb.pdf


# TODO : add ramp function

def make_swatch(make_color_fcn, hue_seed=None, dhue=DEFAULT_DHUE, num_colors=6,
        saturation=DEFAULT_SAURATION, value=DEFAULT_VALUE):
    """ make an array of colors with constant saturation and value
        uses 3 sinusoids offset by 1/3 to maintain a constant sum
            hue_seed [0, 100) - seed for hue value
            hue_step [0, 100) - step for next hue
            num_colors - number of colors in the array
            value [0, 100] - max value for sinusoids
            saturation [0, 100] - (1 - min value for sinusoids)
            min = (1 - sat)

        returns (r, g, b) as uint8 values
    """
    if hue_seed is None:
        hue_seed = random.random()
        log.info("Random hue seed is {:.0f}".format(hue_seed * 100))
    else:
        hue_seed = (hue_seed / 100) % 1.0

    swatch = [make_color_fcn(hue_seed + dhue * i, saturation, value) for i in range(num_colors)]

    log.info("Swatch is [{}]".format(", ".join(_rgb_to_text(*rgb, uint8=True) for rgb in swatch)))
    log.info("Swatch has {} colors".format(len(swatch)))
    return swatch


# color picker from stopsen testing scripts
def get_color(**kwargs):
    """ return a color (possibly translated from a number)
        translate color based on multiple options
        freq|trial|rep
    """
    fmin = kwargs.pop('fmin', 400)
    fmax = kwargs.pop('fmax', 3000)
    tcmax = kwargs.pop('tcmax', 32)
    tcmin = kwargs.pop('tcmin', 2)
    dmin = kwargs.pop('dmin', 0)
    dmax = kwargs.pop('dmax', 600)
    vmin = kwargs.pop('vmin', 0)
    vmax = kwargs.pop('vmax', 9)
    color_num = random.randint(0, 255)
    if 'color_num' in kwargs:
        color_num = kwargs.pop('color_num')
    elif 'freq' in kwargs and 'tc' in kwargs:
        f = int(255*(kwargs.pop('freq')-fmin)/(fmax-fmin))
        tc = int(255*(math.log(kwargs.pop('tc'))-math.log(tcmin))/(math.log(tcmax)-math.log(tcmin)))
        return "#{:02X}{:02X}{:02X}".format(f, 0xff-(f+tc)//2, tc)
    elif 'tc' in kwargs:
        tc = int(255*(math.log(kwargs.pop('tc'))-math.log(tcmin))/(math.log(tcmax)-math.log(tcmin)))
        return "#{:02X}{:02X}{:02X}".format(tc, 0, 0xff-tc)
    elif 'freq' in kwargs:
        freq = kwargs.pop('freq')
        log.info("Freq {} fmin {} fmax {}".format(freq, fmin, fmax))
        f = int(255*(freq-fmin)/(fmax-fmin))
        return "#{:02X}{:02X}{:02X}".format(f, 0, 0xff-f)
    elif 'dist' in kwargs and 'vac' in kwargs:
        d = int(255*(kwargs.pop('dist')-dmin)/(dmax-dmin))
        v = int(255*(kwargs.pop('vac')-vmin)/(vmax-vmin))
        return "#{:02X}{:02X}{:02X}".format(d, 0xff-(d+v)//2, v)
    elif 'rep' in kwargs:
        scale = 255 / 8
        color_num = int(scale * (kwargs.pop('rep')-1))
    return "#{:02X}{:02X}{:02X}".format(color_num, 0, 0xff-color_num)

if __name__ == "__main__":
    import argparse
    import matplotlib.pyplot as plt
    try:
        from skimage import io
    except ImportError:
        io = None
    import numpy as np

    logging.basicConfig(level=logging.DEBUG)

    def _make_parser():
        parser = argparse.ArgumentParser(description="Gradient Picker")
        parser.add_argument('-u', '--hue-seed', type=int, default=None,
                help='Hue seed [0, 100)')

        parser.add_argument('-d', '--hue-step', type=int, default=DEFAULT_DHUE*100,
                help='Hue step, out of 100')

        parser.add_argument('-n', '--number-colors', type=int, default=None,
                help='Number of colors in the swatch')
        parser.add_argument('-q', '--number-swatches', type=int, default=DEFAULT_NUM_SWATCHES,
                help='Number of swatches to display')

        parser.add_argument('-g', '--use-rgb', action='store_true',
                help='Use rgb sinusoids to pick colors')

        parser.add_argument('-s', '--saturation', type=int, default=72,
                help='Saturation, out of 100')
        parser.add_argument('-v', '--value', type=int, default=100,
                help='Value, out of 100')

        return parser


    parser = _make_parser()
    args = parser.parse_args()

    if args.number_colors is None:
        num_colors = int(100 / args.hue_step) + 1
        log.info("Setting number of colors to {}, full spectrum".format(num_colors))
    else:
        num_colors = args.number_colors

    if args.use_rgb:
        fcn = make_rgb_sin
    else:
        fcn = make_rgb_from_hsv

    N = args.number_swatches if args.hue_seed is None else 1
    array = [make_swatch(fcn, args.hue_seed, dhue=args.hue_step/100,
        num_colors=num_colors, saturation=args.saturation/100,
        value=args.value/100) for j in range(N)]
    if len(array) == 1:
        plt.subplot(211)
        colors = ['.-r', '.-g', '.-b']
        ndx = list(range(len(array[0])))
        for i in range(3):
            plt.plot(ndx, [c[i] for c in array[0]], colors[i])
        plt.subplot(212)
    if io is not None:
        io.imshow(np.array(array, dtype=np.uint8))
        plt.show()
