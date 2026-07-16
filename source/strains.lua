-- Phase 4: the rival strain roster. You (Anthopleura, the default stats) climb a
-- ladder of genetically distinct rival clones, each with its own combat feel and
-- 1-bit dither identity, ending on a boss. Stats override the RIVAL anemone in
-- Duel.start (per-anemone fields on the instance); the player keeps C defaults.

Strains = {}

Strains.PAT = {
    actinia   = { 0x88, 0x00, 0x22, 0x00, 0x88, 0x00, 0x22, 0x00 }, -- sparse spots (bright)
    metridium = { 0xEE, 0xEE, 0xEE, 0x00, 0xEE, 0xEE, 0xEE, 0x00 }, -- horizontal bands
    urticina  = { 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 }, -- dense checker
    aggressor = { 0xFF, 0x81, 0xBD, 0xA5, 0xA5, 0xBD, 0x81, 0xFF }, -- heavy patterned (boss)
}

-- tolerance = sting endured; stingBase/stingGain = its lash damage; aiRate =
-- wind-up speed; feedMul = feeding rate; resist = fraction of incoming sting
-- shrugged off
-- style drives the AI's *behaviour* (ai.lua PROFILES), not just its numbers: a
-- cannon over-commits and pounces, an economy turtles and retreats to feed, an
-- attrition wall holds the midline, the boss presses greedily.
Strains.LIST = {
    { id = "actinia",   name = "Actinia",   tolerance = 70,  stingBase = 9, stingGain = 34,
      aiRate = 0.036, feedMul = 0.8, resist = 0.0,  pattern = Strains.PAT.actinia, style = "cannon" },   -- glass cannon
    { id = "metridium", name = "Metridium", tolerance = 155, stingBase = 6, stingGain = 13,
      aiRate = 0.022, feedMul = 1.5, resist = 0.0,  pattern = Strains.PAT.metridium, style = "economy" }, -- economy tank
    { id = "urticina",  name = "Urticina",  tolerance = 140, stingBase = 7, stingGain = 21,
      aiRate = 0.024, feedMul = 1.0, resist = 0.10, pattern = Strains.PAT.urticina, style = "attrition" },  -- attrition
    { id = "aggressor", name = "Aggressor", tolerance = 150, stingBase = 8, stingGain = 28,
      aiRate = 0.034, feedMul = 1.1, resist = 0.35, pattern = Strains.PAT.aggressor, boss = true, style = "boss" },
}

function Strains.count() return #Strains.LIST end
function Strains.at(i) return Strains.LIST[((i - 1) % #Strains.LIST) + 1] end
