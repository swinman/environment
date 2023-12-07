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

    for (uint8_t lowval=30; lowval<35; lowval++) {
        printf("set sennum %u (0x%X 0b"BB_STR") by calling 0x%X 0b"BB_STR"\n",
            lowval, lowval, BTOB(lowval), lowval+' ', BTOB(lowval + ' '));
    }

    /* WORKS
    const char set_sennum_cmd = 32;
    const char max_numsen = 96;
    const char sensor_check = 0x60;
    */

    /* FAILS
    const char set_sennum_cmd = 16;
    const char max_numsen = 111;
    const char sensor_check = 0x30;
    */

    /* TESTING */
    const char set_sennum_cmd = 64;
    const char max_numsen = 64;
    const char sensor_check = 0x40;

    uint8_t sennum;
    uint8_t cmd;
    uint8_t failed = 0;
    for (sennum=0; sennum<max_numsen; sennum++) {
        cmd = set_sennum_cmd + sennum;
        if (!(cmd & sensor_check)) {
            printf("Set sennum %u has a command %u that wont work\n",
                    sennum, cmd);
            failed++;
        }
    }
    if (!failed) {
        printf("Set sennum commands adding %u work by checking (sn | 0x%02X) for up to %u sensors\n\n",
                set_sennum_cmd, sensor_check, max_numsen);
    } else {
        printf("Set sennum commands adding %u and by checking (sn | 0x%02X) FAILS for %u of %u sensors\n\n",
                set_sennum_cmd, sensor_check, failed, max_numsen);
    }

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
