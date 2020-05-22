#!/usr/bin/python3

import math

# hex is 4 bits per character (through 0-15)    : 0-9 + A-F
# b32 is 5 bits per character (0-31)            : A-Z + 2-7
# b64 is 6 bits per character (0-63)

# 128 bit > 128/4 = 32 characters long
# 128 bit > 128/5 = 26 characters long
# 128 bit > 128/6 = 22 characters long

def b32(number, chr_len=None):
    """ given a number, convert it into a string """
    base = 32
    if not isinstance(number, int):
        raise ValueError("Can only convert int")
    if number < 0:
        raise ValueError("Only positive numbers")
    req_chr_len = math.ceil(math.log(number+1)/math.log(base))
    if chr_len is None:
        chr_len = req_chr_len
    elif chr_len < req_chr_len:
        raise ValueError("number too big for {} len str, needs {}".format(
            chr_len, req_chr_len))

    rstr = ''
    for i in reversed(range(chr_len)):
        digit = int(number/base**i)
        number -= digit*base**i

        if base == 32:
            if digit < 26:
                char = chr(ord('A') + digit)
            else:
                char = str(2 + digit - 26)
        else:
            raise NotImplementedError("no conversions for other basese")
        rstr = rstr + char
        if i in (7, 19):
            rstr = rstr + '-'
    if number != 0:
        raise RuntimeError("Calc went wrong")
    return rstr

if __name__ == "__main__":
    import random
    import argparse
    len_128bit_hex = 32
    b32_chars = [chr(ord('A')+i) for i in range(26)] + [str(i) for i in range(2,9)]
    hex_chars = [str(i) for i in range(10)] + [chr(ord('A')+i) for i in range(6)]
    example_128bit_hex_str = '0x' + ''.join(random.choice(hex_chars) for _ in range(32))
    example_128bit = eval(example_128bit_hex_str)

    #example_128bit = 0xFF19191737202020515135431B02F6DB



    max_128bit = eval('0x' + 'F'*32)

    len_base_10 = len(str(max_128bit))
    len_base_32_128b = math.ceil(128/5)
    len_base_32_72b = math.ceil(72/5)


    example_as_b32 = b32(example_128bit, len_base_32_128b)

    print("Example 128 bit number")
    print("  Number Format:   {0:0{1}}".format(example_128bit, len_base_10))
    print("  Hex Format (0x): {:032X}".format(example_128bit))
    print("  b32 Format:      {}".format(example_as_b32))

    atmel_uids = [
            0xFF172A133720202051513543321F6698,
            0xFF181F0E3720202051513543F2391E50,
            0xFF182A0A372020205151354377F1BEC2,
            0xFF19070F3720202051513543DFFCD666,
            0xFF19191737202020515135431B02F6DB,
            ]

    lid_uids = [
            0x01236646deb1f604ee,
            0x0123c2243e440b93ee,
            0x0123bddf47aaf0e5ee,
            ]

    print()
    print("Atmel UIDs")
    for uid in atmel_uids:
        print("  {}  0x{:032X}".format(b32(uid, len_base_32_128b), uid))

    print()
    print("Lid UIDs")
    for uid in lid_uids:
        print("  {}  0x{:018X}".format(b32(uid, len_base_32_72b), uid))
