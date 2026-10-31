"""Lab 2.1 配置脚本 —— 以 configs/learning_gem5/part1/simple.py 为基础修改。

改动点（相对 simple.py）：
1. 二进制路径、CPU 型号、时钟频率、内存型号改为命令行参数，便于对比实验；
2. 其余（512MiB 内存、membus、中断控制器、SE 模式）保持不变。

用法示例：
  ./build/X86/gem5.opt -d m5out/timing_num configs/learning_gem5/part1/lab21.py \
      --binary <path> --cpu TimingSimple --freq 1GHz --mem DDR3_1600_8x8
"""

import argparse
import os

import m5
from m5.objects import *

parser = argparse.ArgumentParser()
parser.add_argument("--binary", required=True, help="被模拟的 x86 二进制")
parser.add_argument(
    "--cpu", default="TimingSimple", choices=["TimingSimple", "Minor"]
)
parser.add_argument("--freq", default="1GHz")
parser.add_argument(
    "--mem",
    default="DDR3_1600_8x8",
    choices=["DDR3_1600_8x8", "DDR3_2133_8x8"],
)
args = parser.parse_args()

system = System()

system.clk_domain = SrcClockDomain()
system.clk_domain.clock = args.freq
system.clk_domain.voltage_domain = VoltageDomain()

system.mem_mode = "timing"  # MinorCPU 也要求 timing 模式
system.mem_ranges = [AddrRange("512MiB")]

if args.cpu == "TimingSimple":
    system.cpu = X86TimingSimpleCPU()
else:
    system.cpu = X86MinorCPU()

system.membus = SystemXBar()

system.cpu.icache_port = system.membus.cpu_side_ports
system.cpu.dcache_port = system.membus.cpu_side_ports

system.cpu.createInterruptController()
system.cpu.interrupts[0].pio = system.membus.mem_side_ports
system.cpu.interrupts[0].int_requestor = system.membus.cpu_side_ports
system.cpu.interrupts[0].int_responder = system.membus.mem_side_ports

system.mem_ctrl = MemCtrl()
if args.mem == "DDR3_1600_8x8":
    system.mem_ctrl.dram = DDR3_1600_8x8()
else:
    system.mem_ctrl.dram = DDR3_2133_8x8()
system.mem_ctrl.dram.range = system.mem_ranges[0]
system.mem_ctrl.port = system.membus.mem_side_ports

system.system_port = system.membus.cpu_side_ports

system.workload = SEWorkload.init_compatible(args.binary)
process = Process()
process.cmd = [args.binary]
system.cpu.workload = process
system.cpu.createThreads()

root = Root(full_system=False, system=system)
m5.instantiate()

print(
    f"Beginning simulation! binary={args.binary} cpu={args.cpu} "
    f"freq={args.freq} mem={args.mem}"
)
exit_event = m5.simulate()
print(f"Exiting @ tick {m5.curTick()} because {exit_event.getCause()}")
