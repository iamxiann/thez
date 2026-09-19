local BleedingState = {}

local function FiniteNumber(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then
        return nil
    end
    return value
end

function BleedingState.New()
    return { players = {}, lastReports = {} }
end

function BleedingState.Start(state, src, now)
    if state.players[src] then return false end
    state.players[src] = { startedAt = now, lastDrainAt = now }
    return true
end

function BleedingState.Stop(state, src)
    if not state.players[src] then return false end
    state.players[src] = nil
    return true
end

function BleedingState.Reset(state, src)
    state.players[src] = nil
    state.lastReports[src] = nil
end

function BleedingState.IsBleeding(state, src)
    return state.players[src] ~= nil
end

function BleedingState.AcceptReport(state, src, now, cooldownMs)
    now = FiniteNumber(now)
    cooldownMs = math.max(0, FiniteNumber(cooldownMs) or 0)
    if not now then return false end

    local previous = state.lastReports[src]
    if previous and (now - previous) < cooldownMs then return false end
    state.lastReports[src] = now
    return true
end

function BleedingState.ValidateDamageReport(
    beforeHealth,
    afterHealth,
    serverHealth,
    threshold,
    maxDamage,
    tolerance,
    isAlive
)
    beforeHealth = FiniteNumber(beforeHealth)
    afterHealth = FiniteNumber(afterHealth)
    serverHealth = FiniteNumber(serverHealth)
    threshold = math.max(1, FiniteNumber(threshold) or 30)
    maxDamage = math.max(threshold, FiniteNumber(maxDamage) or 200)
    tolerance = math.max(0, FiniteNumber(tolerance) or 8)

    if not isAlive or not beforeHealth or not afterHealth or not serverHealth then
        return false, 0
    end
    local damage = beforeHealth - afterHealth
    if damage < threshold or damage > maxDamage then return false, damage end
    if afterHealth <= 100 or math.abs(serverHealth - afterHealth) > tolerance then
        return false, damage
    end
    return true, damage
end

_G.BleedingState = BleedingState
return BleedingState
