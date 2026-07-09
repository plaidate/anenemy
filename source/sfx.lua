-- Combat SFX kit (pure synth, no music yet). Every entry point is no-op-safe if
-- the sound system is unavailable so nothing crashes headless. Sfx.on gates the
-- lot for the system-menu toggle.

Sfx = {}
Sfx.on = true

local ok, snd = pcall(function() return playdate.sound end)
if not ok then snd = nil end

local lashS, stingS, whiffS, feedS, deflateS, chimeS, peckS
if snd then
    lashS = snd.synth.new(snd.kWaveNoise);       lashS:setADSR(0.001, 0.06, 0, 0.03)
    stingS = snd.synth.new(snd.kWaveSquare);      stingS:setADSR(0.001, 0.08, 0, 0.05)
    whiffS = snd.synth.new(snd.kWaveNoise);       whiffS:setADSR(0.001, 0.04, 0, 0.02)
    feedS = snd.synth.new(snd.kWaveTriangle);     feedS:setADSR(0.001, 0.02, 0, 0.02)
    deflateS = snd.synth.new(snd.kWaveSawtooth);  deflateS:setADSR(0.01, 0.4, 0, 0.3)
    chimeS = snd.synth.new(snd.kWaveTriangle);    chimeS:setADSR(0.001, 0.15, 0.2, 0.2)
    peckS = snd.synth.new(snd.kWaveSquare);       peckS:setADSR(0.001, 0.03, 0, 0.02)
end

local function live() return Sfx.on ~= false end

function Sfx.lash()  if lashS and live() then lashS:playNote(500, 0.25, 0.06) end end
function Sfx.sting() if stingS and live() then stingS:playNote(180, 0.4, 0.09) end end
function Sfx.whiff() if whiffS and live() then whiffS:playNote(700, 0.12, 0.05) end end
function Sfx.feed()  if feedS and live() then feedS:playNote(1200, 0.08, 0.02) end end
function Sfx.peck()  if peckS and live() then peckS:playNote(1500, 0.35, 0.04) end end

function Sfx.deflate()
    if not (deflateS and live()) then return end
    deflateS:playNote(200, 0.4, 0.35)
    Util.after(0.12, function() if deflateS then deflateS:playNote(90, 0.4, 0.4) end end)
end

function Sfx.chime()
    if not (chimeS and live()) then return end
    chimeS:playNote(523, 0.3, 0.12)
    Util.after(0.12, function() if chimeS then chimeS:playNote(784, 0.3, 0.18) end end)
end
