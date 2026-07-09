-- Per-frame intent for an anemone. The human pilots the player with the crank
-- (engorge the acrorhagi) and Ⓐ (lash); the rival is always the AI. In smoke
-- builds EVERY anemone is AI-driven so duels resolve headless.

Input = {}
local pd <const> = playdate

function Input.player()
    return {
        engorgeDelta = pd.getCrankChange() * C.ENGORGE_PER_DEG,
        strike = pd.buttonJustPressed(pd.kButtonA),
    }
end

function Input.forAnemone(a, opp)
    if Harness.enabled then return AI.decide(a, opp) end
    if a.isPlayer then return Input.player() end
    return AI.decide(a, opp)
end
