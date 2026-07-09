# AnEnemy — design

*A real-time territorial dueling game about sea-anemone warfare, for Playdate
(Lua SDK). You command the front-line warrior polyps of a clone colony. Crank
to engorge your **acrorhagi** — venom-packed fighting tentacles — then release
to lash the rival clone across the no-man's-land gap. Land stings until it
deflates and withdraws, and the boundary is yours.*

Screen 400x240, 1-bit, fixed 30 fps (`DT = 1/30`). Modules share globals
(`import` shares the global env), one concern per file. bundleID
`com.sdwfrost.anenemy`.

## The fantasy, and how each real fact becomes a mechanic

Sea anemones (*Anthopleura elegantissima*) live in large genetically identical
clones. Where two clones meet they hold a no-man's-land boundary and fight in
ranks with acrorhagi — specialised structures near the tentacle base, loaded
with high-density toxin used *only* against rival anemones (their ordinary
tentacles are for catching prey). A strike leaves patches of stinging cells on
the opponent's soft body. Battles run minutes to days; the loser deflates,
withdraws, and relocates.

| Real biology | Mechanic |
| --- | --- |
| Feeding tentacles catch drifting prey | Passive plankton feeding -> **Energy** |
| Acrorhagi engorge with venom before a strike | **Crank forward to inflate** the fighting tentacles (charge 0..1) |
| The overreaching lash deposits stinging cells | **Release + Ⓐ** lashes; reach & sting scale with charge at release |
| Toxic patches accumulate on the body | Damage is a **sting** total toward a **tolerance**, shown as scars — not a health bar |
| Loser deflates, withdraws, relocates | Rival **deflates and vacates** the cell -> you hold the border |
| Clone armies, no-man's-land, ranks | Rock is a **cell grid** (Phase 3); win skirmishes to push the boundary |
| Intertidal life, high/low tide | **Tide** is the master clock: feed & fight at high tide, consolidate at low |

## Core tension

**Feed vs. fight.** Engorging the acrorhagi *stops* your feeding tentacles and
*burns* Energy; the bigger the charge, the more it costs and the longer you are
exposed. Over-attack and you starve mid-lash; over-feed and the rival advances.
Every skirmish is that gamble, under a ticking tide.

Reach is the skill gate: a lash only connects if `reach >= gap`. Reach grows
with charge, so a limp, under-charged strike whiffs. The player learns the
minimum "connect" charge (marked on the charge meter); charging past it hits
harder but bleeds more Energy and leaves you open. Getting stung mid-charge
**drops your charge** — so timing beats spamming.

## Controls (Playdate-native)

- **Crank ⟳** — engorge acrorhagi (raise charge / reach).
- **Crank ⟲** — deflate the charge (conserve Energy, bail out of a wind-up).
- **Ⓐ** — release / strike (with current charge). Confirm on menus.
- (Phase 3) **D-pad** — pick which front-line cell you pilot; hold to pedal-disc creep.

## State machine (per anemone)

`feeding` (default; catches plankton, regenerates Energy) -> `engorging`
(crank raising charge, draining Energy) -> `striking` (brief lash; sting applied
at mid-frame) -> `recover` (vulnerable retract) -> `feeding`. Getting hit ->
`hurt` (flinch, charge dropped). Tolerance exceeded -> `deflating` -> duel over.

## Tuning constants (Phase 1, in `config.lua` as `C`)

Positions: player x=112, rival x=288, body radius 30 -> edge-to-edge gap 116 px.
Reach = `34 + charge*132`, so the connect threshold is charge ~0.62. Sting per
lash = `7 + charge*24` (max ~31); tolerance 100 -> ~4–5 solid hits to deflate.
Energy: max 100; feeding +~0.85/frame (tide-scaled); holding full charge bleeds
~0.7/frame + 12 per lash. All per-frame at 30 fps.

## Build phases

- **P0 — DESIGN.md** (this file).
- **P1 — Core duel (this scaffold).** One border cell, one rival. Crank-engorge
  -> lash -> sting -> deflate; plankton feeding + Energy; a light tide; AI rival;
  title/result flow. Headless autopilot drives both sides and cycles several
  duels, forcing BOTH the win and the loss ending.
- **P2 — Economy + tide. (DONE 2026-07-08)** Full high/low/slack tide cycle, low-tide contract &
  heal beat, desiccation, air predators (gull peck, *Aeolidia* nudibranch that
  grazes / steals sting cells).
- **P3 — Territory war. (DONE 2026-07-09)** Rock of cells, boundary push, cell claim, reinforcement
  spawns, rival-clone AI over the whole rock. Win = clear the rock.
- **P4 — Roster + music. (DONE 2026-07-09)** Rival strains as personalities (Actinia glass-cannon,
  Metridium economy racer, Urticina attrition tank, a nudibranch boss);
  tide-phase step-sequencer audio.
- **P5 — Polish. (DONE 2026-07-09)** Procedural 1-bit anemone art (the breathing inflate/deflate is
  the hero visual), title, save/scores, full-game autopilot.

## Art & audio direction

1-bit, procedural, animated. Hero visual = the **breathing engorge/deflate** of
the tentacle columns. Clone identity by **dither pattern** (you = sparse/light,
rival = dense/checker), not outline. Acrorhagi = thick tentacles with a venom
**bulb** at the tip that swells with charge; the lash extends a bold line across
the gap. Sting damage = **stipple scars** accreting on the oral disc. Audio is
pure synth (`playdate.sound.synth`): lash whoosh, sting thud, feed tick, a
descending deflate, a win chime. Music (step sequencer) arrives in P4.

## Headless testing

`tools/smoke.sh [seconds] [until-grep]` builds the instrumented variant
(`SMOKE_BUILD`), runs the Simulator headless (`open <app>.app --args <pdx>` —
the SDK-3.0.6-safe form), and polls the datastore. The harness pcall-wraps
`playdate.update`, writes a 90-frame heartbeat to `smoke` (state, both anemones'
energy/sting/charge/state, strikes/stings/whiffs, plankton, per-side win tally,
`duelIndex`), errors to `err`, and screenshots (per-state + strike/engorge/
deflate event shots). Both sides run on the AI; a small alternating per-duel
handicap guarantees the run records both `wins` and `losses`. LOOK AT THE
SCREENSHOTS — count-clean but visually broken is the usual bug.
