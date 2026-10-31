#!/bin/bash
# Lab 2.3 自动化脚本: LRU vs NMRU (初始配置, se_rp.py = se.py + --rp)
# 在 gem5-lab 仓库根目录 (/workspaces/gem5-lab) 下执行
set -e
bash ./tests/ucas/build.sh   # 二进制缺失/过期时自动编译
GEM5=./build/X86/gem5.opt
BIN=./tests/ucas/Lab2-3/cache_test
CFG=./tests/ucas/Lab2-3/se_rp.py
COMMON="--cmd $BIN --cpu-type=O3CPU --caches --l2cache \
  --l1d_size=64kB --l1i_size=32kB --l1d_assoc=2 --l1i_assoc=2 \
  --l2_size=256kB --l2_assoc=8 --cpu-clock=1GHz --mem-type=DDR3_1600_8x8"

for rp in lru nmru; do
    RPU=${rp^^}RP   # lru->LRURP, nmru->NMRURP
    echo "===== $RPU ====="
    $GEM5 -d m5out/lab23_$rp $CFG $COMMON --rp $RPU 2>&1 | grep -E "Beginning|Exiting|replacement" || true
done

echo "===== 对比 ====="
for rp in lru nmru; do
    d=m5out/lab23_$rp/stats.txt
    sim=$(awk '/^simSeconds/ {print $2; exit}' $d)
    ins=$(awk '/^simInsts/ {print $2; exit}' $d)
    l2m=$(awk '/^system\.l2\.demandMisses::total/ {print $2; exit}' $d)
    l2h=$(awk '/^system\.l2\.demandHits::total/ {print $2; exit}' $d)
    printf "%-6s simSeconds=%-12s insts=%-12s L2_hits=%-10s L2_misses=%s\n" $rp "$sim" "$ins" "$l2h" "$l2m"
done
python3 - <<'EOF'
lru = float(open('m5out/lab23_lru/stats.txt').read().split('simSeconds')[1].split()[0])
nmru = float(open('m5out/lab23_nmru/stats.txt').read().split('simSeconds')[1].split()[0])
print(f"性能差异: {(lru-nmru)/lru*100:.2f}% (LRU 比 NMRU 慢的比例)")
EOF
cp m5out/lab23_lru/stats.txt  ./tests/ucas/Lab2-3/lru_stats.txt
cp m5out/lab23_nmru/stats.txt ./tests/ucas/Lab2-3/nmru_stats.txt
echo "done: ./tests/ucas/Lab2-3/{lru,nmru}_stats.txt"
