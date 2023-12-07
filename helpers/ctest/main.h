#include <stdio.h>

typedef char uint8_t;

typedef union {
    struct {
        char first      : 1;
        char second     : 2;
        char third      : 3;
        uint8_t     : 3;
    };
    char byte;
} mytype_t;


#define BB_STR "%c%c%c%c %c%c%c%c"
#define BTOB(byte)  \
  ((byte) & 0x80 ? '1' : '0'), \
  ((byte) & 0x40 ? '1' : '0'), \
  ((byte) & 0x20 ? '1' : '0'), \
  ((byte) & 0x10 ? '1' : '0'), \
  ((byte) & 0x08 ? '1' : '0'), \
  ((byte) & 0x04 ? '1' : '0'), \
  ((byte) & 0x02 ? '1' : '0'), \
  ((byte) & 0x01 ? '1' : '0')
