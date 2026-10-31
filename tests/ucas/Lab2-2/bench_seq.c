/* Lab2-2 基准 1: 顺序扫描 (sequential scan)
 * 特征: Memory Regularity 高（地址完全可预测）、Memory Intensity 高（每迭代 1 load 1 add）、
 *       时间局部性差（64MB 工作集远大于 L2，无复用）、控制规律性高（无分支）
 * 64MB 数组 = 8M 个 uint64，单遍求和。工作集 >> 16MiB(最大受测 L2)，容量缺失主导。
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define N (8u * 1024u * 1024u)   /* 8M elements = 64 MiB */

static uint64_t *buf;

int main(void)
{
    buf = malloc(N * sizeof(uint64_t));
    for (uint64_t i = 0; i < N; i++)
        buf[i] = i;

    uint64_t sum = 0;
    for (uint64_t i = 0; i < N; i++)
        sum += buf[i];

    printf("seq_scan sum=%llu\n", (unsigned long long)sum);
    return 0;
}
