# Lab 2.3 Exploring Cache Replacement Policy 实验报告

## 1. a) NMRU 策略实现说明

以 `src/mem/cache/replacement_policies/lru_rp.*` 为基础拷贝为 `nmrp_rp.*`，类名 `LRU`→`NMRU`，
替换数据仍用 `lastTouchTick` 时间戳（`invalidate`/`touch`/`reset` 与 LRU 完全一致）。
**唯一实质修改在 `getVictim()`**：

```cpp
// 第一步：找 MRU（lastTouchTick 最大的候选）
ReplaceableEntry* mru = candidates[0];
for (const auto& candidate : candidates)
    if (cast(candidate)->lastTouchTick > cast(mru)->lastTouchTick)
        mru = candidate;

// 第二步：在其余候选中随机选受害者
ReplaceableEntry* victim = candidates[0];
if (candidates.size() > 1)
    do {
        victim = candidates[rng->random<unsigned>(0, candidates.size() - 1)];
    } while (victim == mru);
```

与 LRU 的区别：LRU 固定淘汰时间戳最小的块；NMRU 只保护 MRU 一个块，其余等概率随机淘汰。
随机数生成器复用 gem5 的 `gem5::Random::genRandom()`（同 `random_rp.cc` 的用法）。
顺带发现：2 路组内 NMRU 退化为 LRU（除 MRU 外只剩 1 个候选）。

## 2. b) 接入模拟器的步骤

1. **注册到 scons**：`src/mem/cache/replacement_policies/SConscript` 的 `sim_objects` 列表加
   `'NMRURP'`，并添加 `Source('nmrp_rp.cc')`；
2. **添加到 Python 类**：`ReplacementPolicies.py` 新增
   `class NMRURP(BaseReplacementPolicy)`，指向 `cxx_class = "gem5::replacement_policy::NMRU"`、
   `cxx_header = "mem/cache/replacement_policies/nmrp_rp.hh"`；
3. **重新编译**：`scons build/X86/gem5.opt -j8`（增量编译，自动生成 `params/NMRURP.hh`）；
4. **在配置脚本中使用**：`se.py` 拷贝为 `configs/deprecated/example/se_rp.py`，新增
   `--rp {LRURP,NMRURP,...}` 参数，在 `CacheConfig.config_cache()` 之后把所选策略实例赋给
   `cpu.icache/dcache` 与 `system.l2` 的 `replacement_policy` 字段（应用到所有 classic cache 层）。

运行命令（配置同 Lab 2.2 初始参数）：

```bash
./build/X86/gem5.opt -d m5out/lab23_lru configs/deprecated/example/se_rp.py \
  --cmd cache_test --cpu-type=O3CPU --caches --l2cache \
  --l1d_size=64kB --l1i_size=32kB --l1d_assoc=2 --l1i_assoc=2 \
  --l2_size=256kB --l2_assoc=8 --cpu-clock=1GHz --mem-type=DDR3_1600_8x8 --rp LRURP
# 同上，--rp NMRURP -d m5out/lab23_nmru
```

## 3. c) 负载设计：为什么能"攻击" LRU

**最终负载**：在 512 KiB（= 2×L2）缓冲区上构造地址顺序的指针环 `next[i]=i+1`，
`cur = next[cur]` 沿环追逐 100 圈（6.55M 次加载）。两个关键要素：

1. **循环工作集 > 缓存容量**：工作集 8192 行 > L2 4096 行（256 KiB，8 路×512 组，
   平均每组 ~16 行 >> 8 路）。固定顺序循环访问下：
   - **严格 LRU** 淘汰"最旧"的行——而固定循环下最旧的恰是下一圈最早回来的行，
     稳态命中率 ≈ 0（**LRU 对循环工作集是最坏策略**，实测 L2 命中 22 次 / 829,174 缺失）；
   - **NMRU** 只保护 MRU，其余 7 路随机淘汰——淘汰与访问顺序解耦，部分行存活到
     下一圈被命中（实测 132,610 次命中，16.0% 命中率）。
2. **指针追逐消除访存级并行（MLP）**：若用普通顺序扫描，O3CPU 可同时挂起几十个
   未决缺失把延迟重叠掉，命中率差只折算成 2.59% 的时间差（我们实测过）；
   `cur = next[cur]` 使每次加载地址依赖上一次加载的值，依赖链完全串行，
   每次 L2 命中都直接缩短关键路径，命中率差异被完整放大。

**过程中的重要发现（为什么不用教科书式的"同组 W+1 块"冲突攻击）**：
最初按经典方法用 9 个块、32 KiB 步长（=512 组×64B）构造同组循环，实测两种策略下
**全部命中**（demandHits ≈ 总访问数）。原因：gem5 SE 模式的进程页表把每个虚拟页
映射到**任意物理帧**，虚拟地址上的"同组间距"经虚实转换后物理地址落在伪随机
物理页上，不再共组——经典缓存按**物理地址**索引。因此改用与物理映射无关的
**容量型**攻击（循环工作集 > 缓存容量），它在任何地址映射下都成立。

## 4. 实验结果

| 工作集 | 策略 | simSeconds | L2 hits | L2 misses | L2 命中率 |
|---|---|---|---|---|---|
| 512 KiB（默认） | LRU | 0.100732 | 22 | 829,174 | ≈0% |
| 512 KiB（默认） | NMRU | 0.090904 | 132,610 | 696,586 | 16.0% |
| **384 KiB（调优）** | LRU | 0.075571 | 24 | 622,333 | ≈0% |
| **384 KiB（调优）** | NMRU | 0.058901 | 227,634 | 394,723 | 36.6% |

- **默认工作集（512 KiB = 2×L2）：性能差异 9.76%**（(LRU−NMRU)/LRU），远超 2% 的通过线；
- **调优工作集（384 KiB = 1.5×L2，平均 12 行/组）：性能差异 22.06%**——LRU 仍 ≈0% 命中，
  NMRU 命中率升到 36.6%。

**放大差异的思路（思考题，目标 10%）**：两个杠杆——
① 用指针追逐消除 MLP（见 §3，否则命中率差被乱序执行的重叠访存稀释成 ~2.6%）；
② 缩小工作集到刚超过 L2 容量（512→384 KiB），组内竞争从 16 行/组降到 12 行/组，
NMRU 随机淘汰下行的存活概率大幅上升，而 LRU 在任何 > 容量的循环下都保持 0%——
差异从 9.76% 放大到 **22.06%**。

## 5. 提交文件

- `cache_test.cpp`（源码，默认 512 KiB 工作集；`-DSIZE=393216` 编译 384 KiB 变体）
- `lru_stats.txt`、`nmru_stats.txt`（默认 512 KiB 的主对比）
- `lru_512k_stats.txt` / `nmru_512k_stats.txt`、`lru_384k_stats.txt` / `nmru_384k_stats.txt`（原始数据）
- `se_rp.py`（配置脚本）、`run_lab23.sh`（自动化脚本）
- `nmrp_rp.hh`、`nmrp_rp.cc`（NMRU 实现，也已在 gem5-lab 仓库中提交：commit 70a214eb60）
