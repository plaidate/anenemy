-- Per-frame intent for an anemone. The human pilots the player with the crank
-- (engorge the acrorhagi) and Ⓐ (lash); the rival is always the AI. In smoke
-- builds EVERY anemone is AI-driven so duels resolve headless.

Input = {}
local pd <const> = playdate

function Input.player()
    -- the player anemone always faces right, so d-pad right = advance on the foe,
    -- left = retreat (Phase 1 positioning)
    local adv = 0
    if pd.buttonIsPressed(pd.kButtonRight) then adv = 1
    elseif pd.buttonIsPressed(pd.kButtonLeft) then adv = -1 end
    return {
        engorgeDelta = pd.getCrankChange() * C.ENGORGE_PER_DEG,
        strike = pd.buttonJustPressed(pd.kButtonA),
        advance = adv,
        brace = pd.buttonJustPressed(pd.kButtonB),   -- Phase 3: duck the gull peck
    }
end

function Input.forAnemone(a, opp)
    if Harness.enabled then return AI.decide(a, opp) end
    if a.isPlayer then return Input.player() end
    return AI.decide(a, opp)
end
