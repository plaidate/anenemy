-- AnEnemy - Phase 4: the campaign ladder + music. title -> map -> duel ->
-- skirmish -> (map | warover) -> next strain | campaign end. You climb a ladder
-- of rival strains (Actinia, Metridium, Urticina, the Aggressor boss); clearing
-- a strain's rock advances you, losing a war ends the run. Tide-phase music
-- plays during duels. Headless smoke runs both clones on the AI over
-- SMOKE_CAMPAIGNS campaigns: campaign 1 favours the player (climbs the whole
-- ladder -> every strain + a cleared campaign), campaign 2 favours the rival
-- (a lost campaign).

import "CoreLibs/graphics"
import "CoreLibs/ui"

import "config"
import "util"
import "harness"
import "save"
import "sfx"
import "music"
import "anemone"
import "ai"
import "input"
import "strains"
import "tide"
import "war"
import "duel"
import "draw"

math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(SMOKE_BUILD and 0 or 30)
Harness.shotPath = SHOT_PATH

G.state = "title"
G.t = 0
G.frame = 0
G.duelIndex = 0
G.warIndex = 0
G.ladderIdx = 1
G.campaignIdx = 0
G.smokeFavor = 0
G.skWins = 0
G.skLosses = 0
G.warWins = 0
G.warLosses = 0
G.freeze = SMOKE_BUILD and 12 or 0   -- linger so the title renders headless

Save.load()

local function advance(canHuman)
    if Harness.enabled then
        G.freeze = (G.freeze or 0) - 1
        return G.freeze <= 0
    end
    if canHuman then return playdate.buttonJustPressed(playdate.kButtonA) end
    return true
end

local function toMap() G.state = "map"; G.t = 0; G.freeze = SMOKE_BUILD and 6 or 0 end

local function startCampaign()
    G.campaignIdx = (G.campaignIdx or 0) + 1
    G.ladderIdx = 1
    G.campaignResult = nil
    G.upgrades = { tol = 0, sting = 0, feed = 0 }   -- Phase 4: spoils reset per campaign
    if SMOKE_BUILD then G.smokeFavor = (G.campaignIdx == 1) and 1 or -1 end
    War.start()
end

local function recordCampaign(won)
    local r = G.records or {}
    r.campaigns = (r.campaigns or 0) + 1
    if won then
        r.campaignWins = (r.campaignWins or 0) + 1
        r.bestStrains = math.max(r.bestStrains or 0, Strains.count())
    else
        r.bestStrains = math.max(r.bestStrains or 0, (G.ladderIdx or 1) - 1)
    end
    G.records = r
    Save.store()
end

local function tick()
    G.t = G.t + C.DT
    Util.runPending(C.DT)
    local s = G.state

    if s == "title" then
        if advance(true) then startCampaign(); toMap() end

    elseif s == "map" then
        if advance(true) then
            Duel.start()
            G.tutorial = (not Harness.enabled) and not (G.records and G.records.seenTutorial) or nil
        end

    elseif s == "duel" then
        local res = Duel.update(Input.forAnemone(G.p, G.r), Input.forAnemone(G.r, G.p))
        if G.tutorial and ((G.p.hits or 0) > 0 or G.t > 8) then
            G.tutorial = nil
            G.records.seenTutorial = true
            Save.store()
        end
        if res then
            G.skResult = res
            local won = (res == "win")
            War.applySkirmish(won)
            if won then G.skWins = G.skWins + 1; Harness.count("skWins"); Sfx.chime()
            else G.skLosses = G.skLosses + 1; Harness.count("skLosses") end
            Harness.count("boundaryShifts")
            G.state = "skirmish"; G.t = 0; G.freeze = SMOKE_BUILD and 8 or 0
        end

    elseif s == "skirmish" then
        if advance(true) then
            local w = War.done()
            if w then
                G.warResult = w
                if w == "win" then G.warWins = G.warWins + 1; Harness.count("warWins")
                else G.warLosses = G.warLosses + 1; Harness.count("warLosses") end
                G.state = "warover"; G.t = 0; G.freeze = SMOKE_BUILD and 9 or 0
            else
                toMap()
            end
        end

    elseif s == "warover" then
        if advance(true) then
            if G.warResult == "win" then
                if (G.ladderIdx or 1) >= Strains.count() then
                    G.campaignResult = "won"; Harness.count("campaignWins"); recordCampaign(true)
                    G.state = "campaign"; G.t = 0; G.freeze = SMOKE_BUILD and 10 or 0
                    Sfx.chime()
                else
                    G.spoilSel = 1
                    G.state = "spoils"; G.t = 0; G.freeze = SMOKE_BUILD and 6 or 0
                end
            else
                G.campaignResult = "lost"; Harness.count("campaignLosses"); recordCampaign(false)
                G.state = "campaign"; G.t = 0; G.freeze = SMOKE_BUILD and 10 or 0
                Sfx.deflate()
            end
        end

    elseif s == "spoils" then
        if not Harness.enabled then
            if playdate.buttonJustPressed(playdate.kButtonLeft) then
                G.spoilSel = ((G.spoilSel or 1) - 2) % 3 + 1
            elseif playdate.buttonJustPressed(playdate.kButtonRight) then
                G.spoilSel = (G.spoilSel or 1) % 3 + 1
            end
        else
            G.spoilSel = (G.ladderIdx or 1) % 3 + 1   -- headless: vary the auto-pick
        end
        if advance(true) then
            local id = ({ "tol", "sting", "feed" })[G.spoilSel or 1]
            G.upgrades[id] = (G.upgrades[id] or 0) + 1
            Harness.count("spoils")
            G.ladderIdx = G.ladderIdx + 1
            War.start(); toMap()
        end

    elseif s == "campaign" then
        if advance(true) then
            if SMOKE_BUILD and (G.campaignIdx or 0) >= C.SMOKE_CAMPAIGNS then
                G.state = "done"
            else
                startCampaign(); toMap()
            end
        end
    end

    Music.update()
    Draw.frame()
end

do
    local m = playdate.getSystemMenu and playdate.getSystemMenu()
    if m then
        m:addCheckmarkMenuItem("music", true, function(v) Sfx.on = v; Music.on = v end)
    end
end

Harness.extra = function(t)
    t.state = G.state
    t.campaignIdx = G.campaignIdx
    t.ladderIdx = G.ladderIdx
    t.strain = G.strain and G.strain.id or nil
    t.warIndex = G.warIndex
    t.owned = G.owned
    t.cells = G.cells
    t.skirmishes = G.skirmishes
    t.skWins = G.skWins; t.skLosses = G.skLosses
    t.warWins = G.warWins; t.warLosses = G.warLosses
    t.tidePhase = Tide.phase()
    if G.gull then t.gull = true end
    if G.slug then t.slug = true end
    if G.p then
        t.pEnergy = math.floor(G.p.energy); t.rEnergy = math.floor(G.r.energy)
        t.pSting = math.floor(G.p.sting);   t.rSting = math.floor(G.r.sting)
        t.rTol = G.r.tolerance
        t.pState = G.p.state; t.rState = G.r.state
    end
    if G.skResult then t.skResult = G.skResult end
    if G.warResult then t.warResult = G.warResult end
    if G.campaignResult then t.campaignResult = G.campaignResult end
    if G.records then t.recBest = G.records.bestStrains; t.recWins = G.records.campaignWins; t.recPlayed = G.records.campaigns end
end

function playdate.update()
    G.frame = (G.frame or 0) + 1
    Harness.frame(G.frame, tick)
end
