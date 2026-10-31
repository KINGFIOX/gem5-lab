/* Lab 2.3: 缓存替换策略对比负载 (cache_test.cpp)
 *
 * 设计: 在 512 KiB（= 2 x L2 容量）缓冲区上构造一个"地址顺序"的指针环
 * next[i] = i+1（模 N 回绕），沿环追逐 N*ROUNDS 步。
 *
 * 两个关键要素:
 * 1) 循环工作集 > 缓存容量 —— 攻击 LRU 的根本机制。
 *    工作集 8192 行 > L2 4096 行(256 KiB, 8 路 x 512 组, 平均每组约
 *    16 行 >> 8 路)。按固定顺序循环访问:
 *      - 严格 LRU: 组内按新旧排队, 缺失时淘汰"最旧"——固定循环下被淘汰
 *        的恰是下一圈最早回来的行, 稳态命中率 ~0 (LRU 对循环工作集是
 *        最坏策略);
 *      - NMRU: 只保护 MRU 一行, 其余 7 路等概率随机淘汰——淘汰与访问
 *        顺序解耦, 部分行存活到下一圈被命中, 命中率显著 > 0。
 *
 * 2) 指针追逐(数据依赖链) —— 消除乱序执行的访存级并行(MLP)。
 *    若用普通的顺序扫描(for i: sum+=buf[i]), O3CPU 可以同时挂起几十
 *    个未决缺失, 延迟互相重叠, LRU/NMRU 的命中率差(0% vs ~16%)只折
 *    算成 ~2.6% 时间差。改为 cur = next[cur] 后每次加载的地址依赖上一
 *    次加载的值, 依赖链完全串行, 每次 L2 命中都直接缩短关键路径,
 *    命中率差异被完整放大成时间差异(目标 >10%)。
 *    (地址顺序与 i+1 一致, 但 CPU 只有拿到加载值才知道下一跳地址。)
 *
 * 为什么不用"同组 W+1 块"的教科书式冲突攻击:
 *    gem5 SE 模式的进程页表把虚拟页映射到任意物理帧, 虚拟地址上按
 *    "512 组 x 64B = 32 KiB 步长"构造的同组间距经虚实转换后不再落在
 *    同一组(实测 9 块循环在 L1/L2 全命中), 经典缓存按物理地址索引,
 *    因此改用与物理映射无关的容量型攻击。
 */
#include <stdint.h>

#include <cstdio>
#include <cstdlib>

#ifndef SIZE
#define SIZE     (512 * 1024)   /* 工作集: 512 KiB = 2 x L2 (8192 行) */
#endif
#define N        (SIZE / 8)     /* 环上节点数 */
#ifndef ROUNDS
#define ROUNDS   100            /* 环上圈数 (共 N*ROUNDS 次加载) */
#endif

static uint64_t *next_;

static volatile uint64_t sink;

int main(void)
{
    /* 构造地址顺序的环: next[i] = i+1, 末节点回指 0 */
    next_ = (uint64_t *)malloc(SIZE);
    for (uint64_t i = 0; i < N; i++)
        next_[i] = (i + 1) % N;

    /* 沿环追逐: cur 的值就是下一跳的地址索引(串行依赖链) */
    uint64_t cur = 0;
    for (int r = 0; r < ROUNDS; r++)
        for (uint64_t k = 0; k < N; k++) {
            cur = next_[cur];
            sink += cur;
        }

    printf("cache_test cur=%llu\n", (unsigned long long)cur);
    return 0;
}
