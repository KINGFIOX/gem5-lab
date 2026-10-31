#!/bin/bash
# Lab 2 一键实验脚本 —— 在 devcontainer 内执行（无 docker，直接调用 gem5）
# 用法: bash run-all.sh [seq|random|gemm|all]   (默认 all; 可只重跑某个 Lab2-2 基准)
# 前置: gem5.opt 已构建; 在 gem5-lab 仓库根目录执行
set -u
cd "$(dirname "$0")"   # 仓库根
FILTER="${1:-all}"

status=/tmp/xp-status-$$.txt
: > "$status"

run() {  # run <名字> <命令...>（后台）
    local name=$1; shift
    "$@" > /tmp/xp-$name.log 2>&1 &
    local pid=$!
    echo "$name pid=$pid" >> "$status"
}

# ---- Lab 2-1: 5 组，TimingSimple/Minor，很快 ----
run lab21 bash ucas/Lab2-1/run_lab21.sh

# ---- Lab 2-2: 每基准一个后台进程，内部 7 组串行 ----
if [ "$FILTER" = all ] || [ "$FILTER" = seq ]; then
    run lab22_seq bash -c 'GEM5=./build/X86/gem5.opt; CFG=./tests/ucas/Lab2-2/lab22.py
        run1() { echo "== $1 =="; $GEM5 -d m5out/lab22_$1 $CFG --binary ./tests/ucas/Lab2-2/bench_seq ${@:2} 2>&1 | grep -E "Beginning|Exiting|fatal"; }
        run1 seq_base --l2-size 256KiB
        run1 seq_nol2 --l2-size none
        run1 seq_freq4 --l2-size none --cpu-freq 4GHz
        run1 seq_iw2 --l2-size none --issue-width 2
        run1 seq_l2_4way --l2-size 256KiB --l2-assoc 4
        run1 seq_l2_2m --l2-size 2MiB
        run1 seq_l2_16m --l2-size 16MiB
        cp m5out/lab22_seq_base/stats.txt ./tests/ucas/Lab2-2/bench_seq-stats.txt
        echo LAB22_seq_DONE'
fi

if [ "$FILTER" = all ] || [ "$FILTER" = random ]; then
    run lab22_random bash -c 'GEM5=./build/X86/gem5.opt; CFG=./tests/ucas/Lab2-2/lab22.py
        run1() { echo "== $1 =="; $GEM5 -d m5out/lab22_$1 $CFG --binary ./tests/ucas/Lab2-2/bench_random ${@:2} 2>&1 | grep -E "Beginning|Exiting|fatal"; }
        run1 random_base --l2-size 256KiB
        run1 random_nol2 --l2-size none
        run1 random_freq4 --l2-size none --cpu-freq 4GHz
        run1 random_iw2 --l2-size none --issue-width 2
        run1 random_l2_4way --l2-size 256KiB --l2-assoc 4
        run1 random_l2_2m --l2-size 2MiB
        run1 random_l2_16m --l2-size 16MiB
        cp m5out/lab22_random_base/stats.txt ./tests/ucas/Lab2-2/bench_random-stats.txt
        echo LAB22_random_DONE'
fi

if [ "$FILTER" = all ] || [ "$FILTER" = gemm ]; then
    run lab22_gemm bash -c 'GEM5=./build/X86/gem5.opt; CFG=./tests/ucas/Lab2-2/lab22.py
        run1() { echo "== $1 =="; $GEM5 -d m5out/lab22_$1 $CFG --binary ./tests/ucas/Lab2-2/bench_gemm ${@:2} 2>&1 | grep -E "Beginning|Exiting|fatal"; }
        run1 gemm_base --l2-size 256KiB
        run1 gemm_nol2 --l2-size none
        run1 gemm_freq4 --l2-size none --cpu-freq 4GHz
        run1 gemm_iw2 --l2-size none --issue-width 2
        run1 gemm_l2_4way --l2-size 256KiB --l2-assoc 4
        run1 gemm_l2_2m --l2-size 2MiB
        run1 gemm_l2_16m --l2-size 16MiB
        cp m5out/lab22_gemm_base/stats.txt ./tests/ucas/Lab2-2/bench_gemm-stats.txt
        echo LAB22_gemm_DONE'
fi

# ---- Lab 2-3: LRU vs NMRU ----
run lab23 bash ucas/Lab2-3/run_lab23.sh

wait
echo "ALL DONE $(date)" >> "$status"
cat "$status"
