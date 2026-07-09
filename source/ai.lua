-- Rival brain (and, in smoke, both sides). Refuel to a buffer, then COMMIT: wind
-- to the connect charge and lash (bailing at a floor deadlocks - a full wind-up
-- costs more than the floor). Strikes on sight when the foe is exposed, and
-- dumps early if about to run dry. Uses the anemone's own aiRate (strains vary).

AI = {}

local FEED_TARGET = 32

function AI.decide(a, opp)
    local inp = { engorgeDelta = 0, strike = false }
    local target = Util.clamp(Anemone.connectFrac() + 0.08, C.MIN_STRIKE, 0.98)
    local exposed = (opp.state == "recover" or opp.state == "striking" or opp.hurtT > 0)

    if a.engorge >= target * 0.85 and exposed then
        inp.strike = true
        return inp
    end
    if a.engorge <= 0.02 and a.energy < FEED_TARGET then
        return inp
    end
    if a.engorge < target and a.energy > C.STRIKE_ENERGY + 3 then
        inp.engorgeDelta = (a.aiRate or C.ENGORGE_AI_RATE) * (a.rateMul or 1)
    else
        inp.strike = true
    end
    return inp
end
