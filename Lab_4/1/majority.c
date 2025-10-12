

#include <stdio.h>
#include <stdlib.h>

int main(void) {
    long n;
    if (scanf("%ld", &n) != 1) {
        printf("Решение: Нет\n");
        return 0;
    }
    if (n <= 0) {
        printf("Решение: Нет\n");
        return 0;
    }
    long ones = 0;
    for (long i = 0; i < n; ++i) {
        int v;
        if (scanf("%d", &v) != 1) {
            
            break;
        }
        if (v == 1) ++ones;
    }
    if (ones * 2 > n) {
        printf("Решение: Да\n");
    } else {
        printf("Решение: Нет\n");
    }
    return 0;
}
