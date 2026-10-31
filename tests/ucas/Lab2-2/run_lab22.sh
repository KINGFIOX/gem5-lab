#!/bin/bash
# Lab 2.2 自动化脚本: 3 个基准 x 7 组配置
# 在 gem5-lab 仓库根目录 (/workspaces/gem5-lab) 下执行
set -e
bash ./tests/ucas/build.sh   # 二进制缺失/过期时自动编译
GEM5=./build/X86/gem5.opt
BIN_DIR=./tests/ucas/Lab2-2
CFG=./tests/ucas/Lab2-2/lab22.py

BENCHES="seq random gemm"

# 7 组配置: name extra-args
declare -A CFGS=(
    [base]=""                                              # iw8 1GHz L2 256KiB 8way (默认初始配置)
    [nol2]="--l2-size none"                                # iw8 1GHz 无 L2
    [freq4]="--l2-size none --cpu-freq 4GHz"               # iw8 4GHz 无 L2
    [iw2]="--l2-size none --issue-width 2"                 # iw2 1GHz 无 L2
    [l2_4way]="--l2-assoc 4"                               # iw8 1GHz L2 256KiB 4way
    [l2_2m]="--l2-size 2MiB"                               # iw8 1GHz L2 2MiB 8way
    [l2_16m]="--l2-size 16MiB"                             # iw8 1GHz L2 16MiB 8way
)

for b in $BENCHES; do
    for c in base nol2 freq4 iw2 l2_4way l2_2m l2_16m; do
        out=m5out/lab22_${b}_${c}
        echo "===== $b / $c ====="
        $GEM5 -d $out $CFG --binary $BIN_DIR/bench_$b ${CFGS[$c]} \
            2>&1 | grep -E "Beginning|Exiting" || true
    done
done

echo "===== 汇总: sim_seconds / sim_insts / IPC / L2 总缺失 ====="
printf "%-22s %12s %14s %8s %10s\n" run sim_sec sim_insts IPC L2_misses
for b in $BENCHES; do
    for c in base nol2 freq4 iw2 l2_4way l2_2m l2_16m; do
        d=m5out/lab22_${b}_${c}/stats.txt
        sim=$(awk '/^simSeconds/ {print $2; exit}' $d)
        ins=$(awk '/^sim_insts/ {print $2; exit}' $d)
        ipc=$(awk '/^system\.cpu\.ips/ {print $2; exit}' $d)
        l2m=$(awk '/^system\.l2\.overall_misses::total/ {print $2; exit}' $d)
        printf "%-22s %12.6f %14s %8.3f %10s\n" "${b}_${c}" "$sim" "$ins" "$ipc" "${l2m:--}"
    done
done
# 提交要求: 默认配置每个基准的 stats.txt
for b in $BENCHES; do
    cp m5out/lab22_${b}_base/stats.txt $BIN_DIR/bench_${b}-stats.txt
done
echo "done: $BIN_DIR/bench_*-stats.txt"
