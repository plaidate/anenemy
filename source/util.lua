-- Shared helpers: clamps and a delayed-call scheduler (used by multi-note SFX
-- and timed fx). Mirrors the house util module.

Util = {}

function Util.clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

function Util.lerp(a, b, t)
    return a + (b - a) * t
end

function Util.sign(v)
    if v > 0 then return 1 elseif v < 0 then return -1 else return 0 end
end

-- true if (ax,ay) is within r of (bx,by)
function Util.near(ax, ay, bx, by, r)
    local dx, dy = bx - ax, by - ay
    return dx * dx + dy * dy <= r * r
end

local pending = {}
function Util.after(delay, fn)
    pending[#pending + 1] = { t = delay, fn = fn }
end

function Util.runPending(dt)
    for i = #pending, 1, -1 do
        local p = pending[i]
        p.t = p.t - dt
        if p.t <= 0 then
            table.remove(pending, i)
            p.fn()
        end
    end
end
