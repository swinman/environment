#include "main.h"
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

void place_str(const char* str_ptr) {
    str_ptr = "World";
}

const char* get_ptr(void) {
    const char *str_ptr = "World";
    return str_ptr;
}

void make_command(void) {

    int tilt = -3200;

    int print_len;
    char str[10];

    str[0] = 'M';
    str[1] = 't';

    print_len = snprintf(str + 2, 8, "%d", tilt);

    printf("Rem char is %d, str len is %d, str is '%s'\n",
            print_len, 2 + print_len, str);

}

int main() {
    mytype_t mb;
    const char *str = NULL;
    str = get_ptr();

    mb.byte = 15;


    make_command();

    const char sn[] = "0000-DEAD-BEEF-FFFF";

    printf("strlen(sn)=%lu sizeof(sn)=%lu\n", strlen(sn), sizeof(sn));

    printf("Hex rep of 25: 0x%x\n", 25);
    printf("bff.third 0x%x\n", mb.third);
    printf("Hello, %s!\n", str);
    return 0;
}
