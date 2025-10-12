#include <stdio.h>
#include <stdlib.h>
#include <string.h>

long long calculate_result(long long n) {
    
    return n / 481;
}


int is_valid_number(const char *str) {
    if (str == NULL || *str == '\0') {
        return 0;
    }
    

    for (int i = 0; str[i] != '\0'; i++) {
        if (str[i] < '0' || str[i] > '9') {
            return 0;
        }
    }
    
    return 1;
}

int main(int argc, char *argv[]) {

    if (argc != 2) {
        printf("Использование: %s n\n", argv[0]);
        return 1;
    }
    

    if (!is_valid_number(argv[1])) {
        printf("Ошибка: n должно быть целым положительным числом\n");
        return 1;
    }
    
    long long n = atoll(argv[1]);
    
    if (n <= 0) {
        printf("Ошибка: n должно быть положительным числом\n");
        return 1;
    }
    
    
    long long result = calculate_result(n);
    
    printf("Количество чисел от 1 до %lld, делящихся на 37 и 13: %lld\n", n, result);
    
    return 0;
}