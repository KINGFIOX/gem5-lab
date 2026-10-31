/* Lab2-2 基准 3: 分块矩阵乘 (tiled GEMM)
 * 特征: 算术强度高（每 2 次访存 ~2*N_tile 次 FMA）、局部性好（分块后 A/B/C 片驻留缓存）、
 *       控制规律性高（规则嵌套循环）、访存强度相对低 —— 计算受限型负载
 * 384x384 float，64 分块：三个 64x64x4B=16KiB 块片，总活跃数据 < 64KiB，L1/L2 均可容纳。
 */
#include <stdio.h>
#include <stdlib.h>

#define DIM 384
#define TILE 64

static float *A, *B, *C;

int main(void)
{
    A = malloc(DIM * DIM * sizeof(float));
    B = malloc(DIM * DIM * sizeof(float));
    C = malloc(DIM * DIM * sizeof(float));
    for (int i = 0; i < DIM * DIM; i++) {
        A[i] = (float)(i % 7) * 0.5f;
        B[i] = (float)(i % 5) * 0.25f;
        C[i] = 0.0f;
    }

    for (int ii = 0; ii < DIM; ii += TILE)
        for (int jj = 0; jj < DIM; jj += TILE)
            for (int kk = 0; kk < DIM; kk += TILE)
                for (int i = ii; i < ii + TILE; i++)
                    for (int j = jj; j < jj + TILE; j++) {
                        float c = C[i * DIM + j];
                        for (int k = kk; k < kk + TILE; k++)
                            c += A[i * DIM + k] * B[k * DIM + j];
                        C[i * DIM + j] = c;
                    }

    printf("gemm C[0]=%f C[last]=%f\n", C[0], C[DIM * DIM - 1]);
    return 0;
}
