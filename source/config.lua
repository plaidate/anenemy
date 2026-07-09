import "smokeflag" -- must precede any SMOKE_BUILD block (config imports first)

-- AnEnemy - sea-anemone territorial duel. Fixed 30fps, 400x240 1-bit.
-- Phase 1: the core border duel (crank-engorged acrorhagi, the lash, sting ->
-- deflate, plankton feeding). Phase 2: the full tide cycle (high tide feeds &
-- fights, low tide bares the rock - contract, heal, desiccation, gull &
-- nudibranch). Phase 3: the territory war - a 1D frontier of cells, reinforced
-- by the rock you hold; clear it to win.
--
-- C = tunables (per-frame at 30fps). G = live state.

C = {
    DT = 1 / 30,
    W = 400,
    H = 240,

    BASE_Y = 150,          -- oral-disc anchor height
    ROCK_Y = 178,          -- rock surface line (feet of the column)
    PLAYER_X = 112,
    RIVAL_X = 288,
    BODY_R = 30,           -- oral-disc radius (the hurt zone)

    MAX_ENERGY = 100,
    START_ENERGY = 55,
    TOLERANCE = 100,       -- sting patches endured before deflating

    -- engorging the acrorhagi (charge 0..1)
    ENGORGE_PER_DEG = 0.0045,
    ENGORGE_AI_RATE = 0.028,
    ENGORGE_DECAY = 0.05,
    ENGORGE_DRAIN = 0.55,
    ENGORGE_IDLE_DRAIN = 0.15,

    MIN_STRIKE = 0.12,
    BASE_REACH = 34,
    REACH_GAIN = 132,
    STRIKE_BASE = 7,
    STRIKE_GAIN = 24,
    STRIKE_ENERGY = 12,
    STRIKE_ANIM = 6,
    HIT_FRAME = 3,
    RECOVER_FRAMES = 18,
    HURT_FRAMES = 9,
    DEFLATE_FRAMES = 40,

    -- feeding economy
    FEED_BASE = 0.9,
    FEED_REACH = 46,
    PLANKTON_MAX = 14,
    PLANKTON_VALUE = 2.5,

    -- Phase 2: tide
    TIDE_PERIOD = 22,
    TIDE_LOW = 0.34,
    TIDE_HIGH = 0.62,
    LOWTIDE_SCALE = 0.5,
    HEAL_RATE = 0.14,
    DESICC_RATE = 0.10,

    -- Phase 2: low-tide predators
    GULL_INTERVAL = 2.6,
    GULL_DIVE_FRAMES = 26,
    GULL_STING = 10,
    GULL_HIT_X = 34,
    SLUG_SPEED = 0.75,
    SLUG_CONTACT = 30,
    SLUG_DRAIN = 0.35,
    SLUG_GRAZE_STING = 0.05,

    -- Phase 3: the territory war (1D frontier / tug-of-war over the rock)
    CELLS = 7,                  -- cells in the rock row
    START_OWNED = 3,            -- cells you start holding (rival gets the rest)
    TERRITORY_ENERGY = 4,       -- start-energy edge per net cell held (reinforcements)
    MAX_SKIRMISHES = 40,        -- headless safety: force-resolve a war after this many

    -- Phase 4: roster
    STRAIN_TOL_MUL = 1,         -- scales rival strain tolerance (smoke shrinks it)
    SMOKE_CAMPAIGNS = 2,        -- headless: campaigns (1 win-run climbs the ladder, 1 lose-run)

    -- headless autopilot
    SMOKE_WARS = 4,
}

if SMOKE_BUILD then
    -- bound the headless run: smaller rock, softer tolerance, two wars (the
    -- alternating war favour covers both the cleared-rock and lost-rock endings)
    C.CELLS = 5
    C.START_OWNED = 2
    C.SMOKE_WARS = 2
    C.MAX_SKIRMISHES = 24
    C.TOLERANCE = 72
    C.STRAIN_TOL_MUL = 0.5
end

G = {}
