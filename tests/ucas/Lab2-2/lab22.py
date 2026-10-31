"""Lab 2.2 配置脚本 —— 以 configs/learning_gem5/part1/two_level.py 的结构为基础，
参数化初始配置的全部微架构参数（O3CPU / 1GHz / DDR3_1600_8x8 / L1I 32KB 2-way /
L1D 64KB 2-way / L2 256KB 8-way / issue width 8），用于 7 组对比实验。

用法示例（默认初始配置）:
  ./build/X86/gem5.opt -d m5out/seq_base configs/lab22.py --binary bench_seq
无 L2 组合:
  ./build/X86/gem5.opt -d m5out/seq_nol2 configs/lab22.py --binary bench_seq --l2-size none
"""

import argparse

import m5
from m5.objects import *

parser = argparse.ArgumentParser()
parser.add_argument("--binary", required=True)
parser.add_argument("--cpu-type", default="O3CPU")
parser.add_argument("--issue-width", type=int, default=8)
parser.add_argument("--cpu-freq", default="1GHz")
parser.add_argument("--mem-type", default="DDR3_1600_8x8")
parser.add_argument("--l1i-size", default="32KiB")
parser.add_argument("--l1i-assoc", type=int, default=2)
parser.add_argument("--l1d-size", default="64KiB")
parser.add_argument("--l1d-assoc", type=int, default=2)
parser.add_argument("--l2-size", default="256KiB", help="none 表示去掉 L2")
parser.add_argument("--l2-assoc", type=int, default=8)
args = parser.parse_args()

system = System()
system.clk_domain = SrcClockDomain()
system.clk_domain.clock = args.cpu_freq
system.clk_domain.voltage_domain = VoltageDomain()
system.mem_mode = "timing"  # O3CPU 必须使用 timing 模式
system.mem_ranges = [AddrRange("512MiB")]

# ---- CPU ----
if args.cpu_type == "O3CPU":
    system.cpu = X86O3CPU()
    system.cpu.issueWidth = args.issue_width
elif args.cpu_type == "MinorCPU":
    system.cpu = X86MinorCPU()
elif args.cpu_type == "TimingSimpleCPU":
    system.cpu = X86TimingSimpleCPU()
else:
    raise ValueError(f"unknown cpu {args.cpu_type}")

# ---- 缓存层次 ----
system.membus = SystemXBar()


class L1ICache(Cache):
    size = args.l1i_size
    assoc = args.l1i_assoc
    tag_latency = 2
    data_latency = 2
    response_latency = 2
    mshrs = 4
    tgts_per_mshr = 20


class L1DCache(Cache):
    size = args.l1d_size
    assoc = args.l1d_assoc
    tag_latency = 2
    data_latency = 2
    response_latency = 2
    mshrs = 4
    tgts_per_mshr = 20


class L2Cache(Cache):
    tag_latency = 20
    data_latency = 20
    response_latency = 20
    mshrs = 20
    tgts_per_mshr = 12
    assoc = args.l2_assoc
    size = args.l2_size if args.l2_size != "none" else "256KiB"


system.l1i = L1ICache()
system.l1d = L1DCache()

if args.l2_size == "none":
    # 无 L2：L1 直接接 membus
    system.l1i.cpu_side = system.cpu.icache_port
    system.l1i.mem_side = system.membus.cpu_side_ports
    system.l1d.cpu_side = system.cpu.dcache_port
    system.l1d.mem_side = system.membus.cpu_side_ports
else:
    system.l2bus = L2XBar()
    system.l2 = L2Cache()
    system.l1i.cpu_side = system.cpu.icache_port
    system.l1i.mem_side = system.l2bus.cpu_side_ports
    system.l1d.cpu_side = system.cpu.dcache_port
    system.l1d.mem_side = system.l2bus.cpu_side_ports
    system.l2.cpu_side = system.l2bus.mem_side_ports
    system.l2.mem_side = system.membus.cpu_side_ports

system.cpu.createInterruptController()
system.cpu.interrupts[0].pio = system.membus.mem_side_ports
system.cpu.interrupts[0].int_requestor = system.membus.cpu_side_ports
system.cpu.interrupts[0].int_responder = system.membus.mem_side_ports

# ---- 内存 ----
system.mem_ctrl = MemCtrl()
system.mem_ctrl.dram = globals()[args.mem_type]()
system.mem_ctrl.dram.range = system.mem_ranges[0]
system.mem_ctrl.port = system.membus.mem_side_ports

system.system_port = system.membus.cpu_side_ports

# ---- 工作负载 ----
system.workload = SEWorkload.init_compatible(args.binary)
process = Process()
process.cmd = [args.binary]
system.cpu.workload = process
system.cpu.createThreads()

root = Root(full_system=False, system=system)
m5.instantiate()

print(
    f"Beginning simulation! binary={args.binary} cpu={args.cpu_type} "
    f"issue_width={args.issue_width} freq={args.cpu_freq} mem={args.mem_type} "
    f"l1i={args.l1i_size}/{args.l1i_assoc} l1d={args.l1d_size}/{args.l1d_assoc} "
    f"l2={args.l2_size}/{args.l2_assoc if args.l2_size != 'none' else '-'}"
)
exit_event = m5.simulate()
print(f"Exiting @ tick {m5.curTick()} because {exit_event.getCause()}")
