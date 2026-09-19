local Corex = nil
local isReady = false
local spawnedProps = {}
local containerBlips = {}
local isSearching = false
local openContainerId = nil

local function Debug(level, msg)
    if not Config.Debug and level ~= 'Error' then return end
    local colors = { Error = '^1', Warn = '^3', Info = '^2', Verbose = '^5' }
    print((colors[level] or '^7') .. '[COREX-LOOT] ' .. msg .. '^0')
end

local function InitCorex()
    local attempts = 0
    while not Corex and attempts < 30 do
        local success, result = pcall(function()
            return exports['corex-core']:GetCoreObject()
        end)
        if success and result then
            Corex = result
            Debug('Info', 'Client core object acquired')
            return true
        end
        attempts = attempts + 1
        Wait(1000)
    end
    Debug('Error', 'Client failed to acquire core object')
    return false
end

local function SearchContainer(entity, data)
    if isSearching then return end
    if not Corex then return end

    local ped = Corex.Functions.GetPed()
    if Corex.Functions.IsDead(ped) then return end

    local containerId = data.containerId
    local containerType = data.containerType
    local typeData = Config.ContainerTypes[containerType]
    if not typeData then return end

    isSearching = true

    local success = lib.progressBar({
        duration = typeData.searchTime,
        label = typeData.label .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = {
            dict = Config.Reveal.searchAnimDict,
            clip = Config.Reveal.searchAnim
        }
    })

    if not success or Corex.Functions.IsDead(Corex.Functions.GetPed()) then
        isSearching = false
        lib.notify({ description = 'Search cancelled', type = 'warning' })
        return
    end

    TriggerServerEvent('corex-loot:server:requestContainer', containerId)

    CreateThread(function()
        Wait(10000)
        if isSearching then
            isSearching = false
            lib.notify({ description = 'Server timeout - try again', type = 'error' })
        end
    end)
end

local function SpawnContainers()
    for locIndex, location in ipairs(Config.Locations) do
        local containerType = location.type
        local typeData = Config.ContainerTypes[containerType]
        if not typeData then goto nextLocation end

        if typeData.blip then
            local firstContainer = location.containers[1]
            if firstContainer then
                local blip = AddBlipForCoord(firstContainer.coords.x, firstContainer.coords.y, firstContainer.coords.z)
                SetBlipSprite(blip, typeData.blip.sprite)
                SetBlipColour(blip, typeData.blip.color)
                SetBlipScale(blip, typeData.blip.scale)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(typeData.blip.label)
                EndTextCommandSetBlipName(blip)

                containerBlips[#containerBlips + 1] = blip
            end
        end

        for containerIndex, container in ipairs(location.containers) do
            local containerId = ('loc_%d_c_%d'):format(locIndex, containerIndex)
            local model = typeData.model

            local prop = Corex.Functions.SpawnProp(model, container.coords, {
                placeOnGround = false,
                networked = false,
                freeze = true
            })

            if prop then
                SetEntityHeading(prop, container.heading)

                local ok = pcall(function()
                    exports.ox_target:addLocalEntity(prop, {
                        {
                            name = 'corex_loot_search_' .. containerId,
                            icon = typeData.icon,
                            label = typeData.interactLabel,
                            distance = typeData.interactDistance,
                            onSelect = function()
                                SearchContainer(prop, {
                                    containerId = containerId,
                                    containerType = containerType
                                })
                            end
                        }
                    })
                end)

                if not ok then
                    Debug('Error', 'Failed to add target for container ' .. containerId)
                end

                spawnedProps[#spawnedProps + 1] = {
                    prop = prop,
                    containerId = containerId,
                    locData = container
                }

                Debug('Verbose', 'Spawned container ' .. containerId .. ' (' .. typeData.label .. ')')
            else
                Debug('Error', 'Failed to spawn prop for container ' .. containerId)
            end
        end

        ::nextLocation::
    end

    Debug('Info', 'Spawned ' .. #spawnedProps .. ' container props and ' .. #containerBlips .. ' blips')
end

local function CleanupAll()
    for _, entry in ipairs(spawnedProps) do
        if entry.prop and DoesEntityExist(entry.prop) then
            pcall(function()
                exports.ox_target:removeLocalEntity(entry.prop)
            end)
            Corex.Functions.DeleteProp(entry.prop)
        end
    end
    spawnedProps = {}

    for _, blip in ipairs(containerBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    containerBlips = {}

    isSearching = false
    openContainerId = nil

    Debug('Info', 'Cleanup complete')
end

RegisterNetEvent('corex-loot:client:searchContainer', function(entity, data)
    SearchContainer(entity, data)
end)

RegisterNetEvent('corex-loot:client:containerOpened', function(containerId, items, containerLabel)
    isSearching = false
    openContainerId = containerId

    TriggerEvent('corex-inventory:client:openLootContainer', containerId, items, containerLabel, Config.Reveal.itemRevealDelay)

    Debug('Verbose', 'Container opened: ' .. containerId .. ' with ' .. #items .. ' items')
end)

RegisterNetEvent('corex-loot:client:searchFailed', function(reason)
    isSearching = false
    lib.notify({ description = reason or 'Search failed', type = 'error' })
end)

-- Locked container → run the corex-skills lockpick minigame, then report
-- the result back. On success, the server marks us as unlocked for this
-- container and we retry the open. On failure, a 30s server-side cooldown
-- discourages spam.
RegisterNetEvent('corex-loot:client:promptLockpick', function(containerId)
    if not containerId then return end
    isSearching = false

    lib.notify({ description = 'This container is locked — picking...', type = 'info', duration = 2500 })

    local ok = false
    local available, success = pcall(function()
        return exports['corex-skills']:OpenLockpick({ pins = 3, cursorMs = 1400 })
    end)
    if available then ok = success == true end

    TriggerServerEvent('corex-loot:server:lockpickResult', containerId, ok)
    if ok then
        -- Small delay before retry so the success animation completes.
        SetTimeout(700, function()
            TriggerServerEvent('corex-loot:server:requestContainer', containerId)
        end)
    else
        lib.notify({ description = 'The lock didn\'t budge.', type = 'error', duration = 2500 })
    end
end)

RegisterNetEvent('corex-loot:client:takeResult', function(success, itemIndex, errorMsg)
    if success then
        TriggerEvent('corex-inventory:client:lootItemTaken', itemIndex)
    else
        lib.notify({ description = errorMsg or 'Could not take item', type = 'error' })
    end
end)

RegisterNetEvent('corex-loot:client:containerClosed', function(containerId)
    if not containerId then
        containerId = openContainerId
    end

    if containerId then
        TriggerServerEvent('corex-loot:server:closeContainer', containerId)
    end

    openContainerId = nil
    isSearching = false
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    CleanupAll()
end)

CreateThread(function()
    Wait(500)
    if not InitCorex() then return end

    Corex.Functions.WaitForPlayerData(15000)
    isReady = true

    SpawnContainers()
    Debug('Info', 'Client initialized')
end)
