#!/bin/bash
# 构建全部实验二进制（缺失或源码更新时才重编）。二进制是构建产物，不入 git（见 .gitignore）。
set -e
cd "$(dirname "$0")"

build() {  # build <src> <bin> [flags...]
    local src=$1 bin=$2; shift 2
    if [ -x "$bin" ] && [ ! "$src" -nt "$bin" ]; then return 0; fi
    echo "(build $bin)"
    case "$src" in
        *.c) gcc -O2 -static "$@" -o "$bin" "$src" ;;
        *)   g++ -O2 -static "$@" -o "$bin" "$src" ;;
    esac
}

(cd Lab2-1 && build factor.c factor -DNUMBER=202608013282153ULL \
                && build factor.c factor_rev -DNUMBER=351282310806202ULL)
(cd Lab2-2 && build bench_seq.c bench_seq \
                && build bench_random.c bench_random && build bench_gemm.c bench_gemm)
(cd Lab2-3 && build cache_test.cpp cache_test)
echo "binaries ready."
