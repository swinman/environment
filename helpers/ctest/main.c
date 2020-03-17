#include <stdio.h>

void place_str(const char* str_ptr) {
    str_ptr = "World";
}

const char* get_ptr(void) {
    const char *str_ptr = "World";
    return str_ptr;
}

int main() {
    const char *str = NULL;
    str = get_ptr();

    printf("Hex rep of 25: 0x%x\n", 25);
    printf("Hello, %s!\n", str);
    return 0;
}
