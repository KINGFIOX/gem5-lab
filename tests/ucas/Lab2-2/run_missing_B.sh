#!/bin/bash
bash ./tests/ucas/build.sh
# 补跑 random 的缺失配置（在 gem5-lab 仓库根目录下执行）
set -u
GEM5=./build/X86/gem5.opt
CFG=./tests/ucas/Lab2-2/lab22.py
run1() {
    echo "== $1 =="
    $GEM5 -d m5out/lab22_$1 $CFG --binary ./tests/ucas/Lab2-2/bench_$2 ${@:3} 2>&1 | grep -E "Beginning|Exiting|fatal"
}
run1 random_nol2   random --l2-size none
run1 random_freq4  random --l2-size none --cpu-freq 4GHz
run1 random_iw2    random --l2-size none --issue-width 2
run1 random_l2_2m  random --l2-size 2MiB
run1 random_l2_16m random --l2-size 16MiB
cp m5out/lab22_random_base/stats.txt ./tests/ucas/Lab2-2/bench_random-stats.txt
echo FIXB_DONE
