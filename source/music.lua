-- Phase 4: clock-driven step-sequencer music (zero drift - advances by frames,
-- not wall time). A 16-step bass + lead loop whose pattern follows the tide:
-- sparse & open at high tide, busier mid, spare & tense at low tide. Plays only
-- during the duel; gated by Sfx.on / Music.on. No-op-safe headless.

Music = {}
Music.on = true

local ok, snd = pcall(function() return playdate.sound end)
if not ok then snd = nil end

local bass, lead
if snd then
    bass = snd.synth.new(snd.kWaveSine);     bass:setADSR(0.005, 0.12, 0.2, 0.12); bass:setVolume(0.35)
    lead = snd.synth.new(snd.kWaveTriangle); lead:setADSR(0.005, 0.08, 0.1, 0.10); lead:setVolume(0.22)
end

local BASS = {
    high = { 45, 0, 0, 0, 45, 0, 48, 0, 45, 0, 0, 0, 43, 0, 0, 0 },
    mid  = { 45, 0, 45, 0, 48, 0, 0, 0, 43, 0, 43, 0, 41, 0, 0, 0 },
    low  = { 40, 0, 0, 40, 0, 0, 40, 0, 38, 0, 0, 0, 38, 0, 0, 0 },
}
local LEAD = {
    high = { 0, 0, 69, 0, 0, 72, 0, 0, 0, 0, 71, 0, 0, 67, 0, 0 },
    mid  = { 0, 64, 0, 67, 0, 0, 69, 0, 0, 64, 0, 0, 0, 62, 0, 0 },
    low  = { 0, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
}

local function freq(n) return 440 * 2 ^ ((n - 69) / 12) end

local STEP_FRAMES = 6
local acc, step = 0, 0

function Music.update()
    if not Music.on then return end
    if Sfx and Sfx.on == false then return end   -- the menu toggle silences both
    if G.state ~= "duel" then return end
    acc = acc + 1
    if acc < STEP_FRAMES then return end
    acc = 0
    step = (step % 16) + 1
    local ph = Tide.phase()
    local b = (BASS[ph] or BASS.mid)[step]
    local l = (LEAD[ph] or LEAD.mid)[step]
    if bass and b > 0 then bass:playNote(freq(b), 0.35, 0.14) end
    if lead and l > 0 then lead:playNote(freq(l), 0.22, 0.10) end
end
