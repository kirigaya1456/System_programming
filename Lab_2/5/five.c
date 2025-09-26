#include <unistd.h>

int main() {
    char number[] = "5277616985";
    int sum = 0;
    
    for (char *p = number; *p; p++) {
        sum += *p - '0';
    }
    
    char buffer[16];
    char *ptr = buffer + 15;
    *ptr = '\n';
    
    int n = sum;
    do {
        *--ptr = '0' + (n % 10);
        n /= 10;
    } while (n > 0);
    
    write(1, ptr, buffer + 16 - ptr);
    return 0;
}