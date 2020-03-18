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
