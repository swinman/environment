#!/usr/bin/python3
from matplotlib import pyplot as plt


line_colors = [
            'orange',   # good
            '#17a895',  # good
#            'magenta',  # good -- too close to red
            '#dd00ff',  #
#            'red',      # good
            '#ff3300',
#            'olive',    # okay but close to green
            'green',    # good
#            'brown',    # good
            '#406080',
            'blue',     # good
            'purple',   # good
#            'gray',     # normal
#            '0.25',     # darker
#            '0.75',     # lighter
#            'pink',     # not visible
#            'cyan',     # not visible in black and white
            ]

alphas = [0.5, 0.7, 1]


shift = 1

for i, color in enumerate(line_colors):
    scale = 1-(i/len(line_colors))
    for j, alpha in enumerate(alphas):
        seg = 1/len(alphas)
        plt.plot([shift*j*seg, shift*(j+1)*seg], [scale, scale], color=color, alpha=alpha)
    plt.text(shift, scale, '{}. {}'.format(i, color))

plt.xlim(0, 1.2)

plt.show()
