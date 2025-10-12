#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s n\n", argv[0]);
        return 1;
    }
    
    int n = atoi(argv[1]);
    int sum = 0;
    int sign = 1;
    
    for (int i = 1; i <= n; i++) {
        sum += i * sign;
        
        if (i % 2 == 0) {
            sign = -sign;
        }
    }
    
    printf("Result: %d\n", sum);
    return 0;
}