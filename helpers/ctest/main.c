#include "main.h"
#include <stdlib.h>
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

int8_t parse_two_ints_in_str(char* cmd_str) {
    int ndx, value;
    char *cmd_nxt, *end_chk;

    if (cmd_str == NULL) {
        printf("NULL Cmd string, exiting\n");
        return -1;
    }
    while (*cmd_str == ' ') {
        cmd_str++;
    }

    if (cmd_str[0] == '\0') {
        printf("Empty cmd_str, exiting\n");
        return -2;
    }

    ndx = strtod(cmd_str, &cmd_nxt);
    while (*cmd_nxt == ' ') {
        cmd_nxt++;
    }
    if (cmd_nxt[0] == '\0') {
        printf("Empty value, exiting\n");
        return -3;
    }

    value = strtold(cmd_nxt, &end_chk);
    while (*end_chk == ' ') {
        end_chk++;
    }
    if (*end_chk != '\0') {
        printf("Invalid data after command '%s', exiting\n", end_chk);
        return -4;
    }

    printf("Cmd str is '%s', ndx is %d val is %d\n", cmd_str, ndx, value);
    return 0;
}

void test_int_parsing(void) {
    printf("\n");
    parse_two_ints_in_str("5 -50");
    parse_two_ints_in_str(" 5 10");
    parse_two_ints_in_str(" 5   10");
    parse_two_ints_in_str(" 5   ");
    parse_two_ints_in_str(NULL);
    parse_two_ints_in_str("");
    parse_two_ints_in_str(" ");
    parse_two_ints_in_str(" 5 10 4  ");
    parse_two_ints_in_str("toast 3");
    parse_two_ints_in_str("3 4a");
    printf("\n");
}

int main() {
    mytype_t mb;
    const char *str = NULL;
    str = get_ptr();

    mb.byte = 15;


    make_command();

    test_int_parsing();

    const char sn[] = "0000-DEAD-BEEF-FFFF";

    printf("strlen(sn)=%lu sizeof(sn)=%lu\n", strlen(sn), sizeof(sn));

    printf("print a percent sign: '%%'\n");

    printf("Hex rep of 25: 0x%x\n", 25);
    printf("bff.third 0x%x\n", mb.third);
    printf("Hello, %s!\n", str);
    return 0;
}
