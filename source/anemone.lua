-- Anemone entity: an anchored warrior polyp. Constructor + reach geometry.
-- Phase 4: combat stats live per-instance (tolerance / sting / aiRate / feed /
-- resist / pattern), so a rival strain can override them while the player keeps
-- the C defaults. Duel drives the state machine; AI/Input decide intent.

Anemone = {}

function Anemone.new(opts)
    return {
        x = opts.x,
        facing = opts.facing,
        isPlayer = opts.isPlayer,
        clone = opts.clone,          -- "you" | "rival"
        wave = opts.wave or 0,
        aiPhase = opts.aiPhase or 0,
        rateMul = 1,

        -- per-instance stats (rival strain overrides; player = C defaults)
        pattern = opts.pattern,               -- fill dither (nil player -> PAT_YOU)
        strainName = opts.strainName,
        tolerance = opts.tolerance or C.TOLERANCE,
        stingBase = opts.stingBase or C.STRIKE_BASE,
        stingGain = opts.stingGain or C.STRIKE_GAIN,
        aiRate = opts.aiRate or C.ENGORGE_AI_RATE,
        feedMul = opts.feedMul or 1,
        resist = opts.resist or 0,

        energy = C.START_ENERGY,
        sting = 0,
        engorge = 0,
        state = "feeding",
        stateT = 0,

        hurtT = 0, recoverT = 0, strikeT = 0, deflateT = 0,
        pendingHit = false, readyHit = false, strikeReach = 0, strikeDmg = 0,

        fed = 0, strikes = 0, hits = 0,
    }
end

function Anemone.connectDist()
    return (C.RIVAL_X - C.PLAYER_X) - 2 * C.BODY_R
end

function Anemone.reach(a)
    return C.BASE_REACH + a.engorge * C.REACH_GAIN
end

function Anemone.connectFrac()
    return Util.clamp((Anemone.connectDist() - C.BASE_REACH) / C.REACH_GAIN, 0, 1)
end
