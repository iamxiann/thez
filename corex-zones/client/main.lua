local Corex = nil
local isReady = false

print('[COREX-ZONES] ^3Initializing...^0')

local function InitCore()
    local success, core = pcall(function()
        return exports['corex-core']:GetCoreObject()
    end)
    if not success or not core or not core.Functions then return false end
    Corex = core
    return true
end

if not InitCore() then
    AddEventHandler('corex:client:coreReady', function(coreObj)
        if coreObj and coreObj.Functions and not Corex then
            Corex = coreObj
            isReady = true
            print('[COREX-ZONES] ^2Successfully connected to COREX core^0')
        end
    end)
    CreateThread(function()
        Wait(15000)
        if not Corex then
            print('[COREX-ZONES] ^1ERROR: Core init timed out^0')
        end
    end)
else
    isReady = true
    print('[COREX-ZONES] ^2Successfully connected to COREX core^0')
end

local currentZone = nil
local isInSafeZone = false
local spawnedBlips = {}

-- Point-in-polygon membership check via the shared PolyZone objects
-- (built once in shared/zones.lua from Config.SafeZones).
local function GetZoneAtCoords(coords)
    if not isReady or not coords then return nil end

    local zoneObj, zoneConfig = Corex_GetZoneObjectAt(coords)
    return zoneConfig
end

local function ApplyProtection(ped)
    if not isReady or not Config.Protection then return end

    if Config.Protection.godMode then
        SetEntityInvincible(ped, true)
    end

    -- Weapon-disable controls must be re-asserted per-frame since
    -- DisableControlAction only affects the current frame.
    if Config.Protection.disableWeapons then
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 257, true)
    end
end

local lastForceUnarmed = 0
local function ForceUnarmedInterval(ped)
    -- SetCurrentPedWeapon is expensive; only reassert periodically
    -- rather than every frame.
    local now = GetGameTimer()
    if now - lastForceUnarmed < 500 then return end
    lastForceUnarmed = now
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
end

local function RemoveProtection()
    if not isReady then return end

    local ped = Corex.Functions.GetPed()
    SetEntityInvincible(ped, false)
end

