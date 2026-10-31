/* Lab 2.1: 将学号做质因数分解（非数字字符用 0 替代）
 * 学号 2026E8013282153 -> 202608013282153 (E -> 0)
 * 编译: gcc -O2 -static -DNUMBER=202608013282153ULL -o factor factor.c
 * 反写学号: -DNUMBER=351282310806202ULL
 * 算法: 试除法，从小到大枚举除数 d，整除则除尽，d*d > n 时剩余的 n 即最大质因子
 */
#include <stdint.h>
#include <stdio.h>

#ifndef NUMBER
#define NUMBER 202608013282153ULL
#endif

int main(void)
{
    uint64_t n = NUMBER;
    uint64_t d = 2;

    printf("factorizing %llu:\n", (unsigned long long)n);
    while (d * d <= n) {
        while (n % d == 0) {
            printf("  %llu\n", (unsigned long long)d);
            n /= d;
        }
        d++;
    }
    if (n > 1)
        printf("  %llu\n", (unsigned long long)n);
    printf("done\n");
    return 0;
}
