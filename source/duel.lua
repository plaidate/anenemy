-- Core duel (the frontier skirmish): plankton feeding, crank-engorged acrorhagi,
-- the lash, sting accumulation, deflate/withdraw. Phase 2 tide gating + low-tide
-- contract/heal/desiccation. Phase 3 reinforcement opening. Phase 4: combat
-- reads PER-ANEMONE stats, so the rival strain (set here from G.strain) fights
-- with its own tolerance / damage / feed / venom-resistance.

Duel = {}

local function spawnPlankton()
    return {
        x = math.random(20, C.W - 20),
        y = math.random(40, C.ROCK_Y - 26),
        vx = (math.random() < 0.5 and -1 or 1) * (0.3 + math.random() * 0.5),
        vy = (math.random() - 0.5) * 0.3,
    }
end

function Duel.start()
    G.duelIndex = (G.duelIndex or 0) + 1

    local pRate, rRate = 1, 1
    if SMOKE_BUILD and (G.warFavor or 0) ~= 0 then
        if G.warFavor == 1 then pRate = 1.8 else rRate = 1.8 end
    end

    -- Phase 1: the opening gap varies with the boundary (press forward when
    -- ahead) plus jitter, so the connect tick sits somewhere new each skirmish.
    local net = (G.owned or 0) - (G.cells - (G.owned or 0))
    local jit = (math.random() - 0.5) * C.SPREAD_JITTER
    local half = Util.clamp(C.SPREAD_BASE - net * C.SPREAD_PER_CELL + jit, C.SPREAD_MIN, C.SPREAD_MAX)
    local px, rx = C.CENTER_X - half, C.CENTER_X + half

    -- Phase 4: the player carries its earned spoils (rival keeps strain stats)
    local up = G.upgrades or {}
    G.p = Anemone.new{ x = px, facing = 1, isPlayer = true, clone = "you", wave = 0, aiPhase = 0,
        tolerance = C.TOLERANCE + (up.tol or 0) * C.SPOIL_TOL,
        stingGain = C.STRIKE_GAIN + (up.sting or 0) * C.SPOIL_STING,
        feedMul = 1 + (up.feed or 0) * C.SPOIL_FEED }
    local st = G.strain
    G.r = Anemone.new{ x = rx, facing = -1, isPlayer = false, clone = "rival", wave = 1.7, aiPhase = 3,
        pattern = st.pattern, strainName = st.name, tolerance = st.tolerance * C.STRAIN_TOL_MUL,
        stingBase = st.stingBase, stingGain = st.stingGain, aiRate = st.aiRate,
        feedMul = st.feedMul, resist = st.resist, style = st.style }
    G.p.rateMul = pRate
    G.r.rateMul = rRate
    if SMOKE_BUILD and (G.warFavor or 0) ~= 0 then
        -- headless: give the favoured clone a decisive edge (damage + tolerance,
        -- not just wind-up speed) so campaigns resolve in the intended direction
        -- and BOTH the cleared-campaign and lost-campaign endings are exercised
        local fav = (G.warFavor == 1) and G.p or G.r
        fav.stingGain = fav.stingGain * 1.6
        fav.tolerance = fav.tolerance * 1.6
    end

    -- Phase 3: reinforcements from held rock tilt the opening
    local terr = War.territoryEnergy()
    G.p.energy = Util.clamp(C.START_ENERGY + terr, 15, C.MAX_ENERGY)
    G.r.energy = Util.clamp(C.START_ENERGY - terr, 15, C.MAX_ENERGY)

    G.plankton = {}
    for _ = 1, 8 do G.plankton[#G.plankton + 1] = spawnPlankton() end
    Tide.reset()
    G.result = nil
    G.sudden = false
    G.state = "duel"
    G.t = 0
    Harness.count("duels")
end

local function feedGain(a)
    return C.FEED_BASE * (a.feedMul or 1) * Tide.feedScale()
end

local function updatePlankton()
    local target = math.floor(2 + (G.tide or 1) * (C.PLANKTON_MAX - 2) * 0.7)
    for _, pk in ipairs(G.plankton) do
        pk.x = pk.x + pk.vx
        pk.y = pk.y + pk.vy
        if pk.x < 8 then pk.x = 8; pk.vx = -pk.vx end
        if pk.x > C.W - 8 then pk.x = C.W - 8; pk.vx = -pk.vx end
        if pk.y < 38 then pk.y = 38; pk.vy = -pk.vy end
        if pk.y > C.ROCK_Y - 26 then pk.y = C.ROCK_Y - 26; pk.vy = -pk.vy end
    end
    while #G.plankton < target do G.plankton[#G.plankton + 1] = spawnPlankton() end
    while #G.plankton > target + 2 do table.remove(G.plankton) end
end

-- Phase 3: a tap of brace grants a brief window that deflects the gull's peck
-- (Tide.update reads braceT). Decays every frame.
local function applyBrace(a, inp)
    if (a.braceT or 0) > 0 then a.braceT = a.braceT - 1 end
    if inp.brace and a.state ~= "deflating" then a.braceT = C.BRACE_FRAMES end
end

local function tryFeed(a)
    if a.state ~= "feeding" or not Tide.submerged() then return end
    if (a.lean or 0) > 2 then return end   -- Phase 3: leaning in stops your feeding tentacles
    local mouthY = C.BASE_Y - 16
    for i = #G.plankton, 1, -1 do
        local pk = G.plankton[i]
        if Util.near(pk.x, pk.y, a.x, mouthY, C.FEED_REACH) then
            table.remove(G.plankton, i)
            a.energy = math.min(C.MAX_ENERGY, a.energy + C.PLANKTON_VALUE)
            a.fed = a.fed + 1
            Sfx.feed()
        end
    end
end

local function stepOne(a, inp)
    a.stateT = a.stateT + 1

    if a.state == "deflating" then a.deflateT = a.deflateT + 1; return end
    if a.hurtT > 0 then
        a.hurtT = a.hurtT - 1
        a.engorge = math.max(0, a.engorge - C.ENGORGE_DECAY * 2)
        if a.hurtT == 0 then a.state = "feeding" end
        return
    end
    if a.state == "striking" then
        a.strikeT = a.strikeT - 1
        if a.strikeT == C.HIT_FRAME and a.pendingHit then a.readyHit = true end
        if a.strikeT <= 0 then a.state = "recover"; a.recoverT = C.RECOVER_FRAMES end
        return
    end
    if a.state == "recover" then
        a.recoverT = a.recoverT - 1
        a.engorge = math.max(0, a.engorge - C.ENGORGE_DECAY)
        if a.recoverT <= 0 then a.state = "feeding" end
        return
    end

    if not Tide.submerged() then
        a.state = "lowtide"
        a.engorge = math.max(0, a.engorge - C.ENGORGE_DECAY)
        a.sting = math.max(0, a.sting - C.HEAL_RATE)
        a.energy = math.max(0, a.energy - C.DESICC_RATE)
        return
    end

    local ed = inp.engorgeDelta or 0
    if ed > 0 and a.energy > 1 then
        a.engorge = Util.clamp(a.engorge + ed, 0, 1)
        a.state = "engorging"
    elseif ed < 0 then
        a.engorge = math.max(0, a.engorge + ed)
        if a.engorge <= 0.001 then a.state = "feeding" end
    else
        if a.engorge > 0 then a.engorge = math.max(0, a.engorge - C.ENGORGE_DECAY * 0.5) end
        if a.engorge <= 0.001 then a.state = "feeding" end
    end
    if a.energy <= 0 then
        a.energy = 0
        a.engorge = math.max(0, a.engorge - C.ENGORGE_DECAY)
        if a.engorge <= 0.001 then a.state = "feeding" end
    end

    if a.state == "engorging" or a.engorge > 0 then
        a.energy = math.max(0, a.energy - (C.ENGORGE_IDLE_DRAIN + a.engorge * C.ENGORGE_DRAIN))
    end
    if a.state == "feeding" then
        a.energy = math.min(C.MAX_ENERGY, a.energy + feedGain(a))
    end

    if inp.strike and a.engorge >= C.MIN_STRIKE then
        a.state = "striking"
        a.strikeT = C.STRIKE_ANIM
        a.pendingHit = true
        a.readyHit = false
        a.strikeReach = Anemone.reach(a)
        a.strikeGap = Anemone.connectDist()   -- lock the gap at launch (positions may drift)
        a.strikeDmg = a.stingBase + a.engorge * a.stingGain
        a.energy = math.max(0, a.energy - C.STRIKE_ENERGY)
        a.engorge = 0
        a.strikes = a.strikes + 1
        Sfx.lash()
        Harness.count("strikes")
    end
end

-- Phase 1: creep the front line toward (+) or away (-) the foe. Advancing closes
-- the gap so a lower charge connects, but you enter the rival's reach and burn
-- energy; retreating opens it and is free. Blocked while committed/contracted.
local function stepMove(a, inp)
    if a.state == "deflating" or a.state == "lowtide" or a.state == "striking" or a.hurtT > 0 then
        return
    end
    local adv = inp.advance or 0
    if adv ~= 0 then
        a.lean = Util.clamp((a.lean or 0) + adv * C.LEAN_SPEED, C.LEAN_MIN, C.LEAN_MAX)
        if adv > 0 and a.energy > 0 then a.energy = math.max(0, a.energy - C.LEAN_DRAIN) end
    end
    a.x = a.homeX + (a.lean or 0) * a.facing
end

-- Phase 1: after the clock runs out, both tolerances erode so the fighter
-- carrying more sting deflates first - a duel can no longer stall forever.
local function suddenDeath()
    if G.t <= C.DUEL_SECONDS then return end
    G.p.tolerance = math.max(1, (G.p.tolerance or C.TOLERANCE) - C.SUDDEN_DECAY)
    G.r.tolerance = math.max(1, (G.r.tolerance or C.TOLERANCE) - C.SUDDEN_DECAY)
    G.sudden = true
end

local function resolveHit(a, opp)
    if not a.readyHit then return end
    a.readyHit = false
    a.pendingHit = false
    if opp.state == "deflating" then return end
    if a.strikeReach >= (a.strikeGap or Anemone.connectDist()) then
        if opp.state == "striking" then opp.interrupted = 8 end   -- their lash breaks off
        opp.sting = opp.sting + a.strikeDmg * (1 - (opp.resist or 0))
        opp.hurtT = C.HURT_FRAMES
        opp.state = "hurt"
        opp.engorge = opp.engorge * 0.3
        a.hits = a.hits + 1
        Sfx.sting()
        Harness.count("stings")
    else
        Sfx.whiff()
        Harness.count("whiffs")
    end
end

local function checkDeflate(a)
    if a.state ~= "deflating" and a.sting >= (a.tolerance or C.TOLERANCE) then
        a.state = "deflating"
        a.deflateT = 0
        a.engorge = 0
        Sfx.deflate()
    end
end

function Duel.update(inpP, inpR)
    applyBrace(G.p, inpP)
    applyBrace(G.r, inpR)
    Tide.update(C.DT)
    updatePlankton()
    stepMove(G.p, inpP)
    stepMove(G.r, inpR)
    tryFeed(G.p)
    tryFeed(G.r)
    stepOne(G.p, inpP)
    stepOne(G.r, inpR)
    suddenDeath()
    resolveHit(G.p, G.r)
    resolveHit(G.r, G.p)
    checkDeflate(G.p)
    checkDeflate(G.r)

    if G.r.state == "deflating" and G.r.deflateT >= C.DEFLATE_FRAMES then return "win" end
    if G.p.state == "deflating" and G.p.deflateT >= C.DEFLATE_FRAMES then return "lose" end
    return nil
end
