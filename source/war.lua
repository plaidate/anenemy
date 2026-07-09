-- Phase 3/4: the territory war over one rock, against the current ladder strain.
-- The rock is a 1D row of CELLS; you hold G.owned, the rival the rest, with a
-- no-man's-land boundary between. A won frontier duel pushes the boundary +1, a
-- loss -1; held cells feed reinforcement start-energy into the next duel so a
-- lead snowballs (wars converge). Clear the rock to win the war -> next strain.

War = {}

function War.start()
    G.warIndex = (G.warIndex or 0) + 1
    G.strain = Strains.at(G.ladderIdx or 1)
    G.cells = C.CELLS
    G.owned = C.START_OWNED
    G.skirmishes = 0
    G.lastShift = 0
    G.skResult = nil
    G.warResult = nil
    -- smoke: the whole campaign favours one clone (set by main.startCampaign)
    G.warFavor = SMOKE_BUILD and (G.smokeFavor or 0) or 0
end

function War.territoryEnergy()
    local net = (G.owned or 0) - (G.cells - (G.owned or 0))
    return net * C.TERRITORY_ENERGY
end

function War.applySkirmish(playerWon)
    G.skirmishes = (G.skirmishes or 0) + 1
    G.lastShift = playerWon and 1 or -1
    G.owned = Util.clamp((G.owned or 0) + G.lastShift, 0, G.cells)
end

function War.done()
    if (G.owned or 0) >= G.cells then return "win" end
    if (G.owned or 0) <= 0 then return "lose" end
    if SMOKE_BUILD and (G.skirmishes or 0) >= C.MAX_SKIRMISHES then
        return (G.owned * 2 >= G.cells) and "win" or "lose"
    end
    return nil
end
