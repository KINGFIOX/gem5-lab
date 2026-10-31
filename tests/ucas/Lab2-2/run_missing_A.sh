#!/bin/bash
bash ./tests/ucas/build.sh
# 补跑 no-L2 等缺失配置（在 gem5-lab 仓库根目录下执行）
set -u
GEM5=./build/X86/gem5.opt
CFG=./tests/ucas/Lab2-2/lab22.py
run1() {
    echo "== $1 =="
    $GEM5 -d m5out/lab22_$1 $CFG --binary ./tests/ucas/Lab2-2/bench_$2 ${@:3} 2>&1 | grep -E "Beginning|Exiting|fatal"
}
# ---- A: seq + gemm 的 no-L2 三组 ----
run1 seq_nol2   seq --l2-size none
run1 seq_freq4  seq --l2-size none --cpu-freq 4GHz
run1 seq_iw2    seq --l2-size none --issue-width 2
run1 gemm_nol2  gemm --l2-size none
run1 gemm_freq4 gemm --l2-size none --cpu-freq 4GHz
run1 gemm_iw2   gemm --l2-size none --issue-width 2
echo FIXA_DONE
