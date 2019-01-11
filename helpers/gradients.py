#!/usr/bin/python3
"""
Gradient color maker
========================
demo code for making gradients

@modified: 2019-01-10 12:49:13
"""

import colorsys
import random

import logging
log = logging.getLogger(__name__)

DEFAULT_SAURATION = 75 / 100
DEFAULT_VALUE = 100 / 100
DEFAULT_DHUE = 4 / 100
DEFAULT_NUM_COLORS = int(1 / DEFAULT_DHUE) + 1
DEFAULT_NUM_SWATCHES = 20

def _rgb_to_text(r, g, b, uint8=False):
    rgb = r, g, b
    if not uint8:
        rgb = [int(0xff * c) % 0x100 for c in rgb]
    txt = '#{:02X}{:02X}{:02X}'.format(*rgb)
    return txt

def make_swatch(hue_seed=None, dhue=DEFAULT_DHUE, num_colors=DEFAULT_NUM_COLORS,
        saturation=DEFAULT_SAURATION, value=DEFAULT_VALUE):
    """ make an array of colors with constant saturation and value
            hue_seed [0, 100) - seed for hue value
            hue_step [0, 100) - step for next hue
            num_colors - number of colors in the array
            saturation [0, 100] - satuartion for all colors
            value [0, 100] - value for all colors

        returns (r, g, b) as uint8 values
    """
    if hue_seed is None:
        hue_seed = random.random()
        log.info("Random hue seed is {:.0f}".format(hue_seed * 100))
    else:
        hue_seed = (hue_seed / 100) % 1.0

    def make_rgb(hue):
        rgb = colorsys.hsv_to_rgb(hue % 1.0, saturation, value)
        log.debug("RGB for hue {:.2f} is [{}]".format(hue % 1.0,
            ', '.join('{:.2f}'.format(round(c, 2)) for c in rgb)))
        rgb_uint8 = [int(c * 0xff) % 0x100 for c in rgb]
        return rgb_uint8

    swatch = [make_rgb(hue_seed + dhue * i) for i in range(num_colors)]

    log.info("Swatch is [{}]".format(", ".join(_rgb_to_text(*rgb, uint8=True) for rgb in swatch)))
    log.info("Swatch has {} colors".format(len(swatch)))
    return swatch


if __name__ == "__main__":
    import argparse
    import matplotlib.pyplot as plt
    from skimage import io
    import numpy as np

    logging.basicConfig(level=logging.DEBUG)

    def _make_parser():
        parser = argparse.ArgumentParser(description="Gradient Picker")
        parser.add_argument('-u', '--hue-seed', type=int, default=None,
                help='Hue seed [0, 100)')

        parser.add_argument('-d', '--hue-step', type=int, default=DEFAULT_DHUE*100,
                help='Hue step, out of 100')

        parser.add_argument('-n', '--number-colors', type=int, default=DEFAULT_NUM_COLORS,
                help='Number of colors in the swatch')
        parser.add_argument('-q', '--number-swatches', type=int, default=DEFAULT_NUM_SWATCHES,
                help='Number of swatches to display')

        parser.add_argument('-s', '--saturation', type=int, default=72,
                help='Saturation, out of 100')
        parser.add_argument('-v', '--value', type=int, default=100,
                help='Value, out of 100')

        return parser

    parser = _make_parser()
    args = parser.parse_args()

    array = [make_swatch(args.hue_seed, dhue=args.hue_step/100,
        num_colors=args.number_colors, saturation=args.saturation/100,
        value=args.value/100) for j in range(args.number_swatches if args.hue_seed is None else 1)]
    io.imshow(np.array(array, dtype=np.uint8))
    plt.show()
