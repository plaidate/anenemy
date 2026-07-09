-- Phase 2: the tide is the master clock, and the low-tide beat. A smooth cosine
-- cycle drives G.tide (1 = high/submerged, 0 = low/exposed). High tide = feed &
-- fight; low tide = the rock is bare, anemones contract to blobs (Duel gates
-- combat), they heal sting but bleed energy to desiccation, and two air
-- predators appear: a diving GULL that pecks, and an Aeolidia NUDIBRANCH that
-- crawls the rock grazing energy. Predators hit BOTH clones, so the AI needs no
-- new logic - they are pure environment.

Tide = {}

function Tide.reset()
    G.tide = 1          -- start submerged, so combat opens the duel
    G.tideT = 0
    G.phase = "high"
    G.lowCount = 0
    G.gull = nil
    G.gullCd = C.GULL_INTERVAL
    G.slug = nil
end

function Tide.submerged() return (G.tide or 1) > C.TIDE_LOW end

function Tide.phase()
    local t = G.tide or 1
    if t <= C.TIDE_LOW then return "low"
    elseif t >= C.TIDE_HIGH then return "high"
    else return "mid" end
end

-- feeding scales with depth, and stops entirely once exposed
function Tide.feedScale()
    if not Tide.submerged() then return 0 end
    return 0.5 + 0.7 * Util.clamp((G.tide - C.TIDE_LOW) / (1 - C.TIDE_LOW), 0, 1)
end

local function nearest(x)
    return math.abs(x - G.p.x) <= math.abs(x - G.r.x) and G.p or G.r
end

local function updateGull(dt)
    if not Tide.submerged() then
        G.gullCd = (G.gullCd or 0) - dt
        if not G.gull and G.gullCd <= 0 then
            -- dive at one clone, alternating each low tide so both get pecked
            local tgt = ((G.lowCount or 0) % 2 == 0) and G.p or G.r
            G.gull = { x = tgt.x, y = -18, f = 0 }
            G.gullCd = C.GULL_INTERVAL
        end
    end
    local g = G.gull
    if not g then return end
    g.f = g.f + 1
    local dive = C.GULL_DIVE_FRAMES
    if g.f <= dive then
        g.y = Util.lerp(-18, C.BASE_Y - 18, g.f / dive)
    elseif g.f == dive + 1 then
        local a = nearest(g.x)
        if math.abs(a.x - g.x) <= C.GULL_HIT_X and a.state ~= "deflating" then
            a.sting = a.sting + C.GULL_STING
            a.hurtT = math.max(a.hurtT, 4)
            Harness.count("gullPecks")
            Sfx.peck()
        end
    else
        g.y = g.y - 9
        if g.y < -20 then G.gull = nil end
    end
end

local function updateSlug()
    if Tide.submerged() then
        if G.slug then           -- water returns: the slug retreats to its edge
            G.slug.x = G.slug.x - G.slug.dir * C.SLUG_SPEED * 2.5
            if G.slug.x < -20 or G.slug.x > C.W + 20 then G.slug = nil end
        end
        return
    end
    if not G.slug then
        -- crawl in toward the richer clone (graze the most energy / venom)
        local rich = (G.p.energy >= G.r.energy) and G.p or G.r
        local fromLeft = rich.x < C.W / 2
        G.slug = { x = fromLeft and -14 or C.W + 14, dir = fromLeft and 1 or -1 }
    end
    local s = G.slug
    s.x = s.x + s.dir * C.SLUG_SPEED
    for _, a in ipairs({ G.p, G.r }) do
        if a.state ~= "deflating" and math.abs(a.x - s.x) <= C.SLUG_CONTACT then
            a.energy = math.max(0, a.energy - C.SLUG_DRAIN)
            a.sting = a.sting + C.SLUG_GRAZE_STING   -- grazing leaves small wounds
            Harness.count("grazes")
        end
    end
    if s.x < -20 or s.x > C.W + 20 then G.slug = nil end
end

function Tide.update(dt)
    G.tideT = (G.tideT or 0) + dt
    G.tide = 0.5 + 0.5 * math.cos((G.tideT / C.TIDE_PERIOD) * 2 * math.pi)
    local p = Tide.phase()
    if p == "low" and G.phase ~= "low" then
        G.lowCount = (G.lowCount or 0) + 1
        Harness.count("lowTides")
    end
    G.phase = p
    updateGull(dt)
    updateSlug()
end
