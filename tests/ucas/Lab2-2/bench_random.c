/* Lab2-2 基准 2: 随机扫描 (random scan)
 * 特征: Memory Regularity 低（地址不可预测）、Memory Intensity 高、局部性差（每次访问不同缓存行），
 *       延迟受限（每次访问都可能缺失，乱序窗口难以完全掩盖长延迟）
 * 同样 64MiB 数组，用 xorshift64 生成伪随机下标做 gather-sum。
 * xorshift64 状态固定，SE 模式下无文件 IO，可复现。
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define N (8u * 1024u * 1024u)   /* 8M elements = 64 MiB */
#define ITER (8u * 1024u * 1024u)

static uint64_t *buf;

static inline uint64_t xorshift64(uint64_t *s)
{
    uint64_t x = *s;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    *s = x;
    return x;
}

int main(void)
{
    buf = malloc(N * sizeof(uint64_t));
    for (uint64_t i = 0; i < N; i++)
        buf[i] = i;

    uint64_t prng = 0x20261028ULL;
    uint64_t sum = 0;
    for (uint64_t i = 0; i < ITER; i++)
        sum += buf[xorshift64(&prng) % N];

    printf("random_scan sum=%llu\n", (unsigned long long)sum);
    return 0;
}
