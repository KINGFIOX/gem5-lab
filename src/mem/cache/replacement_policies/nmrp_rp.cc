/**
 * @file
 * Implementation of a Not Most Recently Used (NMRU) replacement policy.
 * 以 lru_rp.cc 为基础，唯一实质修改在 getVictim()：
 *   LRU  —— 淘汰 lastTouchTick 最小（最久未用）的候选块；
 *   NMRU —— 先找到 lastTouchTick 最大（最近使用）的 MRU 块并保护它，
 *           然后从其余候选块中等概率随机选择一个淘汰。
 */

#include <cassert>
#include <memory>

#include "mem/cache/replacement_policies/nmrp_rp.hh"
#include "params/NMRURP.hh"
#include "sim/cur_tick.hh"

namespace gem5
{

namespace replacement_policy
{

NMRU::NMRU(const Params &p)
  : Base(p)
{
}

void
NMRU::invalidate(const std::shared_ptr<ReplacementData>& replacement_data)
{
    // Reset last touch timestamp
    std::static_pointer_cast<NMRUReplData>(
        replacement_data)->lastTouchTick = Tick(0);
}

void
NMRU::touch(const std::shared_ptr<ReplacementData>& replacement_data) const
{
    // Update last touch timestamp
    std::static_pointer_cast<NMRUReplData>(
        replacement_data)->lastTouchTick = curTick();
}

void
NMRU::reset(const std::shared_ptr<ReplacementData>& replacement_data) const
{
    // Set last touch timestamp
    std::static_pointer_cast<NMRUReplData>(
        replacement_data)->lastTouchTick = curTick();
}

ReplaceableEntry*
NMRU::getVictim(const ReplacementCandidates& candidates) const
{
    // There must be at least one replacement candidate
    assert(candidates.size() > 0);

    // 第一步：找到 MRU（lastTouchTick 最大的候选块）
    ReplaceableEntry* mru = candidates[0];
    for (const auto& candidate : candidates) {
        if (std::static_pointer_cast<NMRUReplData>(
                    candidate->replacementData)->lastTouchTick >
                std::static_pointer_cast<NMRUReplData>(
                    mru->replacementData)->lastTouchTick) {
            mru = candidate;
        }
    }

    // 第二步：从除 MRU 之外的候选块中随机选择受害者。
    // 只有一个候选时别无选择；有 invalid（lastTouchTick == 0）块时
    // LRU 语义会优先淘汰它，这里保持随机语义（NMRU 定义如此）。
    ReplaceableEntry* victim = candidates[0];
    if (candidates.size() > 1) {
        do {
            victim = candidates[rng->random<unsigned>(0,
                                       candidates.size() - 1)];
        } while (victim == mru);
    }

    return victim;
}

std::shared_ptr<ReplacementData>
NMRU::instantiateEntry()
{
    return std::shared_ptr<ReplacementData>(new NMRUReplData());
}

} // namespace replacement_policy
} // namespace gem5
