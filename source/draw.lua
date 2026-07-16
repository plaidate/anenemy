-- Renderer: the tidal sea (water band rises/falls with G.tide), rock, drifting
-- plankton, the two procedural anemones (dither identifies the clone; acrorhagi
-- swell with charge; sting scars accrete; they contract to blobs at low tide),
-- the low-tide predators (diving gull, crawling nudibranch), the HUD (energy +
-- sting bars, a tide gauge, the player's charge meter with its connect tick),
-- and the title / result screens. 1-bit, redrawn every frame.

Draw = {}
local gfx = playdate.graphics

-- clone dither identities (8x8): you = sparse/light, rival = dense checker
local PAT_YOU = { 0xFF, 0xDD, 0xFF, 0x77, 0xFF, 0xDD, 0xFF, 0x77 }
local PAT_RIVAL = { 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 }
local PAT_ROCK = { 0x88, 0x22, 0x88, 0x22, 0x88, 0x22, 0x88, 0x22 }
local PAT_WATER = { 0x00, 0x08, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00 }

-- fixed scar slots on the oral disc (relative to disc centre)
local SCARS = {
    { -13, -5 }, { 9, -9 }, { -4, 6 }, { 15, 3 }, { -17, 4 }, { 3, -14 },
    { 12, -3 }, { -9, -12 }, { 6, 11 }, { 17, -7 }, { -20, -3 }, { 0, 9 },
}

local function drawTentacles(a, cx, discY, scaleY, contracted)
    local n = 9
    local retract = contracted or a.state == "engorging" or a.engorge > 0.15
    local len = (retract and (contracted and 6 or 12) or 25) * (0.4 + 0.6 * scaleY)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    for i = 1, n do
        local frac = (i - 1) / (n - 1)
        local ang = math.rad(-108 + frac * 216)
        local sway = math.sin(G.t * 3 + i + a.wave) * 4
        local bx = cx + math.sin(ang) * C.BODY_R * 0.7
        local by = discY - math.cos(ang) * C.BODY_R * 0.35
        local tx = cx + math.sin(ang) * (C.BODY_R * 0.7 + len) + sway
        local ty = by - math.cos(ang) * len - math.abs(len) * 0.15
        gfx.drawLine(bx, by, tx, ty)
    end
    gfx.setLineWidth(1)
end

-- venom fighting tentacles: thick stubs on the facing side that swell with
-- charge, each capped by a venom bulb; during a lash one bold arm shoots to
-- strikeReach (touching the foe when it connects)
local function drawAcrorhagi(a, cx, discY)
    local dir = a.facing
    gfx.setColor(gfx.kColorBlack)
    if a.state == "striking" then
        local x0 = cx + dir * C.BODY_R * 0.8
        local x1 = cx + dir * (C.BODY_R * 0.8 + a.strikeReach)
        gfx.setLineWidth(4)
        gfx.drawLine(x0, discY - 2, x1, discY - 6)
        gfx.fillCircleAtPoint(x1, discY - 6, 5)
        gfx.setLineWidth(1)
    elseif a.engorge > 0.02 then
        local grow = a.engorge
        gfx.setLineWidth(3)
        for k = 0, 3 do
            local yy = discY - 12 + k * 8
            local l = 8 + grow * 46
            local x0 = cx + dir * C.BODY_R * 0.7
            local x1 = cx + dir * (C.BODY_R * 0.7 + l)
            gfx.drawLine(x0, yy, x1, yy)
            gfx.fillCircleAtPoint(x1, yy, 2 + grow * 3)
        end
        gfx.setLineWidth(1)
    end
end

local function drawAnemone(a)
    local contracted = (a.state == "lowtide")
    local cx = a.x
    local scaleY = 1
    if a.state == "deflating" then
        scaleY = 1 - Util.clamp(a.deflateT / C.DEFLATE_FRAMES, 0, 1) * 0.78
    elseif contracted then
        scaleY = C.LOWTIDE_SCALE
    elseif a.hurtT > 0 then
        scaleY = 0.94
    end
    if a.state ~= "deflating" and not contracted then
        scaleY = scaleY * (1 + math.sin(G.t * 2 + a.wave) * 0.05)   -- breathing
    end
    local colH = 30 * scaleY
    local discY = C.ROCK_Y - colH
    local r = C.BODY_R

    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(cx - r * 0.45, discY, r * 0.9, C.ROCK_Y - discY + 1)

    gfx.setPattern(a.clone == "you" and PAT_YOU or (a.pattern or PAT_RIVAL))
    gfx.fillCircleAtPoint(cx, discY, r)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(cx, discY, r)

    local nScar = math.floor(Util.clamp(a.sting / (a.tolerance or C.TOLERANCE), 0, 1) * #SCARS)
    for i = 1, nScar do
        local o = SCARS[i]
        gfx.fillCircleAtPoint(cx + o[1], discY + o[2], 2)
    end

    -- Phase 3: bracing draws a hunkered shell cap over the top of the disc; a
    -- fresh deflect flashes a white ring
    if (a.braceT or 0) > 0 then
        gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(3)
        local rr, steps = r + 3, 10
        for i = 0, steps - 1 do
            local a0 = math.pi * (1 + i / steps)
            local a1 = math.pi * (1 + (i + 1) / steps)
            gfx.drawLine(cx + math.cos(a0) * rr, discY + math.sin(a0) * rr,
                         cx + math.cos(a1) * rr, discY + math.sin(a1) * rr)
        end
        gfx.setLineWidth(1)
    end
    if (a.deflected or 0) > 0 then
        a.deflected = a.deflected - 1
        gfx.setColor(gfx.kColorWhite); gfx.drawCircleAtPoint(cx, discY, r + 5)
    end
    -- Phase 5: a lash broken by an incoming sting flashes a white X at the tip
    if (a.interrupted or 0) > 0 then
        a.interrupted = a.interrupted - 1
        local fx = cx + a.facing * (r + 7)
        gfx.setColor(gfx.kColorWhite); gfx.setLineWidth(2)
        gfx.drawLine(fx - 4, discY - 10, fx + 4, discY - 2)
        gfx.drawLine(fx + 4, discY - 10, fx - 4, discY - 2)
        gfx.setLineWidth(1)
    end

    drawTentacles(a, cx, discY, scaleY, contracted)
    if a.state ~= "deflating" and not contracted then drawAcrorhagi(a, cx, discY) end
end

local function drawGull(g)
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    local x, y = g.x, g.y
    gfx.drawLine(x - 10, y, x - 3, y - 6)
    gfx.drawLine(x - 3, y - 6, x, y - 2)
    gfx.drawLine(x, y - 2, x + 3, y - 6)
    gfx.drawLine(x + 3, y - 6, x + 10, y)
    if g.f >= C.GULL_DIVE_FRAMES - 6 then gfx.drawLine(x, y, x, y + 9) end   -- beak stab
    gfx.setLineWidth(1)
end

local function drawSlug(s)
    local y = C.ROCK_Y - 6
    gfx.setColor(gfx.kColorBlack)
    gfx.fillEllipseInRect(s.x - 9, y - 3, 18, 8)                 -- body
    gfx.setLineWidth(1)
    for i = -2, 2 do                                            -- cerata on the back
        gfx.drawLine(s.x + i * 3, y - 3, s.x + i * 3 + s.dir, y - 10)
    end
    gfx.drawLine(s.x + s.dir * 8, y - 2, s.x + s.dir * 12, y - 8) -- rhinophore
end

local function drawWorld()
    -- water recedes across the SUBMERGED range: gone (rock bare) by low tide,
    -- full at high tide - so contraction and the dry rock stay in sync
    local wt = Util.clamp(((G.tide or 1) - C.TIDE_LOW) / (1 - C.TIDE_LOW), 0, 1)
    local waterY = math.floor(Util.lerp(C.ROCK_Y + 2, 22, wt))
    if waterY < C.ROCK_Y then
        gfx.setPattern(PAT_WATER)
        gfx.fillRect(0, waterY, C.W, C.ROCK_Y - waterY)
        gfx.setColor(gfx.kColorBlack)
        gfx.setLineWidth(1)
        local px, py
        for x = 0, C.W, 8 do
            local y = waterY + math.sin(x * 0.08 + G.t * 1.5) * 2
            if px then gfx.drawLine(px, py, x, y) end
            px, py = x, y
        end
    end
    -- rock bed
    gfx.setPattern(PAT_ROCK)
    gfx.fillRect(0, C.ROCK_Y, C.W, C.H - C.ROCK_Y)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawLine(0, C.ROCK_Y, C.W, C.ROCK_Y)
    -- plankton (only those still under the surface)
    for _, pk in ipairs(G.plankton or {}) do
        if pk.y > waterY then gfx.fillCircleAtPoint(pk.x, pk.y, 1) end
    end
end

local function drawPredators()
    if G.gull then drawGull(G.gull) end
    if G.slug then drawSlug(G.slug) end
end

local function bar(x, y, w, h, frac, fromRight)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(x, y, w, h)
    local fw = math.floor((w - 2) * Util.clamp(frac, 0, 1))
    if fromRight then
        gfx.fillRect(x + (w - 1) - fw, y + 1, fw, h - 2)
    else
        gfx.fillRect(x + 1, y + 1, fw, h - 2)
    end
end

local function drawHUD()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("YOU", 6, 4)
    bar(6, 20, 90, 8, (G.p.energy or 0) / C.MAX_ENERGY)
    bar(6, 30, 90, 6, (G.p.sting or 0) / (G.p.tolerance or C.TOLERANCE))
    gfx.drawTextAligned(string.upper(G.r.strainName or "RIVAL"), C.W - 6, 4, kTextAlignment.right)
    bar(C.W - 96, 20, 90, 8, (G.r.energy or 0) / C.MAX_ENERGY, true)
    bar(C.W - 96, 30, 90, 6, (G.r.sting or 0) / (G.r.tolerance or C.TOLERANCE), true)

    -- tide gauge (centre top, white backing over the sea)
    local cx = 200
    gfx.setColor(gfx.kColorWhite); gfx.fillRect(cx - 44, 2, 88, 26)
    gfx.setColor(gfx.kColorBlack); gfx.drawRect(cx - 44, 2, 88, 26)
    gfx.drawTextAligned("TIDE " .. string.upper(Tide.phase()), cx, 4, kTextAlignment.center)
    bar(cx - 38, 18, 76, 7, G.tide or 0)

    -- player charge meter with the connect tick (white backing so it reads on
    -- the dark rock bed)
    local mx, my, mw = 130, 220, 140
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(mx - 8, my - 17, mw + 16, 30)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("CHARGE", mx, my - 14)
    bar(mx, my, mw, 9, G.p.engorge or 0)
    local tick = mx + math.floor(mw * Anemone.connectFrac())
    gfx.drawLine(tick, my - 3, tick, my + 11)

    if G.sudden then
        gfx.setColor(gfx.kColorWhite); gfx.fillRect(cx - 46, 30, 92, 14)
        gfx.setColor(gfx.kColorBlack); gfx.drawRect(cx - 46, 30, 92, 14)
        gfx.drawTextAligned("SUDDEN DEATH", cx, 32, kTextAlignment.center)
    end
end

local function drawMiniAnemone(cx, base, pat, ph)
    local breathe = 1 + math.sin(G.t * 2 + ph) * 0.06
    local colH, r = 26 * breathe, 22
    local discY = base - colH
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(cx - 9, discY, 18, base - discY + 1)
    gfx.setPattern(pat)
    gfx.fillCircleAtPoint(cx, discY, r)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(cx, discY, r)
    gfx.setLineWidth(2)
    for i = 1, 8 do
        local ang = math.rad(-100 + ((i - 1) / 7) * 200)
        local sway = math.sin(G.t * 3 + i + ph) * 4
        local bx = cx + math.sin(ang) * r * 0.7
        local by = discY - math.cos(ang) * r * 0.35
        local len = 18 * breathe
        gfx.drawLine(bx, by, cx + math.sin(ang) * (r * 0.7 + len) + sway, by - math.cos(ang) * len - len * 0.15)
    end
    gfx.setLineWidth(1)
end

local function drawTitle()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned("AnEnemy", 200, 34, kTextAlignment.center)
    gfx.drawTextAligned("sea-anemone territorial warfare", 200, 56, kTextAlignment.center)
    drawMiniAnemone(120, 150, PAT_YOU, 0)
    drawMiniAnemone(280, 150, PAT_RIVAL, 1.7)
    local rec = G.records or {}
    gfx.drawTextAligned(string.format("best  %d/%d strains cleared     campaigns won  %d",
        rec.bestStrains or 0, Strains.count(), rec.campaignWins or 0), 200, 176, kTextAlignment.center)
    gfx.drawTextAligned("crank to engorge      \u{24b6} to lash", 200, 196, kTextAlignment.center)
    if not Harness.enabled then
        gfx.drawTextAligned("\u{24b6}  hold the line", 200, 214, kTextAlignment.center)
    end
end

-- Phase 3: the rock as a row of cells with the moving frontier boundary
local function drawMap()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned(string.format("THE ROCK   vs %s  (%d/%d)",
        (G.strain and G.strain.name or "?"), G.ladderIdx or 1, Strains.count()),
        200, 26, kTextAlignment.center)
    local n = G.cells
    local cw, ch, y0 = 44, 46, 78
    local x0 = math.floor((C.W - n * cw) / 2)
    for i = 1, n do
        local x = x0 + (i - 1) * cw
        local mine = (i <= G.owned)
        gfx.setPattern(mine and PAT_YOU or (G.strain and G.strain.pattern or PAT_RIVAL))
        gfx.fillRect(x, y0, cw - 2, ch)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(x, y0, cw - 2, ch)
        -- a reinforcement token (reads on either dither)
        local gx, gy = x + (cw - 2) / 2, y0 + ch / 2
        gfx.setColor(gfx.kColorWhite); gfx.fillCircleAtPoint(gx, gy, 5)
        gfx.setColor(gfx.kColorBlack); gfx.drawCircleAtPoint(gx, gy, 5)
    end
    -- no-man's-land boundary between owned and rival cells
    local bx = x0 + G.owned * cw - 1
    gfx.setLineWidth(3); gfx.drawLine(bx, y0 - 9, bx, y0 + ch + 9); gfx.setLineWidth(1)
    gfx.drawTextAligned(string.format("YOU  %d       RIVAL  %d", G.owned, n - G.owned),
        200, 140, kTextAlignment.center)
    if (G.lastShift or 0) ~= 0 then
        gfx.drawTextAligned(G.lastShift > 0 and "you pushed the border forward"
            or "the rival pushed you back", 200, 160, kTextAlignment.center)
    end
    local up = G.upgrades or {}
    if (up.tol or 0) + (up.sting or 0) + (up.feed or 0) > 0 then
        gfx.drawTextAligned(string.format("boons   body +%d   venom +%d   gape +%d",
            up.tol or 0, up.sting or 0, up.feed or 0), 200, 178, kTextAlignment.center)
    end
    if not Harness.enabled then
        gfx.drawTextAligned("Ⓐ  fight the frontier", 200, 200, kTextAlignment.center)
    end
end

-- skirmish (duel) outcome banner, drawn over the paused field
local function drawSkirmish()
    gfx.setColor(gfx.kColorWhite); gfx.fillRect(64, 62, 272, 92)
    gfx.setColor(gfx.kColorBlack); gfx.drawRect(64, 62, 272, 92)
    local won = (G.skResult == "win")
    gfx.drawTextAligned(won and "FRONTIER HELD" or "DRIVEN BACK", 200, 74, kTextAlignment.center)
    gfx.drawTextAligned(won and "The rival cedes a cell." or "You cede a cell.",
        200, 96, kTextAlignment.center)
    gfx.drawTextAligned(string.format("ROCK   you %d   rival %d",
        G.owned, (G.cells or 0) - (G.owned or 0)), 200, 120, kTextAlignment.center)
    if not Harness.enabled then gfx.drawTextAligned("Ⓐ", 200, 138, kTextAlignment.center) end
end

local function drawWarOver()
    gfx.setColor(gfx.kColorBlack)
    local win = (G.warResult == "win")
    gfx.drawTextAligned(win and "YOU CLEARED THE ROCK" or "THE ROCK IS LOST",
        200, 66, kTextAlignment.center)
    gfx.drawTextAligned(win and "The rival clone abandons the rock."
        or "Your clone withdraws to new rock.", 200, 90, kTextAlignment.center)
    gfx.drawTextAligned(string.format("skirmishes fought  %d", G.skirmishes or 0),
        200, 118, kTextAlignment.center)
    gfx.drawTextAligned(string.format("wars   won %d    lost %d", G.warWins or 0, G.warLosses or 0),
        200, 138, kTextAlignment.center)
    if not Harness.enabled then gfx.drawTextAligned("Ⓐ  a new rock", 200, 200, kTextAlignment.center) end
end

local function drawCampaign()
    gfx.setColor(gfx.kColorBlack)
    local won = (G.campaignResult == "won")
    gfx.drawTextAligned(won and "CAMPAIGN COMPLETE" or "YOUR CLONE IS DEFEATED",
        200, 66, kTextAlignment.center)
    gfx.drawTextAligned(won and "You cleared every rival strain from the shore."
        or "The shore belongs to the rivals.", 200, 90, kTextAlignment.center)
    local beaten = won and Strains.count() or ((G.ladderIdx or 1) - 1)
    gfx.drawTextAligned(string.format("strains beaten  %d / %d", beaten, Strains.count()),
        200, 118, kTextAlignment.center)
    gfx.drawTextAligned(string.format("skirmishes fought  %d", G.skWins + G.skLosses),
        200, 138, kTextAlignment.center)
    if not Harness.enabled then gfx.drawTextAligned("\u{24b6}  a new shore", 200, 200, kTextAlignment.center) end
end

-- Phase 4: the spoils pick after a cleared rock. Three boons; d-pad selects, Ⓐ
-- confirms. Stacks persist for the rest of the campaign (main applies them).
local SPOILS = {
    { name = "THICKER BODY",  desc = "+ tolerance" },
    { name = "SHARPER VENOM", desc = "+ damage" },
    { name = "WIDER GAPE",    desc = "+ feeding" },
}
local function drawSpoils()
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned("SPOILS OF THE ROCK", 200, 24, kTextAlignment.center)
    gfx.drawTextAligned("choose a boon for the shore ahead", 200, 46, kTextAlignment.center)
    local cw, gp = 112, 10
    local x0 = math.floor((C.W - (3 * cw + 2 * gp)) / 2)
    for i = 1, 3 do
        local x = x0 + (i - 1) * (cw + gp)
        local cx = x + cw / 2
        local sel = (G.spoilSel or 1) == i
        gfx.setColor(gfx.kColorWhite); gfx.fillRect(x, 74, cw, 62)
        gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(sel and 4 or 1)
        gfx.drawRect(x, 74, cw, 62); gfx.setLineWidth(1)
        gfx.drawTextAligned(SPOILS[i].name, cx, 88, kTextAlignment.center)
        gfx.drawTextAligned(SPOILS[i].desc, cx, 110, kTextAlignment.center)
    end
    local up = G.upgrades or {}
    gfx.drawTextAligned(string.format("body +%d    venom +%d    gape +%d",
        up.tol or 0, up.sting or 0, up.feed or 0), 200, 150, kTextAlignment.center)
    if not Harness.enabled then
        gfx.drawTextAligned("d-pad choose      \u{24b6} take it", 200, 200, kTextAlignment.center)
    end
end

-- first-duel coaching: point at the connect tick, the one skill that carries the
-- whole game. Shown once ever (save flag), dismissed on the first clean connect.
local function drawTutorial()
    local mx, mw, my = 130, 140, 220
    local tick = mx + math.floor(mw * Anemone.connectFrac())
    gfx.setColor(gfx.kColorWhite); gfx.fillRect(48, 150, 304, 38)
    gfx.setColor(gfx.kColorBlack); gfx.drawRect(48, 150, 304, 38)
    gfx.drawTextAligned("crank to engorge — charge PAST the tick", 200, 156, kTextAlignment.center)
    gfx.drawTextAligned("to reach, then \u{24b6} to lash", 200, 172, kTextAlignment.center)
    gfx.fillTriangle(tick, my - 20, tick - 5, my - 28, tick + 5, my - 28)   -- arrow down to the tick
end

function Draw.frame()
    gfx.clear(gfx.kColorWhite)
    local s = G.state
    if s == "title" then
        drawTitle()
    elseif s == "map" then
        drawMap()
    elseif s == "warover" then
        drawWarOver()
    elseif s == "spoils" then
        drawSpoils()
    elseif s == "campaign" then
        drawCampaign()
    else
        drawWorld()
        drawAnemone(G.p)
        drawAnemone(G.r)
        drawPredators()
        drawHUD()
        if s == "skirmish" then drawSkirmish() end
        if G.tutorial then drawTutorial() end
        if not Harness.enabled and playdate.isCrankDocked() then
            playdate.ui.crankIndicator:draw()
        end
    end
    gfx.setColor(gfx.kColorBlack)
end
