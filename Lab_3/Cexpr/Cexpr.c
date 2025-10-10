#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc < 4) {
        printf("Usage: %s a b c\n", argv[0]);
        return 1;
    }

    long a = atol(argv[1]);
    long b = atol(argv[2]);
    long c = atol(argv[3]);

    long result = ((((a - c) + b) * c) * c) + c;

    printf("%ld\n", result);
    return 0;
}