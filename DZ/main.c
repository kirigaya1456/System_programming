#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

extern void* q_create(size_t capacity);
extern void q_destroy(void* queue);
extern int q_push(void* queue, int64_t value);
extern int q_pop(void* queue, int64_t* out_val);
extern void q_fill_random(void* queue, int count);
extern int q_count_primes(void* queue);
extern int q_get_odds(void* queue, int64_t* out_arr);
extern void q_filter_evens(void* queue);


void print_queue_state(void* q) {
    int64_t buffer[100];
    int count = 0;
    
    
    printf("[ИНФОРМАЦИЯ] Операции с очередью выполняются...\n");
}

int main() {
    printf("=== Демонстрация очереди сборки (ELF64/mmap) ===\n");

    // 1. Создание очереди
    size_t cap = 20;
    void* q = q_create(cap);
    if (!q) {
        perror("Не удалось создать очередь");
        return 1;
    }
    printf("[1] Очередь создана с емкостью %zu.\n", cap);

    printf("[2] Заполнение 15 случайными числами (0-99)...\n");
    q_fill_random(q, 15);

 
    int64_t odds[20];
    int odd_count = q_get_odds(q, odds);
    printf("[3] Нечетные числа в очереди (%d found): ", odd_count);
    for(int i=0; i<odd_count; i++) {
        printf("%ld ", odds[i]);
    }
    printf("\n");

    int primes = q_count_primes(q);
    printf("[4] Простые числа считаются: %d\n", primes);

    printf("[5] фильтрация событий (сохранение шансов, ротация очереди)...\n");
    q_filter_evens(q);

    printf("[6] Окончательное содержимое очереди (удаление всего):\n");
    int64_t val;
    int idx = 0;
    while(q_pop(q, &val)) {
        printf("[%d]: %ld\n", idx++, val);
    }

    q_destroy(q);
    printf("[7] Очередь уничтожена.\n");

    return 0;
}