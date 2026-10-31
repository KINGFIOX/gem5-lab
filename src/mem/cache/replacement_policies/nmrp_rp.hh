/**
 * @file
 * Declaration of a Not Most Recently Used (NMRU) replacement policy.
 * 与 LRU 的区别仅在 getVictim：LRU 固定淘汰最久未使用的块；
 * NMRU 保护最近使用的块（MRU），从其余块中随机选择一个淘汰。
 * 其余逻辑（lastTouchTick 时间戳、invalidate/touch/reset）与 LRU 完全一致。
 */

#ifndef __MEM_CACHE_REPLACEMENT_POLICIES_NMRP_RP_HH__
#define __MEM_CACHE_REPLACEMENT_POLICIES_NMRP_RP_HH__

#include "base/random.hh"
#include "mem/cache/replacement_policies/base.hh"

namespace gem5
{

struct NMRURPParams;

namespace replacement_policy
{

class NMRU : public Base
{
  protected:
    /** NMRU 选择随机受害者时使用的随机数生成器。 */
    mutable gem5::Random::RandomPtr rng = gem5::Random::genRandom();

    /** NMRU-specific implementation of replacement data. */
    struct NMRUReplData : ReplacementData
    {
        /** Tick on which the entry was last touched. */
        Tick lastTouchTick;

        /**
         * Default constructor. Invalidate data.
         */
        NMRUReplData() : lastTouchTick(0) {}
    };

  public:
    typedef NMRURPParams Params;
    NMRU(const Params &p);
    ~NMRU() = default;

    /**
     * Invalidate replacement data to set it as the next probable victim.
     * Sets its last touch tick as the starting tick.
     */
    void invalidate(const std::shared_ptr<ReplacementData>& replacement_data)
                                                                    override;

    /**
     * Touch an entry to update its replacement data.
     * Sets its last touch tick as the current tick.
     */
    void touch(const std::shared_ptr<ReplacementData>& replacement_data) const
                                                                     override;

    /**
     * Reset replacement data. Used when an entry is inserted.
     * Sets its last touch tick as the current tick.
     */
    void reset(const std::shared_ptr<ReplacementData>& replacement_data) const
                                                                     override;

    /**
     * Find replacement victim: 保护 MRU 块，从其余候选中随机选择。
     *
     * @param candidates Replacement candidates, selected by indexing policy.
     * @return Replacement entry to be replaced.
     */
    ReplaceableEntry* getVictim(const ReplacementCandidates& candidates) const
                                                                     override;

    /**
     * Instantiate a replacement data entry.
     *
     * @return A shared pointer to the new replacement data.
     */
    std::shared_ptr<ReplacementData> instantiateEntry() override;
};

} // namespace replacement_policy
} // namespace gem5

#endif // __MEM_CACHE_REPLACEMENT_POLICIES_NMRP_RP_HH__
