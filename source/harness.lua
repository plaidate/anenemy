-- Smoke-test harness. The Makefile stages smokeflag.lua: SMOKE_BUILD false for
-- release (no-op wrapper), true for `make smoke` (pcall-wrapped update writing
-- errors to "err", a 90-frame heartbeat to "smoke", and screenshots the input
-- module / autopilot consult).

import "smokeflag"

Harness = {
    enabled = SMOKE_BUILD,
    counters = {},
    extra = nil,
    shotPath = nil,
}

function Harness.count(key, n)
    if not Harness.enabled then return end
    Harness.counters[key] = (Harness.counters[key] or 0) + (n or 1)
end

local function shot(name)
    if not (Harness.shotPath and playdate.simulator) then return end
    local p = Harness.shotPath:gsub("anenemy%-shot%.png$", name .. ".png")
    playdate.simulator.writeToFile(playdate.graphics.getDisplayImage(), p)
end
Harness.shot = shot

local function near(a, x) return a and math.abs(a.x - x) <= C.SLUG_CONTACT + 4 end

function Harness.frame(frame, updateFn)
    if not Harness.enabled then
        updateFn()
        return
    end
    local ok, err = pcall(updateFn)
    if not ok then
        playdate.datastore.write({ err = tostring(err) }, "err")
    end
    if frame % 90 == 0 then
        local t = {}
        for k, v in pairs(Harness.counters) do t[k] = v end
        t.frame = frame
        if Harness.extra then pcall(Harness.extra, t) end
        playdate.datastore.write(t, "smoke")
    end
    if not (Harness.shotPath and playdate.simulator) then return end
    if frame % 300 == 0 then shot("anenemy-shot") end
    Harness.stateShot = Harness.stateShot or {}
    local st = tostring(G.state or "none")
    if not Harness.stateShot[st] and (G.t or 0) > 0.1 then
        Harness.stateShot[st] = true
        shot("art-" .. st)
    end
    -- combat event shots (one each)
    if not Harness.engorgeShot and G.p and (G.p.engorge > 0.5 or G.r.engorge > 0.5) then
        Harness.engorgeShot = true; shot("art-engorge")
    end
    if not Harness.strikeShot and G.p and (G.p.state == "striking" or G.r.state == "striking") then
        Harness.strikeShot = true; shot("art-strike")
    end
    if not Harness.advanceShot and G.p and ((G.p.lean or 0) > 7 or (G.r.lean or 0) > 7) then
        Harness.advanceShot = true; shot("art-advance")
    end
    if not Harness.deflateShot and G.p and (G.p.state == "deflating" or G.r.state == "deflating") then
        Harness.deflateShot = true; shot("art-deflate")
    end
    -- Phase 2 event shots: low-tide (contracted), a gull mid-peck, a grazing slug
    if not Harness.lowShot and G.p and G.p.state == "lowtide" and Tide.phase() == "low" then
        Harness.lowShot = true; shot("art-lowtide")
    end
    if not Harness.gullShot and G.gull and (G.gull.f or 0) >= C.GULL_DIVE_FRAMES - 6 then
        Harness.gullShot = true; shot("art-gull")
    end
    if not Harness.braceShot and G.p and ((G.p.braceT or 0) > 0 or (G.r.braceT or 0) > 0) then
        Harness.braceShot = true; shot("art-brace")
    end
    -- Phase 4: one shot per rival strain (roster showcase)
    if G.strain and (G.state == "duel" or G.state == "map") and (G.t or 0) > 0.15 then
        Harness.strainShot = Harness.strainShot or {}
        if not Harness.strainShot[G.strain.id] then
            Harness.strainShot[G.strain.id] = true
            shot("strain-" .. G.strain.id)
        end
    end
    if not Harness.slugShot and G.slug and (near(G.p, G.slug.x) or near(G.r, G.slug.x)) then
        Harness.slugShot = true; shot("art-slug")
    end
end
