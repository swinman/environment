#include "main.h"

void place_str(const char* str_ptr) {
    str_ptr = "World";
}

const char* get_ptr(void) {
    const char *str_ptr = "World";
    return str_ptr;
}

int main() {
    mytype_t mb;
    const char *str = NULL;
    str = get_ptr();

    mb.byte = 15;

    printf("Hex rep of 25: 0x%x\n", 25);
    printf("bff.third 0x%x\n", mb.third);
    printf("Hello, %s!\n", str);
    return 0;
}
