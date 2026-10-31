#!/bin/bash
# Lab 2.1 自动化脚本: 学号质因数分解 5 组对比实验
# 在 gem5-lab 仓库根目录 (/workspaces/gem5-lab) 下执行
set -e
bash ./tests/ucas/build.sh   # 二进制缺失/过期时自动编译
GEM5=./build/X86/gem5.opt
BIN_DIR=./tests/ucas/Lab2-1            # factor / factor_rev
CFG=configs/learning_gem5/part1/lab21.py

run() {  # run <name> <extra-args...>
    local name=$1; shift
    echo "===== $name: $* ====="
    $GEM5 -d m5out/lab21_$name $CFG --binary $BIN_DIR/$1 --cpu $2 --freq $3 --mem $4 \
        2>&1 | grep -E "Beginning|Exiting|factor|done|factorizing" || true
}

# 实验 1: 学号 vs 反写学号 (TimingSimple, 1GHz, DDR3_1600)
run timing_num   factor      TimingSimple 1GHz DDR3_1600_8x8
run timing_rev   factor_rev  TimingSimple 1GHz DDR3_1600_8x8
# 实验 2: CPU 型号 (较慢输入=学号): TimingSimple vs Minor
run minor_num    factor      Minor        1GHz DDR3_1600_8x8
# 实验 3: 频率 1GHz -> 2GHz
run freq2_num    factor      TimingSimple 2GHz DDR3_1600_8x8
# 实验 4: 内存 DDR3_1600_8x8 -> DDR3_2133_8x8
run mem2133_num  factor      TimingSimple 1GHz DDR3_2133_8x8

echo "===== 汇总 (simSeconds / hostSeconds) ====="
for d in m5out/lab21_*; do
    printf "%-20s sim=%-14s host=%s\n" "$(basename $d)" \
        "$(grep -m1 '^simSeconds' $d/stats.txt | awk '{print $2}')" \
        "$(grep -m1 '^hostSeconds' $d/stats.txt | awk '{print $2}')"
done
# 提交要求的文件
cp m5out/lab21_timing_num/stats.txt ./tests/ucas/Lab2-1/TimingSimpleCPU-stats.txt
cp m5out/lab21_minor_num/stats.txt  ./tests/ucas/Lab2-1/MinorCPU-stats.txt
echo "done: ./tests/ucas/Lab2-1/{TimingSimpleCPU,MinorCPU}-stats.txt"
