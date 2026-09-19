ZX = ZX or {}

local Population = {}

function Population.AmbientEnabled(config)
    config = config or {}
    if config.LocalClientZombies == false then return false end
    if not config.Spawning or config.Spawning.enabled == false then return false end
    if config.Sync and config.Sync.DisableAmbientLocalSpawner == true then return false end
    return true
end

function Population.ShouldNetwork(spawnOptions)
    spawnOptions = spawnOptions or {}
    return spawnOptions.forceNetworked == true or spawnOptions.sharedId ~= nil
end

function Population.AiInterval(distance, performance)
    performance = performance or {}
    distance = math.max(0.0, tonumber(distance) or math.huge)
    if distance <= (performance.nearDistance or 35.0) then
        return performance.aiNearInterval or 200
    end
    if distance <= (performance.midDistance or 80.0) then
        return performance.aiMidInterval or 500
    end
    return performance.aiFarInterval or 1000
end

function Population.RunnerActive(distance, performance)
    performance = performance or {}
    return (tonumber(distance) or math.huge) <= (performance.runnerMaxDistance or 55.0)
end

ZX.Population = Population
return Population
