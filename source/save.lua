-- Phase 5: persistent records via the datastore ("save" key). Tracks the best
-- ladder cleared, total campaigns won, and campaigns played. Loaded at boot,
-- written whenever a campaign ends. Separate from the smoke harness keys.

Save = {}

function Save.load()
    local d = playdate.datastore.read("save")
    G.records = {
        bestStrains = (d and d.bestStrains) or 0,
        campaignWins = (d and d.campaignWins) or 0,
        campaigns = (d and d.campaigns) or 0,
        seenTutorial = (d and d.seenTutorial) or false,
    }
end

function Save.store()
    playdate.datastore.write(G.records or {}, "save")
end
