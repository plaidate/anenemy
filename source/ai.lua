-- Rival brain (and, in smoke, both sides). Each strain fights to a behaviour
-- PROFILE keyed by a.style, so the roster's personalities actually read at the
-- controls, not just as spongier/spikier numbers:
--   feed    energy buffer it refuels to before committing
--   bias    charge it banks past the bare connect point (higher = safer, slower)
--   pounce  fraction of that target at which it will lash on an opening
--   press   1 = advances while winding to guarantee a connect; 0 = holds
--   greedy  also pounces on a feeding/idle foe, not only its recovery window
--   retreat backs off to open the gap while refuelling
-- Every path keeps the deadlock floor: if it can't afford more charge, it lashes
-- rather than stall at a threshold (a full wind-up costs more than bailing).

AI = {}

local PROFILES = {
    neutral   = { feed = 32, bias = 0.08, pounce = 0.85, press = 1, greedy = false, retreat = false },
    cannon    = { feed = 22, bias = 0.02, pounce = 0.70, press = 1, greedy = true,  retreat = false }, -- Actinia: over-commits, punishes on sight
    economy   = { feed = 48, bias = 0.14, pounce = 0.95, press = 0, greedy = false, retreat = true  }, -- Metridium: turtles, retreats to feed, waits for clean openings
    attrition = { feed = 36, bias = 0.10, pounce = 0.88, press = 0, greedy = false, retreat = false }, -- Urticina: holds the midline, patient trades
    boss      = { feed = 34, bias = 0.12, pounce = 0.80, press = 1, greedy = true,  retreat = false }, -- Aggressor: presses greedily behind its resist
}

function AI.decide(a, opp)
    local p = PROFILES[a.style or "neutral"] or PROFILES.neutral
    local inp = { engorgeDelta = 0, strike = false, advance = 0 }
    local target = Util.clamp(Anemone.connectFrac() + p.bias, C.MIN_STRIKE, 0.98)
    local exposed = (opp.state == "recover" or opp.state == "striking" or opp.hurtT > 0)
    local pounceable = exposed or
        (p.greedy and a.engorge >= target and (opp.state == "feeding" or opp.state == "engorging"))

    -- positioning (inp is shared across every return path below)
    if a.engorge > 0.2 and not exposed and p.press == 1 then inp.advance = 1
    elseif p.retreat and a.energy < p.feed and a.engorge <= 0.02 then inp.advance = -1 end

    -- brace an incoming gull peck during its telegraph window
    local g = G.gull
    if g and g.f >= C.GULL_DIVE_FRAMES - 7 and g.f <= C.GULL_DIVE_FRAMES + 1
       and math.abs(a.x - g.x) <= C.GULL_HIT_X + 6 then
        inp.brace = true
    end

    if a.engorge >= target * p.pounce and pounceable then
        inp.strike = true
        return inp
    end
    if a.engorge <= 0.02 and a.energy < p.feed then
        return inp                                   -- refuel first
    end
    if a.engorge < target and a.energy > C.STRIKE_ENERGY + 3 then
        inp.engorgeDelta = (a.aiRate or C.ENGORGE_AI_RATE) * (a.rateMul or 1)
    else
        inp.strike = true                            -- deadlock floor: dump rather than stall
    end
    return inp
end