-- NOTE: AddBlipForRadius only draws a circle, so it can't represent an
-- arbitrary polygon shape on the minimap. Each zone now gets a single
-- center blip (placed at the polygon's bounding-box center) instead of a
-- radius circle. If you want the actual polygon outline visible, enable
-- PolyZone's own debugPoly option when building the zone (draws the outline
-- in the 3D world, not on the minimap) -- see shared/zones.lua.
local function CreateZoneBlips()
    for i, zone in ipairs(Config.SafeZones) do
        if zone.blip and zone.blip.enabled then
            local zoneObj = CorexZoneObjects[i]
            if zoneObj then
                local center = zoneObj:getBoundingBoxCenter()

                local centerBlip = AddBlipForCoord(center.x, center.y, zoneObj.minZ or 0.0)
                SetBlipSprite(centerBlip, zone.blip.sprite)
                SetBlipDisplay(centerBlip, 4)
                SetBlipScale(centerBlip, zone.blip.scale)
                SetBlipColour(centerBlip, zone.blip.color)
                SetBlipAsShortRange(centerBlip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(zone.blip.label)
                EndTextCommandSetBlipName(centerBlip)

                table.insert(spawnedBlips, centerBlip)
            end
        end
    end
end

CreateThread(function()
    while not isReady do
        Wait(500)
    end

    CreateZoneBlips()
end)

CreateThread(function()
    while not isReady do
        Wait(1000)
    end

    while true do
        Wait(Config.CheckInterval or 500)

        local coords = Corex.Functions.GetCoords()
        local zone = GetZoneAtCoords(coords)

        if zone then
            if not isInSafeZone then
                isInSafeZone = true
                currentZone = zone
                TriggerEvent('corex-zones:client:enteredSafeZone', zone)
                TriggerServerEvent('corex-zones:server:playerEnteredZone', zone.name)
            end
        else
            if isInSafeZone then
                isInSafeZone = false
                local oldZone = currentZone
                currentZone = nil
                TriggerEvent('corex-zones:client:leftSafeZone', oldZone)
                TriggerServerEvent('corex-zones:server:playerLeftZone', oldZone.name)
            end
        end
    end
end)

CreateThread(function()
    while not isReady do
        Wait(1000)
    end

    while true do
        if isInSafeZone then
            Wait(0)
            local ped = PlayerPedId()
            ApplyProtection(ped)
            if Config.Protection and Config.Protection.disableWeapons then
                ForceUnarmedInterval(ped)
            end
        else
            Wait(500)
        end
    end
end)

AddEventHandler('corex-zones:client:enteredSafeZone', function(zone)
    if Config.Debug then
        print('^2[COREX-ZONES] Entered safe zone: ' .. zone.name .. '^0')
    end
    Corex.Functions.Notify('Entered Safe Zone: ' .. zone.name, 'success', 3000)
end)

AddEventHandler('corex-zones:client:leftSafeZone', function(zone)
    if Config.Debug then
        print('^3[COREX-ZONES] Left safe zone: ' .. zone.name .. '^0')
    end
    Corex.Functions.Notify('Left Safe Zone', 'warning', 3000)
    RemoveProtection()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for _, blip in ipairs(spawnedBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end)

function IsPlayerInSafeZone()
    return isInSafeZone
end

function GetPlayerZone()
    return currentZone
end

function GetSafeZones()
    return Config.SafeZones
end

-- Simple boolean membership check for arbitrary coords (e.g. a zombie's position).
-- Returns isInside (bool), zoneConfig (table or nil)
function IsCoordsInSafeZone(coords)
    return Corex_IsCoordsInSafeZone(coords)
end

local function IsFiniteNumber(value)
    return type(value) == 'number' and value == value and math.abs(value) < math.huge
end

-- Distance in meters to the nearest polygon volume: zero inside, including
-- its boundary. Missing height bounds leave that side vertically unbounded.
-- Invalid coordinates or no usable zones return math.huge.
function GetSafeZoneDistance(coords)
    local coordsType = type(coords)
    if coordsType ~= 'table' and coordsType ~= 'vector3' and coordsType ~= 'vector4' then
        return math.huge
    end

    local x, y, z = coords.x, coords.y, coords.z
    if not IsFiniteNumber(x) or not IsFiniteNumber(y) or not IsFiniteNumber(z) then
        return math.huge
    end

    local nearestSq = math.huge
    for _, zone in pairs(CorexZoneObjects or {}) do
        local points = zone.points
        local minZ, maxZ = zone.minZ, zone.maxZ
        if not zone.destroyed and points and #points >= 3
            and IsFiniteNumber(zone.area) and zone.area > 0
            and (minZ == nil or IsFiniteNumber(minZ))
            and (maxZ == nil or IsFiniteNumber(maxZ))
            and (minZ == nil or maxZ == nil or minZ <= maxZ) then
            local projectedZ = z
            if minZ then projectedZ = math.max(projectedZ, minZ) end
            if maxZ then projectedZ = math.min(projectedZ, maxZ) end

            local horizontalSq = math.huge
            -- PolyZone's grid indexes can exceed the grid on its upper bound.
            -- Boundary points use segment distance instead (which is zero).
            if x > zone.min.x and x < zone.max.x and y > zone.min.y and y < zone.max.y
                and zone:isPointInside(vector3(x, y, projectedZ)) then
                horizontalSq = 0.0
            else
                local previous = points[#points]
                for _, point in ipairs(points) do
                    local edgeX, edgeY = point.x - previous.x, point.y - previous.y
                    local lengthSq = edgeX * edgeX + edgeY * edgeY
                    local t = 0.0
                    if lengthSq > 0 then
                        t = math.max(0.0, math.min(1.0,
                            ((x - previous.x) * edgeX + (y - previous.y) * edgeY) / lengthSq))
                    end
                    local dx = x - (previous.x + t * edgeX)
                    local dy = y - (previous.y + t * edgeY)
                    horizontalSq = math.min(horizontalSq, dx * dx + dy * dy)
                    previous = point
                end
            end

            local dz = z - projectedZ
            nearestSq = math.min(nearestSq, horizontalSq + dz * dz)
            if nearestSq == 0 then return 0.0 end
        end
    end

    return math.sqrt(nearestSq)
end
